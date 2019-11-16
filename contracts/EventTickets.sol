pragma solidity ^0.5.0;

contract EventTickets {

    address payable public owner;
    uint TICKET_PRICE = 100 wei;

    struct Event {
        string description;
        string url;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

    Event public myEvent;

    event LogBuyTickets(address buyer, uint amount);
    event LogGetRefund(address buyer, uint amountRefunded);
    event LogEndSale(address owner, uint profit);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor (string memory _description, string memory _url, uint _totalTickets) public {
        owner = msg.sender;
        myEvent.description = _description;
        myEvent.url = _url;
        myEvent.totalTickets = _totalTickets;
        myEvent.sales = 0;
        myEvent.isOpen = true;
    }

    function readEvent() public view returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen) {
        description = myEvent.description;
        website = myEvent.url;
        totalTickets = myEvent.totalTickets;
        sales = myEvent.sales;
        isOpen = myEvent.isOpen;
    }

    function getBuyerTicketCount(address _buyer) public view returns(uint) {
        return myEvent.buyers[_buyer];
    }

    function buyTickets(uint _ticketAmount) public payable {
        require(myEvent.isOpen);
        require(myEvent.totalTickets >= _ticketAmount);
        uint totalPrice = _ticketAmount * TICKET_PRICE;
        require(msg.value >= totalPrice);

        uint change = msg.value - totalPrice;

        myEvent.totalTickets -= _ticketAmount;
        myEvent.buyers[msg.sender] += _ticketAmount;
        myEvent.sales += _ticketAmount;

        msg.sender.transfer(change);

        emit LogBuyTickets(msg.sender, _ticketAmount);
    }

    function getRefund() public {
        require(myEvent.buyers[msg.sender] > 0);
        myEvent.totalTickets += myEvent.buyers[msg.sender];
        uint amountToRefund = myEvent.buyers[msg.sender] * TICKET_PRICE;
        myEvent.buyers[msg.sender] = 0;
        msg.sender.transfer(amountToRefund);

        emit LogGetRefund(msg.sender, amountToRefund);
    }

    function endSale() public onlyOwner {
        myEvent.isOpen = false;
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
        emit LogEndSale(msg.sender, balance);
    }
}
