// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IV1LogPolicies {
    function isAllowed(uint256 td_id) external view returns (bool);
}
