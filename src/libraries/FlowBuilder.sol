// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "src/interfaces/oracles/IRequestOraclePool.sol";
import "src/interfaces/core/IFlowRegistry.sol";

/**
 * @title FlowBuilder
 * @dev A utility library for building and registering Quex data request flows
 */
library FlowBuilder {
    /**
     * @dev Struct holding configuration for a flow to be created.
     */
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

    /**
     * @notice Initializes a FlowConfig with basic values and defaults.
     * @param quexCore Address of the Quex Flow Registry contract. See https://docs.quex.tech/general-information/addresses for network-specific addresses.
     * @param oraclePool Address of the Oracle Pool contract. See https://docs.quex.tech/general-information/addresses for network-specific addresses.
     * @param host Target HTTP host (e.g., "api.llama.fi").
     * @param path Target HTTP path (e.g., "/tvl/dydx").
     * @return config Initialized FlowConfig with default method, schema, filter, and gas limit.
     */
    function create(address quexCore, address oraclePool, string memory host, string memory path)
        internal
        pure
        returns (FlowConfig memory config)
    {
        config.flowRegistry = quexCore;
        config.oraclePool = oraclePool;
        config.request.host = host;
        config.request.path = path;

        // Default values
        config.request.method = RequestMethod.Get;
        config.responseSchema = "uint256";
        config.jqFilter = ".";
        config.gasLimit = 500000;
        return config;
    }

    /**
     * @notice Sets the jq filter to transform the HTTP response.
     * @param config Existing FlowConfig.
     * @param filter jq filter string. See https://docs.quex.tech/developers/https_pool/jq_subset for supported post-processing operations.
     * @return Updated FlowConfig.
     */
    function withFilter(FlowConfig memory config, string memory filter) internal pure returns (FlowConfig memory) {
        config.jqFilter = filter;
        return config;
    }

    /**
     * @notice Sets the expected response schema for the flow.
     * @param config Existing FlowConfig.
     * @param schema Schema string.
     * @return Updated FlowConfig.
     */
    function withSchema(FlowConfig memory config, string memory schema) internal pure returns (FlowConfig memory) {
        config.responseSchema = schema;
        return config;
    }

    /**
     * @notice Sets the consumer address and callback method for the flow.
     * @param config Existing FlowConfig.
     * @param consumer Target contract that will receive the response.
     * @param callback Selector of the callback function.
     * @return Updated FlowConfig.
     */
    function withCallback(FlowConfig memory config, address consumer, bytes4 callback)
        internal
        pure
        returns (FlowConfig memory)
    {
        config.consumer = consumer;
        config.callback = callback;
        return config;
    }

    /**
     * @notice Registers the flow on-chain using the configured parameters.
     * @param config FlowConfig with all parameters set.
     * @return flowId ID of the created flow.
     */
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
