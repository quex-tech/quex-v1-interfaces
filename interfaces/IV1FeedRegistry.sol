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

struct Feed {
    HTTPRequest request;
    HTTPPrivatePatch patch;
    string schema;
    string filter;
}

interface IV1FeedRegistry {
    function addRequest(HTTPRequest memory request) external returns (bytes32 requestId);

    function addPrivatePatch(uint256 tdId, HTTPPrivatePatch memory privatePatch) external returns (bytes32 patchId);

    function addJqFilter(string memory jqFilter) external returns (bytes32 filterId);

    function addResponseSchema(string memory responseSchema) external returns (bytes32 schemaId);

    function addFeed(
        bytes32 requestId,
        bytes32 patchId,
        bytes32 filterId,
        bytes32 schemaId
    ) external returns (bytes32 feedId);

    function getFeed(bytes32 feedId) external view returns (uint256 tdId, Feed memory feed);
}
