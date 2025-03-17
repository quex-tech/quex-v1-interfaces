// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "quex-v1-interfaces/interfaces/core/IQuexActionRegistry.sol";

/**
 * @title QuexFlowManager
 * @dev Abstract contract for managing interactions with Quex data oracles.
 * This contract provides a structured framework for handling requests and responses
 * while enforcing basic restrictions to maintain data integrity.
 *
 * Default behavior:
 * - Processes responses only for a fixed `flowId`, which must be set during initialization.
 * - Only the contract owner can initiate requests.
 *
 * To modify the default behavior, override the relevant methods in a derived contract.
 */
abstract contract QuexRequestManager is Ownable {
    /// @notice Reference to the Quex Action Registry contract
    IQuexActionRegistry public quexCore;

    /// @notice Stores the ID of the most recent request sent to Quex core
    uint256 internal _requestId;

    /// @notice Stores the flow ID
    uint256 internal _flowId;

    /**
     * @dev Initializes the contract with the Quex Action Registry address and sets the owner.
     * @param quexCoreAddress Address of the Quex Action Registry contract
     */
    constructor(address quexCoreAddress) Ownable(msg.sender) {
        quexCore = IQuexActionRegistry(quexCoreAddress);
    }

    /**
     * @notice Retrieves the flow ID
     * @return The flow ID of the contract
     */
    function getFlowId() external view returns (uint256) {
        return _flowId;
    }

    /**
     * @notice Sets the flow ID (can only be set once)
     * @param flowId The unique identifier for the flow.
     */
    function setFlowId(uint256 flowId) public virtual onlyOwner {
        require(_flowId == 0, "Flow ID is already set");
        _flowId = flowId;
    }

    /**
     * @notice Performs necessary validation checks for an incoming response.
     * @dev Ensures the response originates from the Quex core contract and has passed all validity checks.
     *      Also verifies that the response corresponds to the latest request.
     * @param receivedRequestId The ID of the request associated with this response.
     */
    modifier verifyResponse(uint256 receivedRequestId, IdType idType) {
        require(msg.sender == address(quexCore), "Only Quex Proxy can push data");
        require(receivedRequestId == _requestId, "Unknown request ID");
        require(idType == IdType.RequestId, "Return type mismatch");
        _;
    }

    /**
     * @notice Sends a request to the Quex Action Registry
     * @return The request ID of the newly created request.
     */
    function request() public payable virtual onlyOwner returns (uint256) {
        require(_flowId != 0, "Flow ID is not set");
        _requestId = quexCore.createRequest{value: msg.value}(_flowId);
        return _requestId;
    }

    /**
     * @notice Handles refunds if excess payment was made during a request.
     * @dev This contract may receive excess funds from Quex Core after calling `request()`.
     *      Therefore, the `receive()` function must be implemented to properly handle refunds.
     */
    receive() external payable virtual {
        (bool success,) = payable(owner()).call{value: msg.value}("");
        require(success, "Transfer failed");
    }
}
