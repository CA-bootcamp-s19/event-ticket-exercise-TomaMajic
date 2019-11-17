pragma solidity ^0.5.0;

contract EventTicketsV2 {

    address payable public owner;
    uint constant public TICKET_PRICE = 100 wei;
    uint public idGenerator;

    struct Event {
        string description;
        string url;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

    mapping (uint => Event) public events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor () public {
        owner = msg.sender;
    }

    function addEvent(string memory _description, string memory _url, uint _totalTickets) public onlyOwner returns(uint) {
        Event memory newEvent = Event({
            description: _description,
            url: _url,
            totalTickets: _totalTickets,
            sales: 0,
            isOpen: true
        });

        uint eventID = idGenerator;
        events[eventID] = newEvent;
        idGenerator++;

        emit LogEventAdded(_description, _url, _totalTickets, eventID);
        return eventID;
    }

    function readEvent(uint _eventID) public view returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen) {
        Event memory myEvent = events[_eventID];
        description = myEvent.description;
        website = myEvent.url;
        totalTickets = myEvent.totalTickets;
        sales = myEvent.sales;
        isOpen = myEvent.isOpen;
    }

    function getBuyerNumberTickets(uint _eventID) public view returns(uint) {
        Event storage myEvent = events[_eventID];
        return myEvent.buyers[msg.sender];
    }

    function buyTickets(uint _eventID, uint _ticketAmount) public payable {
        Event storage myEvent = events[_eventID];
        require(myEvent.isOpen);
        require(myEvent.totalTickets >= _ticketAmount);
        uint totalPrice = _ticketAmount * TICKET_PRICE;
        require(msg.value >= totalPrice);

        uint change = msg.value - totalPrice;
        myEvent.totalTickets -= _ticketAmount;
        myEvent.buyers[msg.sender] += _ticketAmount;
        myEvent.sales += _ticketAmount;

        msg.sender.transfer(change);

        emit LogBuyTickets(msg.sender, _eventID, _ticketAmount);
    }

    function getRefund(uint _eventID) public {
        Event storage myEvent = events[_eventID];
        require(myEvent.isOpen);
        require(myEvent.buyers[msg.sender] > 0);

        uint ticketAmount = myEvent.buyers[msg.sender];
        myEvent.totalTickets += ticketAmount;
        uint amountToRefund = ticketAmount * TICKET_PRICE;
        myEvent.buyers[msg.sender] = 0;
        myEvent.sales -= ticketAmount;

        msg.sender.transfer(amountToRefund);

        emit LogGetRefund(msg.sender, _eventID, ticketAmount);
    }

    function endSale(uint _eventID) public onlyOwner {
        Event storage myEvent = events[_eventID];
        require(myEvent.isOpen);
        myEvent.isOpen = false;
        uint balance = myEvent.sales * TICKET_PRICE;
        msg.sender.transfer(balance);

        emit LogEndSale(msg.sender, balance, _eventID);
    }
}
