// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IQuexMonetary {
    function getTreasury() external view returns (address);
    function getQuexFee(uint256 flowId) external view returns (uint256);
}
