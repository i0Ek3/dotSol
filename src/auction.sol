pragma solidity ^0.4.24;

contract Auction { // 拍卖
        address public beneficiary; // 受益人
        uint public auctionEnd; // 拍卖结束

        address public highestBidder; // 最高出价人
        uint public highestBid; //最高出价

        mapping(address => uint) pendingReturns;

        bool ended;

        // 触发事件
        event HighestBidIncreased(address bidder, uint amount);
        event AuctionEnded(address winner, uint amount);

        constructor(
                    uint _biddingTime, // 投标时间
                    address _beneficiary
        ) public {
                beneficiary = _beneficiary;
                auctionEnd = now + _biddingTime;
        }

        function bid() public payable {
                require(
                        now <= auctionEnd,
                        "Auction already ended."
                );

                require(
                        msg.value > highestBid,
                        "There already is a higher bid."
                );
                
                // 更新
                if (highestBid != 0) {
                        pendingReturns[highestBidder] += highestBid;
                }
                highestBidder = msg.sender;
                highestBid = msg.value;
                emit HighestBidIncreased(msg.sender, msg.value);
        }

        // 撤回过高的出价
        function withdraw() public returns (bool) {
                uint amount = pendingReturns[msg.sender];
                if (amount > 0) {
                        pendingReturns[msg.sender] = 0;
                        if (!msg.sender.send(amount)) {
                                pendingReturns[msg.sender] = amount;
                                return false;
                        }
                }
                return true;
        }

        function auctionEnd() public {
                require(now >= auctionEnd, "Auction not yet ended.");
                require(!ended, "auctionEnd has already been called.");
                
                ended = true;
                emit AuctionEnded(highestBidder, highestBid);

                beneficiary.transfer(highestBid); // 受益人获得最高出价
        }

}
