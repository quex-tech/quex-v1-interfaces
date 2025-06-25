// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IDepositManager {
    function createSubscription() external returns (uint256);
    function setOwner(uint256 subscriptionId, address owner) external;
    function deposit(uint256 subscriptionId) external payable;
    function withdraw(uint256 subscriptionId, address receiver) external;
    function addConsumer(uint256 subscriptionId, address consumer) external;
    function removeConsumer(uint256 subscriptionId, address consumer) external;

    function balance(uint256 subscriptionId) external view returns (uint256);
    function withdrawableBalance(uint256 subscriptionId) external view returns (uint256);
    function hasAccessToSubscription(uint256 subscriptionId, address consumer) external view returns (bool);
}