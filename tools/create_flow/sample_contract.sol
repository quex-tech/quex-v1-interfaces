// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// Import IV1RequestRegistry interface and DataItem structure
import "https://github.com/quex-tech/quex-v1-interfaces/blob/fad2ceb5bff350b1eece52bdb74a2e01984f333e/interfaces/core/IQuexActionRegistry.sol";
import "@openzeppelin/contracts@4.5.0/access/Ownable.sol";

address constant QUEX_CORE = 0xD8a37e96117816D43949e72B90F73061A868b387;
IQuexActionRegistry constant quexCore = IQuexActionRegistry(QUEX_CORE);

struct Order {
    uint256 price;
    uint256 quantity;
}

struct OrderBook {
    uint256 lastUpdateId;
    Order[5] bids;
    Order[5] asks;
}

contract C is Ownable {
    uint256 requestId;
    OrderBook[] orderBooks;
    
    function request(uint256 flowId) public payable onlyOwner returns(uint256) {
        requestId = quexCore.createRequest{value:msg.value}(flowId);
        return requestId;
    }

    receive() external payable {
        payable(owner()).call{value: msg.value}("");
    }

    function processResponse(uint256 receivedRequestId, DataItem memory response, IdType idType) external {
        require(msg.sender == QUEX_CORE, "Only Quex Proxy can push data");
        require(receivedRequestId == requestId, "Unknown request ID");
        require(idType == IdType.RequestId, "Return type mismatch");
        orderBooks.push(abi.decode(response.value, (OrderBook)));
        return;
    }

    function getOrderBooks() external view returns (OrderBook[] memory) {
        return orderBooks;
    }

    function getLastBid() external view returns (Order memory) {
        require(orderBooks.length >= 1, "No order books recorded");
        return orderBooks[orderBooks.length - 1].bids[0];
    }
}
