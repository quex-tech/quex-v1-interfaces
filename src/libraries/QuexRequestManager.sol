// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "src/interfaces/core/IQuexActionRegistry.sol";
import "src/interfaces/core/IDepositManager.sol";
import "src/libraries/FlowBuilder.sol";

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
    /// @notice Reference to the Quex core
    address public quexCoreAddress;

    /// @notice Stores the ID of the most recent request sent to Quex core
    uint256 internal _requestId;

    /// @notice Stores the flow ID
    uint256 internal _flowId;

    /// @notice Stores the subscription ID
    uint256 internal _subscriptionId;

    /**
     * @dev Initializes the contract with the Quex Action Registry address and sets the owner.
     * @param _quexCoreAddress Address of the Quex Action Registry contract
     */
    constructor(address _quexCoreAddress) Ownable(msg.sender) {
        quexCoreAddress = _quexCoreAddress;
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
     * @notice Build flow from config and register it in FlowRegistry
     */
    function registerFlow(FlowBuilder.FlowConfig memory config) public virtual onlyOwner {
        uint256 flowId = config.build();
        setFlowId(flowId);
    }

    /**
     * @notice Set up subscription
     */
    function createSubscription(uint256 depositValue) internal virtual onlyOwner {
        IDepositManager depositManager = IDepositManager(quexCoreAddress);
        _subscriptionId = depositManager.createSubscription();
        depositManager.addConsumer(_subscriptionId, address(this));
        depositManager.deposit{value: depositValue}(_subscriptionId);
    }

    /**
     * @notice Performs necessary validation checks for an incoming response.
     * @dev Ensures the response originates from the Quex core contract and has passed all validity checks.
     *      Also verifies that the response corresponds to the latest request.
     * @param receivedRequestId The ID of the request associated with this response.
     */
    modifier verifyResponse(uint256 receivedRequestId, IdType idType) {
        require(msg.sender == quexCoreAddress, "Only Quex Proxy can push data");
        require(receivedRequestId == _requestId, "Unknown request ID");
        require(idType == IdType.RequestId, "Return type mismatch");
        _;
    }

    /**
     * @notice Sends a request to the Quex Action Registry
     * @return The request ID of the newly created request.
     */
    function request() public virtual onlyOwner returns (uint256) {
        require(_flowId != 0, "Flow ID is not set");
        require(_subscriptionId != 0, "Subscription ID is not set");
        IQuexActionRegistry actionRegistry = IQuexActionRegistry(quexCoreAddress);
        _requestId = actionRegistry.createRequest(_flowId, _subscriptionId);
        return _requestId;
    }

    /**
     * @notice Withdraw all money from subscription to contract owner
     */
    function withdraw() public onlyOwner {
        IDepositManager depositManager = IDepositManager(quexCoreAddress);
        depositManager.withdraw(_subscriptionId, msg.sender);
    }
}
