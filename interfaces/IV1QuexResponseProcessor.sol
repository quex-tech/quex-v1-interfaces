// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct DataItem {
    uint256 timestamp;
    bytes32 feedId;
    bytes value;
}

interface IV1QuexResponseProcessor {
    function processResponse(bytes32 requestId, DataItem memory response) external;
}
