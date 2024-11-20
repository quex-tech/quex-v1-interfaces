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

## Example Usage

### Create Feed

Before using Quex, you need to set up a feed. This involves defining how data is fetched and processed:
- Define [request](interfaces/IV1FeedRegistry.sol#L58)
- Define [private patch](interfaces/IV1FeedRegistry.sol#L60) if needed
- Define [jq filter](interfaces/IV1FeedRegistry.sol#L62) to transform API response
- Define [response schema](interfaces/IV1FeedRegistry.sol#L64)
- Combine all parts together as a [feed](interfaces/IV1FeedRegistry.sol#L66)

### Perform Request

Once the feed is created, you can make requests to fetch data and process the response in your smart contract.

In order to process response your contract should implement `interfaces/IV1QuexResponseProcessor.sol` interface 
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
    (bytes32 requestId, ) = quexRequests.sendRequest(feedId, address(this), this.processResponse.selector, callbackGasLimit);
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
