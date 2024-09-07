# quex-v1-interfaces

## Description

This repository contains the set of interfaces for V1 of Quex smart-contracts

## Rationale

Quex provides the set of oracles for EVM-compatile blockchains utilizing Trusted Execution Environment (TEE)
attestation. The current set of contracts performs on-chain verification of Intel Trusted Domain Exstensions (TDX)
quotes together with the verification of the certificate chain up to the Intel SGX root CA. The software inside TD
issues the attestation quote containing the public key (more precisely, ETH address) generated inside the domain.

This quote is signed by standard Intel DCAP enclave and registered on-chain together with all the necessary
certificates. From that point, the data signed with the corresponding private key can be set as trusted for the
particular `V1QuexLog` contract.

## Example Usage

In order to use Quex datafeeds, one needs to import `interfaces/IV1QuexLogReader.sol` interface to the Solidity project,
supply the interface with the address of `V1QuexLog` contract (`0x3959148FF37f2d5c5F7a4A9c2E12dA4057B9C38A` in Redbelly
testnet), and call the needed `view` method (see info on `feedID` and contract address in [Current Datafeeds](#cd-anchor)).

For example, in [Remix IDE](https://remix.ethereum.org/)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "https://github.com/quex-tech/quex-v1-interfaces/blob/master/interfaces/IV1QuexLogReader.sol";

bytes32 constant BTC_FEED_ID = 0x4254430000000000000000000000000000000000000000000000000000000000;
address constant QUEX_LOG_ADDRESS = 0x3959148FF37f2d5c5F7a4A9c2E12dA4057B9C38A;

contract C {
    IV1QuexLogReader qreader;

    constructor () {
        qreader = IV1QuexLogReader(QUEX_LOG_ADDRESS);
    }

    function getLastBTCPriceInCents() public view returns (int256) {
        (uint256 id, int256 value, uint256 timestamp) = qreader.getLastData(BTC_FEED_ID);
        return (value / 10000) + (value % 10000 >= 5000 ? int256(1) : int256(0));
    }
}
```

## Deployed Contracts

Quex smart contracts are currently deployed on [Redbelly](https://www.redbelly.network/) Testnet. The environment for 
the chain can be found [here](https://vine.redbelly.network/environments).

The contracts addresses are:
+ [0xcf360ff9996353ccf72c8fe5972e6b38ab7fb968](https://explorer.testnet.redbelly.network/address/0xcf360ff9996353ccf72c8fe5972e6b38ab7fb968) `V1CertificateVerifier`
+ [0x306f4d7105298a535106b7df0efd39e46be2e6ff](https://explorer.testnet.redbelly.network/address/0x306f4d7105298a535106b7df0efd39e46be2e6ff) `V1QuoteVerifier`
+ [0xf731e3f8cc0445f65a19c632646e388cf8cc8dbd](https://explorer.testnet.redbelly.network/address/0xf731e3f8cc0445f65a19c632646e388cf8cc8dbd) `V1SignersRegistry`
+ [0x55e440500a6108c1d05c52a7f550c4138195be9c](https://explorer.testnet.redbelly.network/address/0x55e440500a6108c1d05c52a7f550c4138195be9c) `V1LogPolicies`
+ [0x3959148FF37f2d5c5F7a4A9c2E12dA4057B9C38A](https://explorer.testnet.redbelly.network/address/0x3959148ff37f2d5c5f7a4a9c2e12da4057b9c38a) `V1QuexLog`

## <a id="cd-anchor"></a>Current Datafeeds 

The logging contract stores the data from [Coinmarketcap](https://coinmarketcap.com/). These data are attested, and
authenticity is verified by software inside TD. After the TD attestation and signing, the data is relayed to the
contract [0x3959148FF37f2d5c5F7a4A9c2E12dA4057B9C38A](https://explorer.testnet.redbelly.network/address/0x3959148ff37f2d5c5f7a4a9c2e12da4057b9c38a)
with 15 minutes interval. The data can be read using
`getLastData(bytes32 feedID)` and `getDataByID(bytes32 feedID, uint256 dataID)` view methods.
`feedID` is composed as the symbol of the asset padded with zero bytes to the width of 32 bytes. `dataID` is the
sequential number of the record in the log for the given `feedID`.

The return tuple is `(uint256 id, int256 value, uint256 timestamp)`, where `id` has the same meaning as `dataID` above,
`value` is the price of the asset in micro-USD (to get the floating-point number in USD, divide by 1000000), `timestamp`
is the UNIX timestamp of the data in seconds.

Below is the list of current datafeeds together with hex-encoded `feedID`s:
|Symbol|`feedID`|
|------|--------|
|BTC|`0x4254430000000000000000000000000000000000000000000000000000000000`|
|ETH|`0x4554480000000000000000000000000000000000000000000000000000000000`|
|USDT|`0x5553445400000000000000000000000000000000000000000000000000000000`|
|SOL|`0x534f4c0000000000000000000000000000000000000000000000000000000000`|
|BNB|`0x424e420000000000000000000000000000000000000000000000000000000000`|
|USDC|`0x5553444300000000000000000000000000000000000000000000000000000000`|
|XRP|`0x5852500000000000000000000000000000000000000000000000000000000000`|
|DOGE|`0x444f474500000000000000000000000000000000000000000000000000000000`|
|TRX|`0x5452580000000000000000000000000000000000000000000000000000000000`|
|TON|`0x544f4e0000000000000000000000000000000000000000000000000000000000`|

## Disclaimer

Quex Project is undergoing heavy development, meaning that
+ The ABI is not stable and most likely will be adjusted in the future
+ The datafeeds are in the testnet. Correspondingly, the data in the datafeeds, although fully attested with trusted
  hardware and properly verified on-chain, should be used at your own risk, until the thorough security analysis is
  finished by Quex and mainnet applications are launched
+ Quex does its best to maintain the regular datafeed updates in the testnet, however migrations and refactoring in some
  cases may lead to disruptions in the data updates
+ It worth checking the date. The description in this document is effective at the time of writing, September 2024
