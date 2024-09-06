// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IV1QuexLogReader {
    function getLastData(bytes32 feedID) external view returns (uint256 id, int256 value, uint256 timestamp);
    function getDataByID(bytes32 feedID, uint256 dataID) external view returns (uint256 return_id, int256 value, uint256 timestamp);
    function getFeeds() external view returns (bytes32[] memory);
}
