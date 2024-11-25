import json
import os

from eth_account import Account
from eth_account.signers.local import LocalAccount
from web3 import Web3
from web3.middleware import ExtraDataToPOAMiddleware, SignAndSendRawMiddlewareBuilder

http_methods = {
   "GET"    : 0,
   "POST"   : 1,
   "PUT"    : 2,
   "PATCH"  : 3,
   "DELETE" : 4,
   "OPTIONS": 5,
   "TRACE"  : 6
}

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


def create_patch(w3, contract, patch) -> bytes:
    if patch is None:
        return bytes.fromhex("0000000000000000000000000000000000000000000000000000000000000000")
    tx_hash = contract.functions.addPrivatePatch(patch["td_id"], patch).transact()
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


def create_feed(w3, contract, request_id, patch_id, schema_id, filter_id):
    tx_hash = contract.functions.addFeed(request_id, patch_id, schema_id, filter_id).transact()
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    return tx_receipt["logs"][0]["data"]


if __name__ == "__main__":
    with open("config.json", "r") as f:
        config = json.loads(f.read())
    config["secret_key"] = os.environ.get("SECRET_KEY")

    w3 = init_web3(config)

    with open("FeedRegistry.json", 'r') as f:
        abi = json.load(f)
        contract = init_contract(config["feed_registry"], abi, w3)

    with open(config["feed_file"], "r") as f:
        feed = json.load(f)

    feed["request"]["method"] = http_methods[feed["request"]["method"].upper()]

    request_id = create_request(w3, contract, feed["request"])
    print("request_id:    0x" + request_id.hex())

    patch_id = create_patch(w3, contract, feed["patch"])
    print("patch_id:      0x" + patch_id.hex())

    schema_id = create_response_schema(w3, contract, feed["schema"])
    print("schema_id:     0x" + schema_id.hex())

    filter_id = create_jq_filter(w3, contract, feed["filter"])
    print("filter_id:     0x" + filter_id.hex())

    feed_id = create_feed(w3, contract, request_id, patch_id, schema_id, filter_id)
    print("feed_id:       0x" + feed_id.hex())
