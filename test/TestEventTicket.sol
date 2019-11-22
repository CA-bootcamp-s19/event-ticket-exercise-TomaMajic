pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EventTickets.sol";

contract Owner {
    EventTickets private eventTicketsV1;

    function () external payable {}

    function getEventTicketsV1() public view returns (EventTickets) {
        return eventTicketsV1;
    }

    function createEventV1(string memory _description, string memory _url, uint _totalTickets) public {
        eventTicketsV1 = new EventTickets(_description, _url, _totalTickets);
    }

    function endSaleV1() public returns (bool status) {
        (status, ) = address(eventTicketsV1).call(abi.encodeWithSignature("endSale()"));
    }
}

contract Buyer {
    EventTickets private eventTicketsV1;

    uint constant public TICKET_PRICE = 100 wei;

    function () external payable {}

    constructor(EventTickets _eventTickets) public {
        eventTicketsV1 = _eventTickets;
    }

    function buyTicketsV1(uint _ticketAmount) public returns (bool status) {
        (status, ) = address(eventTicketsV1).call.value(_ticketAmount * TICKET_PRICE)(abi.encodeWithSignature("buyTickets(uint256)", _ticketAmount));
    }

    function getRefundV1() public returns (bool status) {
        (status, ) = address(eventTicketsV1).call(abi.encodeWithSignature("getRefund()"));
    }

    function endSaleV1() public returns (bool status) {
        (status, ) = address(eventTicketsV1).call(abi.encodeWithSignature("endSale()"));
    }
}

contract TestEventTicket {
    uint public initialBalance = 1 ether;
    uint public buyerInitialBalance = 700 wei;
    uint public ownerInitialBalance = 500 wei;
    uint public TICKET_PRICE = 100 wei;

    string private testDescription = "Test";
    string private testUrl = "test.com";
    uint private testTotalTickets = 10;

    Owner private firstOwner;
    Buyer private firstBuyer;
    Buyer private secondBuyer;

    EventTickets private eventTicketsV1;

    function () external payable {}

    constructor() public payable {}

    function setupContracts() public {
        firstOwner = createOwner();
        firstOwner.createEventV1(testDescription, testUrl, testTotalTickets);

        eventTicketsV1 = firstOwner.getEventTicketsV1();

        firstBuyer = createBuyer(eventTicketsV1);
        secondBuyer = createBuyer(eventTicketsV1);
    }

    function createOwner() internal returns (Owner) {
        Owner owner = new Owner();
        address(owner).transfer(ownerInitialBalance);
        return owner;
    }

    function createBuyer(EventTickets _eventTickets) internal returns (Buyer) {
        Buyer buyer = new Buyer(_eventTickets);
        address(buyer).transfer(buyerInitialBalance);
        return buyer;
    }

    modifier setup {
        setupContracts();
        _;
    }


    /*

    TEST EventTickets Version 1

    */

    modifier alreadyBoughtV1(Buyer _buyer, uint _ticketAmount) {
        _buyer.buyTicketsV1(_ticketAmount);
        _;
    }

    // Test setup

    function testV1ContractSetup() public setup {
        (string memory description, string memory url, uint totalTickets, uint sales, bool isOpen) = eventTicketsV1.readEvent();
        Assert.equal(description, testDescription, "The description should be Test");
        Assert.equal(url, testUrl, "The url should be test.com");
        Assert.equal(totalTickets, testTotalTickets, "Total ticket count should be 10");
        Assert.equal(sales, 0, "The sales count should be 0 at the start of the event ticket sale");
        Assert.equal(isOpen, true, "Event should be open");
    }

    // Test buy tickets V1

    function testBuyTicketsV1IfNoSufficientFunds() public setup {
        bool status = firstBuyer.buyTicketsV1(10);
        Assert.isFalse(status, "The buyer has no funds for all the tickets");
    }

    function testBuyTicketsV1IfNoTicketsLeft() public setup {
        bool status = firstBuyer.buyTicketsV1(7);
        Assert.equal(status, true, "The first buyer should successfully buy tickets");
        status = secondBuyer.buyTicketsV1(4);
        Assert.isFalse(status, "The second buyer should fail to buy excess tickets");
    }

    function testBuyTicketsV1EventParameters() public setup {
        bool status = firstBuyer.buyTicketsV1(7);
        Assert.equal(status, true, "The first buyer should successfully buy tickets");
        (,, uint totalTickets, uint sales,) = eventTicketsV1.readEvent();
        Assert.equal(totalTickets, testTotalTickets - 7, "Total tickets should be decreased");
        Assert.equal(sales, 7, "Total sales count should increase");
        uint buyerTicketCount = eventTicketsV1.getBuyerTicketCount(address(firstBuyer));
        Assert.equal(buyerTicketCount, 7, "The buyer ticket count should increase");
    }

    // Test refund V1

    function testRefundV1IfNoTicketsBought() public setup {
        bool status = firstBuyer.getRefundV1();
        Assert.isFalse(status, "Buyer cannot get refunded if they bought no tickets");
    }

    function testRefundV1IfEventClosed() public setup alreadyBoughtV1(firstBuyer, 7) {
        bool status = firstOwner.endSaleV1();
        Assert.equal(status, true, "Sale successfully closed");
        status = firstBuyer.getRefundV1();
        Assert.isFalse(status, "Buyer cannot get refunded if the sale is closed");
    }

    function testRefundV1EventParameters() public setup alreadyBoughtV1(firstBuyer, 7) {
        bool status = firstBuyer.getRefundV1();
        Assert.equal(status, true, "The refund should be successful");
        (,, uint totalTickets, uint sales,) = eventTicketsV1.readEvent();
        Assert.equal(totalTickets, testTotalTickets, "Total tickets should be back to the starting amount");
        Assert.equal(sales, 0, "Total sales count should decrease to 0");
        uint buyerTicketCount = eventTicketsV1.getBuyerTicketCount(address(firstBuyer));
        Assert.equal(buyerTicketCount, 0, "The buyer ticket count should be 0");
    }

    // Test end sale V1

    function testEndSaleV1IfNotCalledByOwner() public setup {
        bool status = firstBuyer.endSaleV1();
        Assert.isFalse(status, "Buyer is not allowed to end the sale");
    }

    function testEndSaleV1IfAlreadyEnded() public setup {
        bool status = firstOwner.endSaleV1();
        Assert.equal(status, true, "The sale should successfully end");
        status = firstOwner.endSaleV1();
        Assert.isFalse(status, "The sale has already ended");
    }
}