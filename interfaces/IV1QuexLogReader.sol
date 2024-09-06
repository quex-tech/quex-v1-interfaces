// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IV1QuexLogReader {
    /**
     * @param feedID ID of the required datafeed
     * @return id Sequential number of the last record in the log
     * @return value numerical value of the record
     * @return timestamp UNIX timestamp of the record in seconds
     */
    function getLastData(bytes32 feedID) external view returns (uint256 id, int256 value, uint256 timestamp);
    /**
     * @param feedID ID of the required datafeed
     * @param dataID sequential number of the record in the log fof fixed feedID
     * @return return_id Sequential number of the record in the log. Must coincide with dataID
     * @return value numerical value of the record
     * @return timestamp UNIX timestamp of the record in seconds
     */
    function getDataByID(bytes32 feedID, uint256 dataID) external view returns (uint256 return_id, int256 value, uint256 timestamp);
    /**
     * @dev Convenience function, not connected to main logic. Returns the owner-defined list of supported feedIDs. Does
     * not enforce absence of other feedIDs or relevance of the list
     * @return feedIDs array of owner-defined feedIDs
     */
    function getFeeds() external view returns (bytes32[] memory feedIDs);
}
