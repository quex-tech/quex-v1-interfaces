// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IP256Verifier {
    function ecdsa_verify(bytes32 message_hash, uint256 r, uint256 s, uint256[2] memory pubKey)
        external
        view
        returns (bool);
}
