// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

enum RequestMethod {
    Get,
    Post,
    Put,
    Patch,
    Delete,
    Options,
    Trace
}

struct RequestHeader {
    string key;
    string value;
}

struct QueryParameter {
    string key;
    string value;
}

struct HTTPRequest {
    RequestMethod method;
    string host;
    string path;
    RequestHeader[] headers;
    QueryParameter[] parameters;
    bytes body;
}

struct RequestHeaderPatch {
    string key;
    bytes ciphertext;
}

struct QueryParameterPatch {
    string key;
    bytes ciphertext;
}

struct HTTPPrivatePatch {
    bytes pathSuffix;
    RequestHeaderPatch[] headers;
    QueryParameterPatch[] parameters;
    bytes body;
}

interface IRequestOraclePool {
    error RequestNotFound();
    error PrivatePatchNotFound();
    error JqFilterNotFound();
    error ResponseSchemaNotFound();

    event RequestAdded(bytes32 requestId);
    event PrivatePatchAdded(bytes32 patchId);
    event JqFilterAdded(bytes32 filterId);
    event ResultSchemaAdded(bytes32 schemaId);
    
    event RequestActionAdded(uint256 feedId);

    function addRequest(HTTPRequest memory request) external returns (bytes32 requestId);

    function addPrivatePatch(uint256 tdId, HTTPPrivatePatch memory privatePatch) external returns (bytes32 patchId);

    function addJqFilter(string memory jqFilter) external returns (bytes32 filterId);

    function addResponseSchema(string memory responseSchema) external returns (bytes32 schemaId);

    function addFlow(
        bytes32 requestId,
        bytes32 patchId,
        bytes32 schemaId,
        bytes32 filterId,
        address consumer,
        bytes4 callback,
        uint256 gasLimit
    ) external returns (uint256 flowId);

    function getAction(uint256 actionId) external view returns (bytes memory);

    function getActionTD(uint256 actionId) external view returns (uint256 tdId);

    function startRequest(uint256 flowId) external payable returns (uint256 requestRunId);
}