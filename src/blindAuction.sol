pragma solidity >0.4.23 <0.5.0;

contract BlindAuction {
        struct Bid {
                bytes32 blindedBid;
                uint deposit;
        }    

        address public beneficiary;
        uint public biddingEnd;
        uint public revealEnd;
        bool public ended;

        mapping(address => Bid[]) public bids;

        address public highestBidder;
        uint public highestBid;

        mapping(address => uint) pendingReturns;

        event AuctionEnded(address winner, uint highestBid);

        modifier onlyBefore(uint _time) {
                require(now < _time); _;  // therein, _ is replaced by the old function body
        }

        modifier onlyAfter(uint _time) {
                require(now > _time); _;
        }
        
        constructor(
                uint _biddingTime,
                uint _revealTime,
                address _beneficiary
        ) public {
                beneficiary = _beneficiary;
                biddingEnd = now + _biddingTime;
                revealEnd = biddingEnd + _revealTime;
        }

        function bid(bytes32 _blindedBid)
                public
                payable
                onlyBefore(biddingEnd)
        {
                bids[msg.sender].push(Bid({
                        blindedBid: _blindedBid,
                        deposit: msg.value
                }));
        }

        function reveal(
                uint[] _values,
                bool[] _fake,
                bytes32[] _secret
        )
                public
                onlyAfter(biddingEnd)
                onlyBefore(revealEnd)
        {
                uint length = bids[msg.sender].length;
                require(_values.length == length);
                require(_fake.length == length);
                require(_secret.length == length);

                uint refund;
                for (uint i = 0; i < length; i++) {
                        Bid storage bid = bids[msg.sender][i];
                        (uint value, bool fake, bytes32 secret) = (_values[i], _fake[i], _secret[i]);
                        // 编译器报错说，原本的keccak256函数只支持一个参数？所以换成下面这个函数了
                        //if (bid.blindedBid != keccak256(value, fake, secret)) {
                        if (bid.blindedBid != abi.encodePacked(value, fake, secret)) {
                                continue;
                        }
                        refund += bid.deposit;
                        if (!fake && bid.deposit >= value) {
                                if (placeBid(msg.sender, value)) {
                                        refund -= value;
                                }
                        }
                        bid.blindedBid = bytes32(0);
                }
                msg.sender.transfer(refund);
        }

        function placeBid(address bidder, uint value) internal
                returns (bool success)
        {
                if (value <= highestBid) {
                        return false;
                } 
                if (highestBidder != 0) {
                        pendingReturns[highestBidder] += highestBid;
                }
                highestBid = value;
                highestBidder = bidder;
                return true;
        }

        function withdraw() public {
                uint amount = pendingReturns[msg.sender];
                if (amount > 0) {
                        pendingReturns[msg.sender] = 0;
                        msg.sender.transfer(amount);
                }
        }

        function auctionEnd() 
                public
                onlyAfter(revealEnd)
        {
                require(!ended);
                emit AuctionEnded(highestBidder, highestBid);
                ended = true;
                beneficiary.transfer(highestBid);
        }

}
