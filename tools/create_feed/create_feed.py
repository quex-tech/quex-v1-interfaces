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
from Crypto.Hash import SHA256
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
    w3 = Web3(Web3.HTTPProvider(config["rpc_url"]))
    w3.middleware_onion.inject(ExtraDataToPOAMiddleware, layer=0)
    account: LocalAccount = Account.from_key(config["secret_key"])
    w3.middleware_onion.add(SignAndSendRawMiddlewareBuilder.build(account))

    w3.eth.default_account = account.address

    return w3


def init_contract(address, abi, w3):
    return w3.eth.contract(address=address, abi=abi)


def create_request(w3, contract, request) -> bytes:
    request["body"] = b'' if request["body"] is None else json.dumps(request["body"]).encode("UTF-8")
    tx_hash = contract.functions.addRequest(request).transact()
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt["logs"][0]["data"]


def create_patch(w3, contract, td_address, patch) -> bytes:
    if patch is None:
        return bytes.fromhex("0000000000000000000000000000000000000000000000000000000000000000")
    tx_hash = contract.functions.addPrivatePatch(td_address, patch).transact()
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt["logs"][0]["data"]


def create_jq_filter(w3, contract, jq_filter) -> bytes:
    tx_hash = contract.functions.addJqFilter(jq_filter).transact()
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt["logs"][0]["data"]


def create_response_schema(w3, contract, response_schema) -> bytes:
    tx_hash = contract.functions.addResponseSchema(response_schema).transact()
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt["logs"][0]["data"]


def create_flow(w3, contract, request_id, patch_id, schema_id, filter_id, consumer, callback, gas_limit):
    tx_hash = contract.functions.addFlow(request_id, patch_id, schema_id, filter_id, consumer, callback, gas_limit).transact()
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt["logs"][-1]["data"]


if __name__ == "__main__":
    load_dotenv(find_dotenv())
    with open("config.json", "r") as f:
        config = json.loads(f.read())
    config["secret_key"] = os.environ.get("SECRET_KEY")

    pk_bytes = bytes.fromhex(config['td_pubkey'][2:])
    pk = Point.from_bytes(SECP256k1.curve, pk_bytes)

    w3 = init_web3(config)

    with open("RequestOraclePoolABI.json", 'r') as f:
        abi = json.load(f)
        contract = init_contract(config["oracle_pool"], abi, w3)

    with open(config["request_file"], "r") as f:
        request = json.load(f)

    request["request"]["method"] = http_methods[request["request"]["method"].upper()]

    encr = lambda x: encrypt(x.encode(), pk)
    request_id = create_request(w3, contract, request["request"])
    print("request_id:    0x" + request_id.hex())

    if "patch" in request:
        p = request["patch"]
        request = {
                "patch" : \
                    { x : encr(p[x]) for x in ["body", "pathSuffix"] } | \
                    { x : encrypt_pairs(p[x], encr) for x in ["headers", "parameters"] }
        } | {x : request[x] for x in ["request", "filter", "schema"]}

        patch_id = create_patch(w3, contract, config["td_id"], request["patch"])
    else:
        patch_id = b'\x00'*32;
    print("patch_id:      0x" + patch_id.hex())

    schema_id = create_response_schema(w3, contract, request["schema"])
    print("schema_id:     0x" + schema_id.hex())

    filter_id = create_jq_filter(w3, contract, request["filter"])
    print("filter_id:     0x" + filter_id.hex())

    flow_id = create_flow(w3, \
            contract, \
            request_id, \
            patch_id, \
            schema_id, \
            filter_id, \
            config["consumer"], \
            config["callback"], \
            config["gas_limit"])

    print("flow_id:       0x" + flow_id.hex())
