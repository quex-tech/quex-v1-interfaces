# Quex feed creation tool

## Description
Quex feed creation tool is made to make your start with Quex easier


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
4. Set up how the script will access the private key [here](create_feed.py#L62)
5. Configure your feed in `quex_feed.json`. Full set of options to describe your feed you can see in [IV1FeedRegistry models](../../interfaces/IV1FeedRegistry.sol)
6. Run script
```bash
python create_feed.py
```

## Models
A feed in Quex is composed of multiple well-defined parts, each serving a specific role in the data-fetching and processing pipeline.
Below are the detailed models of each feed part:

### Feed
+ `request` (HTTPRequest): Request configuration.
+ `patch` (HTTPPrivatePatch): A secure, encrypted section of the feed that contains sensitive parts of the request configuration.
+ `schema` (string): Describes the format of the data delivered to the smart contract.
+ `filter` (string): Specifies how to extract and transform relevant data from the raw JSON response.

### HTTPRequest
+ `method` (enum): HTTP method to use (0 - GET, 1 - POST, 2 - PUT, 3 - PATCH, 4 - DELETE, 5 - OPTIONS, 6 - TRACE).
+ `url` (string): The base URL of the data source.
+ `path` (string): URL path of data source.
+ `headers` (list\[RequestHeader\]): Key-value pairs for HTTP headers.
+ `params` (list\[QueryParameter\]): Query parameters to include in the URL.
+ `body` (object): Payload for POST or PUT requests, in JSON format.

### RequestHeader
+ `key` (string): Key of the header.
+ `value` (string): Value of the header.
+ 
### QueryParameter
+ `key` (string): Key of the parameter.
+ `value` (string): Value of the parameter.

### HTTPPrivatePatch
+ `td_id` (number): ID of the TD that could decrypt patch.
+ `pathSuffix` (bytes): Encrypted path suffix.
+ `headers` (list\[RequestHeaderPatch\]): Key-value pairs for HTTP headers.
+ `params` (list\[QueryParameterPatch\]): Query parameters to include in the URL.
+ `body` (bytes): Encrypted payload.

### RequestHeaderPatch
+ `key` (string): Key of the header.
+ `value` (bytes): Encrypted value of the header.
 
### QueryParameterPatch
+ `key` (string): Key of the parameter.
+ `value` (bytes): Encrypted value of the parameter.

