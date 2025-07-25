// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IQuexActionRegistry, IdType} from "src/interfaces/core/IQuexActionRegistry.sol";
import {FlowBuilder} from "src/libraries/FlowBuilder.sol";

using FlowBuilder for FlowBuilder.FlowConfig;

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
    error QuexRequestManager_FlowIdAlreadySet();
    error QuexRequestManager_FlowIdNotSet();
    error QuexRequestManager_OnlyQuexProxyCanPushData();
    error QuexRequestManager_UnknownRequestId();
    error QuexRequestManager_ReturnTypeIdMismatch();
    error QuexRequestManager_TransferFailed();
    error QuexRequestManager_FlowIdCannotBeZero();

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
        if (flowId == 0) {
            revert QuexRequestManager_FlowIdCannotBeZero();
        }
        _flowId = flowId;
    }

    /**
     * @notice Build flow from config and register it in FlowRegistry
     */
    function registerFlow(FlowBuilder.FlowConfig memory config) public virtual onlyOwner {
        uint256 flowId = config.build();
        setFlowId(flowId);
    }

    /**
     * @notice Performs necessary validation checks for an incoming response.
     * @dev Ensures the response originates from the Quex core contract and has passed all validity checks.
     *      Also verifies that the response corresponds to the latest request.
     * @param receivedRequestId The ID of the request associated with this response.
     */
    modifier verifyResponse(uint256 receivedRequestId, IdType idType) {
        if (msg.sender != address(quexCore)) {
            revert QuexRequestManager_OnlyQuexProxyCanPushData();
        }
        if (receivedRequestId != _requestId) {
            revert QuexRequestManager_UnknownRequestId();
        }
        if (idType != IdType.RequestId) {
            revert QuexRequestManager_ReturnTypeIdMismatch();
        }
        _;
    }

    /**
     * @notice Sends a request to the Quex Action Registry
     * @return The request ID of the newly created request.
     */
    function request() public payable virtual onlyOwner returns (uint256) {
        if (_flowId == 0) {
            revert QuexRequestManager_FlowIdNotSet();
        }
        _requestId = quexCore.createRequest{value: msg.value}(_flowId);
        return _requestId;
    }

    /**
     * @notice Handles refunds if excess payment was made during a request.
     * @dev This contract may receive excess funds from Quex Core after calling `request()`.
     *      Therefore, the `receive()` function must be implemented to properly handle refunds.
     */
    // solhint-disable-next-line no-complex-fallback
    receive() external payable virtual {
        (bool success,) = payable(owner()).call{value: msg.value}("");
        if (!success) {
            revert QuexRequestManager_TransferFailed();
        }
    }
}
