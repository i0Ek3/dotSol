pragma solidity ^0.4.24;

contract Ballot { // voting with delegation

        struct Voter {
                uint weight; // for delegation
                bool voted; // true = voted
                address delegate;
                uint vote; // index of voted proposal
        }

        struct Proposal {
                bytes32 name;
                uint voteCount;
        }

        address public chairperson;
        mapping(address => Voter) public voters; // type: mapping
        Proposal[] public proposals;
        
        constructor(bytes32[] proposalNames) public { // a new ballot to choose one of proposalNames
                chairperson = msg.sender;
                voters[chairperson].weight = 1;
                for (uint i = 0; i < proposalNames.length; i++) { // create a proposal object to store proposalNames and it's vote count
                        proposals.push(Proposal({
                                name: proposalNames[i],
                                voteCount: 0
                        }));
                }
        
        }
        
        function grantVote(address voter) public {
                require(
                        msg.sender == chairperson,
                        "Only chairperson can give right to vote."
                );
                require(
                        !voters[voter].voted,
                        "The voter already voted."
                );
                require(voters[voter].weight == 0);
                voters[voter].weight == 1;
        }
        
        function delegate(address to) public {
                Voter storage sender = voters[msg.sender];
                require(!sender.voted, "You already voted.");
                require(to != msg.sender, "Self-delegation is disallowed.");
                while (voters[to].delegate != address(0)) {
                        to = voters[to].delegate;
                        require(to != msg.sender, "Found loop in delegation.");
                }
                sender.voted = true;
                sender.delegate = to;
                Voter storage delegate_ = voters[to];
                if (delegate_.voted) {
                        proposals[delegate_.vote].voteCount += sender.weight;
                } else {
                        delegate_.weight += sender.weight;
                }
        }
        
        function vote(uint proposal) public {
                Voter storage sender = voters[msg.sender];
                require(!sender.voted, "Already voted.");
                sender.voted = true;
                sender.vote = proposal;
        }
        
        function winProposal() public view
                returns (uint winProposal_)
        {
                uint winVoteCount = 0;
                for (uint p = 0; p < proposals.length; p++) {
                        if (proposals[p].voteCount > winVoteCount) {
                                winVoteCount = proposals[p].voteCount;
                                winProposal_ = p;
                        }
                }
        }
        
        function winnerName() public view
                returns (bytes32 winnerName_)
        {
                winnerName_ = proposals[winProposal()].name;
        }
}




