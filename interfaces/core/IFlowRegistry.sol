// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct Flow {
    uint256 gasLimit;
    uint256 actionId;
    address pool;
    address consumer;
    bytes4 callback;
}

interface IFlowRegistry {
    function createFlow(Flow memory flow) external returns (uint256 flowId);
    function getFlow(uint256 flowId) external view returns (Flow memory);
}
