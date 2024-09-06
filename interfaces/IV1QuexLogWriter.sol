// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

struct DataItem {
    int256 value;
    uint256 timestamp;
    bytes32 feedID;
}

interface IV1QuexLogWriter {
    function setLogPoliciesContract(address log_policies) external;
    function pushData(DataItem memory data_item, uint256 td_id, uint8 v, bytes32 r, bytes32 s) external;
    function addFeed(bytes32 feedID) external;
}
