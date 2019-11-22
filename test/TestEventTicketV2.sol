pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EventTicketsV2.sol";


contract Owner {
    EventTicketsV2 private eventTicketsV2;

    function () external payable {}

    function getEventTicketsV2() public view returns (EventTicketsV2) {
        return eventTicketsV2;
    }

    function createEventV2Contract() public {
        eventTicketsV2 = new EventTicketsV2();
    }

    function addEventV2(string memory _description, string memory _url, uint _totalTickets) public returns (bool status) {
        (status, ) = address(eventTicketsV2).call(abi.encodeWithSignature("addEvent(string,string,uint256)", _description, _url, _totalTickets));
    }

    function endSaleV2(uint _eventID) public returns (bool status) {
        (status, ) = address(eventTicketsV2).call(abi.encodeWithSignature("endSale(uint256)", _eventID));
    }
}

contract Buyer {
    EventTicketsV2 private eventTicketsV2;

    uint constant public TICKET_PRICE = 100 wei;

    function () external payable {}

    constructor(EventTicketsV2 _eventTicketsV2) public {
        eventTicketsV2 = _eventTicketsV2;
    }

    function getBuyerNumberTicketsV2(uint _eventID) public view returns (uint) {
        return eventTicketsV2.getBuyerNumberTickets(_eventID);
    }

    function buyTicketsV2(uint _eventID, uint _ticketAmount) public returns (bool status) {
        (status, ) = address(eventTicketsV2).call.value(_ticketAmount * TICKET_PRICE)(abi.encodeWithSignature("buyTickets(uint256,uint256)", _eventID, _ticketAmount));
    }

    function getRefundV2(uint _eventID) public returns (bool status) {
        (status, ) = address(eventTicketsV2).call(abi.encodeWithSignature("getRefund(uint256)", _eventID));
    }

    function endSaleV2(uint _eventID) public returns (bool status) {
        (status, ) = address(eventTicketsV2).call(abi.encodeWithSignature("endSale(uint256)", _eventID));
    }
}

contract TestEventTicketV2 {
    uint public initialBalance = 1 ether;
    uint public buyerInitialBalance = 7000 wei;
    uint public ownerInitialBalance = 500 wei;
    uint public TICKET_PRICE = 100 wei;

    string private firstTestDescription = "Test";
    string private firstTestUrl = "test.com";
    uint private firstTestTotalTickets = 10;

    string private secondTestDescription = "Test2";
    string private secondTestUrl = "test2.com";
    uint private secondTestTotalTickets = 20;

    Owner private firstOwner;
    Buyer private firstBuyer;
    Buyer private secondBuyer;

    EventTicketsV2 private eventTicketsV2;

    function () external payable {}

    constructor() public payable {}

    function setupContracts() public {
        firstOwner = createOwner();
        firstOwner.createEventV2Contract();
        firstOwner.addEventV2(firstTestDescription, firstTestUrl, firstTestTotalTickets);
        firstOwner.addEventV2(secondTestDescription, secondTestUrl, secondTestTotalTickets);

        eventTicketsV2 = firstOwner.getEventTicketsV2();

        firstBuyer = createBuyer(eventTicketsV2);
        secondBuyer = createBuyer(eventTicketsV2);
    }

    function createOwner() internal returns (Owner) {
        Owner owner = new Owner();
        address(owner).transfer(ownerInitialBalance);
        return owner;
    }

    function createBuyer(EventTicketsV2 _eventTicketsV2) internal returns (Buyer) {
        Buyer buyer = new Buyer(_eventTicketsV2);
        address(buyer).transfer(buyerInitialBalance);
        return buyer;
    }

    modifier setup {
        setupContracts();
        _;
    }

    /*

    TEST EventTickets Version 2

    */

    modifier alreadyBoughtV2(Buyer _buyer, uint _ticketAmount) {
        for (uint i = 0; i < 2; i++) {
            _buyer.buyTicketsV2(i, _ticketAmount);
        }
        _;
    }

    // Test setup

    function testV2ContractSetup() public setup {
        (string memory description, string memory url, uint totalTickets, uint sales, bool isOpen) = eventTicketsV2.readEvent(0);
        Assert.equal(description, firstTestDescription, "The description should be Test");
        Assert.equal(url, firstTestUrl, "The url should be test.com");
        Assert.equal(totalTickets, firstTestTotalTickets, "Total ticket count should be 10");
        Assert.equal(sales, 0, "The sales count should be 0 at the start of the event ticket sale");
        Assert.equal(isOpen, true, "Event should be open");
        (description, url, totalTickets, sales, isOpen) = eventTicketsV2.readEvent(1);
        Assert.equal(description, secondTestDescription, "The description should be Test");
        Assert.equal(url, secondTestUrl, "The url should be test.com");
        Assert.equal(totalTickets, secondTestTotalTickets, "Total ticket count should be 10");
        Assert.equal(sales, 0, "The sales count should be 0 at the start of the event ticket sale");
        Assert.equal(isOpen, true, "Event should be open");
    }

    // Test buy tickets V2

    function testBuyTicketsV2BuyingTicketsForDifferentEvents() public setup {
        bool status = firstBuyer.buyTicketsV2(0, 11);
        Assert.isFalse(status, "The buyer cannot buy more tickets than the total");
        status = firstBuyer.buyTicketsV2(1, 11);
        Assert.equal(status, true, "The second event has more tickets, so the purchase should be successful");
    }

    // Test refund V2

    function testRefundV2IfBuyerHasTicketsForTwoEvents() public setup alreadyBoughtV2(firstBuyer, 7) {
        uint buyerFirstEventTickets = firstBuyer.getBuyerNumberTicketsV2(0);
        Assert.equal(buyerFirstEventTickets, 7, "The user should have 7 tickets for the first event");
        uint buyerSecondEventTickets = firstBuyer.getBuyerNumberTicketsV2(1);
        Assert.equal(buyerSecondEventTickets, 7, "The user should have 7 tickets for the second event");
        bool status = firstBuyer.getRefundV2(0);
        Assert.equal(status, true, "The user should be successfully refunded");
        buyerFirstEventTickets = firstBuyer.getBuyerNumberTicketsV2(0);
        Assert.equal(buyerFirstEventTickets, 0, "The user should have 0 tickets for the first event");
        buyerSecondEventTickets = firstBuyer.getBuyerNumberTicketsV2(1);
        Assert.equal(buyerSecondEventTickets, 7, "The user should still have 7 tickets for the second event");
    }

    // Test end sale V2

    function testEndSaleV2IfOneSaleIsAlreadyClosed() public setup {
        bool status = firstOwner.endSaleV2(0);
        Assert.equal(status, true, "The first event should successfully end");
        status = firstOwner.endSaleV2(1);
        Assert.equal(status, true, "The second event should successfully end");
        status = firstOwner.endSaleV2(0);
        Assert.isFalse(status, "The first event is already closed");
    }
}