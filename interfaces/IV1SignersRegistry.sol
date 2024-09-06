// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IV1SignersRegistry {
    function addSigner(uint256 td_id) external;
    function getAddr(uint256 td_id) external view returns (address);
}

