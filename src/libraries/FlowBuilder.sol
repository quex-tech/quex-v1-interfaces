// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IRequestOraclePool} from "src/interfaces/oracles/IRequestOraclePool.sol";
import {IFlowRegistry} from "src/interfaces/core/IFlowRegistry.sol";

/**
 * @title FlowBuilder
 * @dev A utility library for building and registering Quex data request flows
 */
library FlowBuilder {
    /**
     * @dev Struct holding configuration for a flow to be created.
     */
    struct FlowConfig {
        address oraclePool;
        address flowRegistry;
        HTTPRequest request;
        HTTPPrivatePatch patch;
        string jqFilter;
        string responseSchema;
        address consumer;
        bytes4 callback;
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
     * @notice Sets the gas limit for the flow.
     * @param config Existing FlowConfig.
     * @param gasLimit Gas limit to set.
     * @return Updated FlowConfig.
     */
    function withGasLimit(FlowConfig memory config, uint256 gasLimit) internal pure returns (FlowConfig memory) {
        config.gasLimit = gasLimit;
        return config;
    }

    /**
     * @notice Sets the method for the HTTP request.
     * @param config Existing FlowConfig.
     * @param method Method to set.
     * @return Updated FlowConfig.
     */
    function withMethod(FlowConfig memory config, RequestMethod method) internal pure returns (FlowConfig memory) {
        config.request.method = method;
        return config;
    }

    /**
     * @notice Sets the headers for the HTTP request.
     * @param config Existing FlowConfig.
     * @param headers Headers to set.
     * @return Updated FlowConfig.
     */
    function withHeaders(FlowConfig memory config, RequestHeader[] memory headers)
        internal
        pure
        returns (FlowConfig memory)
    {
        config.request.headers = headers;
        return config;
    }

    /**
     * @notice Sets the query parameters for the HTTP request.
     * @param config Existing FlowConfig.
     * @param parameters Query parameters to set.
     * @return Updated FlowConfig.
     */
    function withQueryParameters(FlowConfig memory config, QueryParameter[] memory parameters)
        internal
        pure
        returns (FlowConfig memory)
    {
        config.request.parameters = parameters;
        return config;
    }

    /**
     * @notice Sets the body for the HTTP request.
     * @param config Existing FlowConfig.
     * @param body Body to set.
     * @return Updated FlowConfig.
     */
    function withBody(FlowConfig memory config, bytes memory body) internal pure returns (FlowConfig memory) {
        config.request.body = body;
        return config;
    }

    /**
     * @notice Sets the td address for the private patch. Required if the private patch is used.
     * @param config Existing FlowConfig.
     * @param tdAddress Td address to set.
     * @return Updated FlowConfig.
     */
    function withTdAddress(FlowConfig memory config, address tdAddress) internal pure returns (FlowConfig memory) {
        config.patch.tdAddress = tdAddress;
        return config;
    }

    /**
     * @notice Sets the private path suffix for the HTTP request.
     * @param config Existing FlowConfig.
     * @param pathSuffix Private path suffix to set.
     * @return Updated FlowConfig.
     */
    function withPrivatePathSuffix(FlowConfig memory config, bytes memory pathSuffix)
        internal
        pure
        returns (FlowConfig memory)
    {
        config.patch.pathSuffix = pathSuffix;
        return config;
    }

    /**
     * @notice Sets the private headers for the HTTP request.
     * @param config Existing FlowConfig.
     * @param headers Private headers to set.
     * @return Updated FlowConfig.
     */
    function withPrivateHeaders(FlowConfig memory config, RequestHeaderPatch[] memory headers)
        internal
        pure
        returns (FlowConfig memory)
    {
        config.patch.headers = headers;
        return config;
    }

    /**
     * @notice Sets the private query parameters for the HTTP request.
     * @param config Existing FlowConfig.
     * @param parameters Private query parameters to set.
     * @return Updated FlowConfig.
     */
    function withPrivateQueryParameters(FlowConfig memory config, QueryParameterPatch[] memory parameters)
        internal
        pure
        returns (FlowConfig memory)
    {
        config.patch.parameters = parameters;
        return config;
    }

    /**
     * @notice Sets the private body for the HTTP request.
     * @param config Existing FlowConfig.
     * @param body Private body to set.
     * @return Updated FlowConfig.
     */
    function withPrivateBody(FlowConfig memory config, bytes memory body) internal pure returns (FlowConfig memory) {
        config.patch.body = body;
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
