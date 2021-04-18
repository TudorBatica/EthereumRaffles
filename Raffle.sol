pragma solidity 0.6.6;

import "https://raw.githubusercontent.com/smartcontractkit/chainlink/master/evm-contracts/src/v0.6/VRFConsumerBase.sol";

contract Raffle is VRFConsumerBase {
    
    string public name;

    // contract deployer
    address public iniatedBy;
    
    uint public totalTickets;

    uint public soldTickets;
    
    // price in wei
    uint public ticketPrice;
    
    // a list of participants and their assigned tickets
    // participants[i] = addr => ticket i has been bought by addr
    address[] public participants;
    
    address payable public winner;
    
    bytes32 internal VRFKeyHash;
    
    uint256 internal VRFFee;
    
    uint256 internal randomResult;
    
    constructor(string memory _name, uint _totalTickets, uint _ticketPrice) 
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        ) public
    {
        name = _name;
        iniatedBy = msg.sender;
        totalTickets = _totalTickets;
        ticketPrice = _ticketPrice;
        soldTickets = 0;
        participants = new address[](totalTickets);
        winner = address(0);
        
        VRFKeyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        VRFFee = 0.1 * 10 ** 18; // 0.1 LINK
    }
    
    function getRandomNumber(uint256 userProvidedSeed) internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= VRFFee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(VRFKeyHash, VRFFee, userProvidedSeed);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness.mod(totalTickets);
    }
    
    function sellTickets() payable public {
        require(soldTickets < totalTickets, "All tickets have been bought.");
        require(msg.value >= ticketPrice, "Not enough wei sent.");
        uint numberOfTickets = msg.value / ticketPrice;
        require(totalTickets - soldTickets >= numberOfTickets, "Not enough tickets left.");

        for(uint i = soldTickets; i < soldTickets + numberOfTickets; i ++) {
            participants[i] = msg.sender;
        }
        soldTickets += numberOfTickets;

        if(soldTickets == totalTickets) {
            getRandomNumber(123);
            winner = payable(participants[randomResult]);
            bool sent = winner.send(address(this).balance);
            require(sent, "Failed to send eth to winner");
        }
    }
}
