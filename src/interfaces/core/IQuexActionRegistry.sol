// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

enum IdType {
    RequestId,
    FlowId
}

struct DataItem {
    uint256 timestamp;
    uint256 error;
    bytes value;
}

struct OracleMessage {
    uint256 actionId;
    DataItem dataItem;
    address relayer;
}

struct ETHSignature {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

struct Request {
    uint256 requestId;
    uint256 flowId;
    address oraclePool;
    uint256 createdBlockNumber;
}

interface IQuexActionRegistry {
    error Flow_NotFound();
    error Request_NotFound();
    error Action_MismatchIds();
    error TrustDomain_NotValid();
    error TrustDomain_IsNotAllowedInOraclePool();
    error OracleMessage_SignatureIsInvalid();
    error OracleMessage_OutdatedMessage();
    error OracleMessage_TimestampFromFuture();
    error OnlyCallableInternally();
    error Subscription_InsufficientValue();
    error Subscription_NotFound(uint256 subscriptionId, address consumer);
    error Subscription_WrongCaller();
    error Subscription_TransferFailed();
    error Request_TooFreshToCancel();
    error Request_NotOwnedBySender();

    event RequestCreated(uint256 requestId, uint256 flowId, address oraclePool);

    function pushData(OracleMessage memory message, ETHSignature memory signature, uint256 flowId, uint256 tdId) external payable;
    function createRequest(uint256 flowId, uint256 subscriptionId) external returns (uint256 requestId);
    function fulfillRequest(OracleMessage memory message, ETHSignature memory signature, uint256 requestId, uint256 tdId) external;
    function getRequestFee(uint256 flowId) external view returns (uint256 nativeFee, uint256 gasFee);
    function getRequest(uint256 requestId) external view returns (Request memory request);
    function cancelRequest(uint256 requestId) external;
}
