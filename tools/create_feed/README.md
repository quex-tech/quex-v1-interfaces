# Quex feed creation tool

## Description
Quex flow creation tool is made to make your start with Quex HTTP Request Oracles easier


## Setup

1. Initialize virtual environment
```bash
python -m venv venv
```
2. Activate virtual environment
```bash
source ./venv/bin/activate
```
3. Install requirements
```bash
pip install -r requirements.txt
```
4. Set up how the script will access the private key. It can be done in three ways:
+ Pass it as a `SECRET_KEY` environment variable
+ Store it in `.env` file:
```
$ cat .env
SECRET_KEY=5a44...
```
+ Set it in the config file as `config.chain.secret_key`
5. Configure your HTTPS request in `request.json`. Full set of options to describe your request can be found in [IV1FeedRegistry models](../../interfaces/oracles/IRequestOraclePool.sol). In case your request does not need encrypted patch, delete `request.patch` field completely
6. Edit `config.json` according to your needs:
+ `config.chain.rpc_url` must contain RPC URL of chain you are working on
+ `config.oracle_pool` and `config.quex_core` must contain corresponding addresses of Quex Contracts on this chain, and local paths to ABI files
+ `config.request_file` is the path to previously configured request
+ `gas_limit` is the gas limit of your callback
+ `td_pubkey` is the public key of the Trust Domain you are encrypting patch to. In case you do not have encrypted data,
  you may delete this field
+ `consumer` is the address of your data consuming contract
+ `callback` is the 4-byte selector of the callback handling the data on your contract. The callback must accept
  arguments `(uint256 receivedRequestId, DataItem memory response, IdType idType)`. See Quex documentation for the
  details
6. Run script
```bash
python create_flow.py config.json
```

The script will perform the following tasks:
1. If necessary, encrypt the `request.patch` data for the TD key you provided
2. Register action with Quex Request Oracle Pool
3. Create the flow with this action from the Oracle Pool to consumer contract

It will output the id of the action registered with the Oracle Pool and id of the corresponding flow created on Quex
Core. Flow id can be used to make requests and deliver data.

## Models
A feed in Quex is composed of multiple well-defined parts, each serving a specific role in the data-fetching and processing pipeline.
Below are the detailed models of each feed part:

### Feed
+ `request` (HTTPRequest): Request configuration.
+ `patch` (HTTPPrivatePatch): A secure, encrypted section of the feed that contains sensitive parts of the request configuration.
+ `schema` (string): Describes the format of the data delivered to the smart contract.
+ `filter` (string): Specifies how to extract and transform relevant data from the raw JSON response.

### HTTPRequest
+ `method` (enum): HTTP method to use (0 - `GET`, 1 -`POST`, 2 - `PUT`, 3 - `PATCH`, 4 - `DELETE`, 5 - `OPTIONS`, 6 - `TRACE`).
+ `url` (string): The base URL of the data source.
+ `path` (string): URL path of data source.
+ `headers` (list\[RequestHeader\]): Key-value pairs for HTTP headers.
+ `params` (list\[QueryParameter\]): Query parameters to include in the URL.
+ `body` (object): Request body for `POST`, `PUT` and `PATCH` methods

### RequestHeader
+ `key` (string): Key of the header.
+ `value` (string): Value of the header.

### QueryParameter
+ `key` (string): Key of the parameter.
+ `value` (string): Value of the parameter.

### HTTPPrivatePatch
Note, that the encryption is performed by the tool. This description shows how the structure will appear on-chain. For
tool usage, please adhere to `request.json` format.
+ `pathSuffix` (bytes): Encrypted path suffix.
+ `headers` (list\[RequestHeaderPatch\]): Key-value pairs for HTTP headers.
+ `params` (list\[QueryParameterPatch\]): Query parameters to include in the URL.
+ `body` (bytes): Encrypted payload.
+ `tdAddress` (address): address of the TD that could decrypt patch.

### RequestHeaderPatch
+ `key` (string): Key of the header.
+ `value` (bytes): Encrypted value of the header.
 
### QueryParameterPatch
+ `key` (string): Key of the parameter.
+ `value` (bytes): Encrypted value of the parameter.

