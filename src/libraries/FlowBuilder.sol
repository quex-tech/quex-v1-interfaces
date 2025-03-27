// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "src/interfaces/oracles/IRequestOraclePool.sol";
import "src/interfaces/core/IFlowRegistry.sol";

library FlowBuilder {
    struct FlowConfig {
        HTTPRequest request;
        HTTPPrivatePatch patch;
        string jqFilter;
        string responseSchema;
        address consumer;
        bytes4 callback;
        address oraclePool;
        address flowRegistry;
        uint256 gasLimit;
    }

    function create(address quexCore, address oraclePool, string memory host, string memory path) internal pure returns (FlowConfig memory config){
        config.flowRegistry = quexCore;
        config.oraclePool = oraclePool;
        config.request.host = host;
        config.request.path = path;

        // default values that might be reapplied later
        config.request.method = RequestMethod.Get;
        config.responseSchema = "uint256";
        config.jqFilter = ".";
        config.gasLimit = 500000;
        return config;
    }

    function withFilter(FlowConfig memory config, string memory filter) internal pure returns (FlowConfig memory) {
        config.jqFilter = filter;
        return config;
    }

    function withSchema(FlowConfig memory config, string memory schema) internal pure returns (FlowConfig memory) {
        config.responseSchema = schema;
        return config;
    }

    function withCallback(FlowConfig memory config, address consumer, bytes4 callback) internal pure returns (FlowConfig memory){
        config.consumer = consumer;
        config.callback = callback;
        return config;
    }

    function build(FlowConfig memory config) internal returns (uint256 flowId) {
        IRequestOraclePool pool = IRequestOraclePool(config.oraclePool);
        IFlowRegistry registry = IFlowRegistry(config.flowRegistry);

        bytes32 requestId = pool.addRequest(config.request);
        bytes32 patchId = pool.addPrivatePatch(config.patch);
        bytes32 schemaId = pool.addResponseSchema(config.responseSchema);
        bytes32 filterId = pool.addJqFilter(config.jqFilter);

        uint256 actionId = pool.addActionByParts(requestId, patchId, schemaId, filterId);

        Flow memory flow = Flow({
            gasLimit: config.gasLimit,
            actionId: actionId,
            pool: config.oraclePool,
            consumer: config.consumer,
            callback: config.callback
        });

        return registry.createFlow(flow);
    }
}
