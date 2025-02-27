#!/usr/bin/env python
import json
import os
import sys
from dotenv import load_dotenv, find_dotenv
from hexbytes import HexBytes

from eth_account import Account
from eth_account.signers.local import LocalAccount
from web3 import Web3
from web3.middleware import ExtraDataToPOAMiddleware, SignAndSendRawMiddlewareBuilder

from Crypto.Cipher import AES
from Crypto.Hash import SHA256, keccak
from Crypto.Protocol.KDF import HKDF
from ecdsa import SECP256k1, SigningKey, VerifyingKey
from ecdsa.ellipticcurve import Point
from Crypto.Random import get_random_bytes

http_methods = {
   "GET"    : 0,
   "POST"   : 1,
   "PUT"    : 2,
   "PATCH"  : 3,
   "DELETE" : 4,
   "OPTIONS": 5,
   "TRACE"  : 6
}

empty_patch = {
        "pathSuffix" : b'',
        "headers": [],
        "parameters": [],
        "body": b'',
        "tdAddress": b'\x00'*20
        }

def pk_to_address(pk_bytes):
    h = keccak.new(digest_bits=256, data=pk_bytes)
    return h.digest()[-20:]

def encrypt(plaintext, pk):
    nonce = get_random_bytes(16)
    r = int.from_bytes(get_random_bytes(32),'little')
    ephemeral_priv = SigningKey.from_secret_exponent(r, curve=SECP256k1)
    shared_point = pk * r
    ephemeral = ephemeral_priv.verifying_key.pubkey.point
    symm_key = HKDF(b'\x04' + ephemeral.to_bytes() + b'\x04' + shared_point.to_bytes(), 32, salt=None, hashmod=SHA256)
    cipher = AES.new(symm_key, AES.MODE_GCM, nonce=nonce)
    ciphertext, tag = cipher.encrypt_and_digest(plaintext)
    return ephemeral.to_bytes() + nonce + tag + ciphertext

def encrypt_pairs(pairs, encr_fun):
    return [{"key": x["key"], "ciphertext": encr_fun(x["value"])}  for x in pairs]

def init_web3(config):
    w3 = Web3(Web3.HTTPProvider(config["chain"]["rpc_url"]))
    w3.middleware_onion.inject(ExtraDataToPOAMiddleware, layer=0)
    account: LocalAccount = Account.from_key(config["chain"]["secret_key"])
    w3.middleware_onion.add(SignAndSendRawMiddlewareBuilder.build(account))

    w3.eth.default_account = account.address

    return w3


def init_contract(contract_config, w3):
    with open(contract_config["abi"], 'r') as f:
        abi = json.load(f)
    return w3.eth.contract(address=contract_config["address"], abi=abi)

def create_action(w3, contract, action):
    tx_hash = contract.functions.addAction(action).transact()
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt["logs"][0]["data"]


def create_flow(w3, contract, flow):
    tx_hash = contract.functions.createFlow(flow).transact()
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt["logs"][0]["data"]


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: create_flow <path_to_config_json>")
        sys.exit(1)

    load_dotenv(find_dotenv())
    with open(sys.argv[1], "r") as f:
        config = json.loads(f.read())

    with open(config["request_file"], 'r') as f:
        request = json.load(f)

    if "secret_key" not in config["chain"]:
        config["chain"]["secret_key"] = os.environ.get("SECRET_KEY")

    pk_bytes = bytes.fromhex(config['td_pubkey'][2:])
    pk = Point.from_bytes(SECP256k1.curve, pk_bytes)

    w3 = init_web3(config)

    core_contract = init_contract(config["quex_core"], w3)
    pool_contract = init_contract(config["oracle_pool"], w3)

    request["request"]["method"] = http_methods[request["request"]["method"].upper()]

    encr = lambda x: encrypt(x.encode(), pk)

    if "patch" in request:
        p = request["patch"]
        patch = { x : encr(p[x]) for x in ["body", "pathSuffix"] } | \
                { x : encrypt_pairs(p[x], encr) for x in ["headers", "parameters"] } | \
                {"tdAddress": pk_to_address(pk_bytes) }
    else:
        patch = empty_patch
    request = {
            "patch" : patch\
    } | {x : request[x] for x in ["request", "jqFilter", "responseSchema"]}
    request["request"]["body"] = request["request"]["body"].encode()

    action_id = create_action(w3, pool_contract, request)
    print("action_id:    0x" + action_id.hex())

    flow = {
            "gasLimit": config["gas_limit"],
            "actionId": int.from_bytes(action_id, 'big'),
            "pool" : pool_contract.address,
            "consumer" : config["consumer"],
            "callback" : config["callback"]
            }

    flow_id = create_flow(w3, core_contract, flow)

    print("flow_id:      0x" + flow_id.hex())

    native_fee, gas = core_contract.functions.getRequestFee(int.from_bytes(flow_id, 'big')).call()

    print(f"Native fee:   {native_fee}")
    print(f"Gas to cover: {gas}")
