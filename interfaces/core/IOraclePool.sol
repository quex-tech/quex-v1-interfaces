// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IOraclePool {
    function isInPool(address tdAddress) external view returns (bool);
    function getAction(uint256 actionId) external view returns (bytes memory);
    function getActionFee(uint256 actionId) external view returns (uint256);
    function getTreasury() external view returns (address);
}
