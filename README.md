# quex-v1-interfaces

## Description

This repository contains the set of interfaces for V1 of Quex smart-contracts

## Rationale

Quex provides the set of oracles for EVM-compatile blockchains utilizing Trusted Execution Environment (TEE)
attestation. The current set of contracts performs on-chain verification of Intel Trusted Domain Exstensions (TDX)
quotes together with the verification of the certificate chain up to the Intel SGX root CA. The software inside TD
issues the attestation quote containing the public key generated inside the domain.

This quote is signed by standard Intel DCAP enclave and registered on-chain together with all the necessary
certificates. From that point, the data signed with the corresponding private key can be set as trusted for the
particular `V1RequestRegistry` contract.

## Overview

### Feeds
Quex enables smart contracts to fetch off-chain data by using a mechanism called a feed. 
A feed is a predefined configuration that specifies how data is fetched, processed, and 
delivered to your smart contract. It serves as a bridge between external data sources (like APIs) 
and the on-chain environment.

A feed consists of the following components:
+ Request configuration: Defines the data source, including the URL, HTTP method, headers, parameters, and body
required to retrieve the data.
+ Private configuration patch: A secure, encrypted section of the feed that contains sensitive parts of the request
configuration, such as the path suffix, headers, parameters, and body. Only a specified trust domain has the authority
to decrypt and access these parts. This ensures that sensitive information like authentication tokens or API keys is
kept secure while still allowing the smart contract to make requests based on the feed.  
+ jq filter: Specifies how to extract and transform relevant data from the raw JSON response.
+ Output ABI: Describes the format of the data delivered to the smart contract, ensuring compatibility with EVM-based applications.

### Requests
Once a feed is created, it acts as a reusable template for making data requests. Here’s how the process works:
1. Initiating the Request: The smart contract calls `IV1RequestRegistry.sendRequest` specifying the feed ID,
callback address and method and gas limit for callback function. This request should be paid to cover the callback 
processing logic (which is out of Quex control) for the network fee by relayer to be reimbursed.
2. Fetching and Processing the Data: Quex TD performs the HTTPS request to the specified data source using the provided feed with certificte verification and response validation performed inside TD, signs the result with the private key exclusively owned by TD
3. Returning the Data: The processed data and TD's signature is returned on-chain where signature checked.
4. Smart Contract Callback: Once the data is retrieved and checked, Quex returns the result to the smart contract by invoking provided callback function.

## Example Usage

### Create Feed

Before using Quex, you need to set up a feed. This involves calling `IV1FeedRegistry` interface's functions to configure
request specification and postprocessing: create [request](interfaces/IV1FeedRegistry.sol#L58), 
add [private patch](interfaces/IV1FeedRegistry.sol#L60) if needed, provide [jq filter](interfaces/IV1FeedRegistry.sol#L62)
to transform API response and specify [response schema](interfaces/IV1FeedRegistry.sol#L64).
When all parts are created, create a feed by calling [addFeed function](interfaces/IV1FeedRegistry.sol#L66).

To simplify your start with Quex, you can use [a Python script](tools/create_feed) designed to streamline the feed creation process.

### Perform Request

Once the feed is created, you can make requests to fetch data and process the response in your smart contract.

In order to process response your contract should implement [IV1QuexResponseProcessor](interfaces/IV1QuexResponseProcessor.sol) interface 
to the Solidity project, provide your contract address and `processResponse` function's signature while
creating request through `IV1RequestRegistry.sendRequest`.

For example, in [Remix IDE](https://remix.ethereum.org/)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "https://github.com/quex-tech/quex-v1-interfaces/blob/master/interfaces/IV1RequestRegistry.sol";
import "https://github.com/quex-tech/quex-v1-interfaces/blob/master/interfaces/IV1QuexResponseProcessor.sol";

address constant QUEX_REQUEST_REGISTRY_ADDRESS = 0x9afa1fd478705a1C4663F1590674500293f01e24;

contract C is IV1QuexResponseProcessor {
  IV1RequestRegistry quexRequests;

  constructor () {
    quexRequests = IV1RequestRegistry(QUEX_REQUEST_REGISTRY_ADDRESS);
  }

  function request(
    bytes32 feedId,
    uint32 callbackGasLimit) public {
    (bytes32 requestId, ) = quexRequests.sendRequest{value: <value>}(feedId, address(this), this.processResponse.selector, callbackGasLimit);
    // you can store some context related to requestId here
  }

  function processResponse(bytes32 requestId, DataItem memory response) external {
    // your logic here
  }
}
```

## Deployed Contracts

Quex smart contracts are currently deployed on [Redbelly](https://www.redbelly.network/) Testnet. The environment for 
the chain can be found [here](https://vine.redbelly.network/environments).

The contracts addresses are:
+ [0x9afa1fd478705a1C4663F1590674500293f01e24](https://redbelly.testnet.routescan.io/address/0x9afa1fd478705a1C4663F1590674500293f01e24) `V1RequestRegistry`
+ [0xE35fBA13d96a9A26166cbD2aC8Df12CD842e1408](https://redbelly.testnet.routescan.io/address/0xE35fBA13d96a9A26166cbD2aC8Df12CD842e1408) `V1FeedRegistry`

## Disclaimer

Quex Project is undergoing heavy development, meaning that
+ The ABI is not stable and most likely will be adjusted in the future
+ The requests are in the testnet. Correspondingly, the responses in the requests, although fully attested with trusted
  hardware and properly verified on-chain, should be used at your own risk, until the thorough security analysis is
  finished by Quex and mainnet applications are launched
+ It worth checking the date. The description in this document is effective at the time of writing, November 2024
