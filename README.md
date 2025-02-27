# quex-v1-interfaces

## Description

This repository contains the set of interfaces for V1 of Quex smart-contracts together with a helper tool for
interacting with Quex Request Oracle Pool

## Rationale

Quex provides the set of oracles for EVM-compatile blockchains utilizing Trusted Execution Environment (TEE)
attestation. The current set of contracts performs on-chain verification of Intel Trusted Domain Exstensions (TDX)
quotes together with the verification of the certificate chain up to the Intel SGX root CA. The software inside TD
issues the attestation quote containing the public key generated inside the domain.

This quote is signed by standard Intel DCAP enclave and registered on-chain together with all the necessary
certificates. From that point, the data signed with the corresponding private key can be set as trusted. To distinguish
different types of workloads, we use the concept of Oracle Pools. Quex Request Oracle Pool is responsible for performing
requests to external TLS-protected HTTP endpoints and post-processing the responses. The particular Trust Domain workload is
defined by so-called action. Data delivery process is arranged into flows. For more details, please refer to our
[dociumentation](https://docs.quex.tech/)

## Flow Creation Tool

In order to get understanding of the flow creation tool usage, please see the corresponding [page](tools/create_flow)
