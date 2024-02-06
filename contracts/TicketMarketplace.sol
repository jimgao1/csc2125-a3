// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol"; 
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
import "hardhat/console.sol";

contract TicketMarketplace is ITicketMarketplace {

    struct Event {
        uint128 nextTicketToSell;
        uint128 maxTickets;
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;
    }

    address ownerAddr;
    address sampleCoinAddr;
    TicketNFT ticketNft;
    address ticketAddr;

    uint128 curEventId;
    mapping (uint128 => Event) public events;

    constructor(address coinaddr) public {
        curEventId = 0;
        sampleCoinAddr = coinaddr;
        ownerAddr = msg.sender;
        ticketNft = new TicketNFT(address(this));
    }

    function createEvent(uint128 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) public {
        if (msg.sender != ownerAddr) revert("Unauthorized access");

        events[curEventId] = Event(
            0,
            maxTickets,
            pricePerTicket,
            pricePerTicketERC20
        );

        emit EventCreated(
            curEventId, 
            events[curEventId].maxTickets, 
            events[curEventId].pricePerTicket, 
            events[curEventId].pricePerTicketERC20
        );

        curEventId += 1;
    }

    function currentEventId() public view returns (uint128 eventId) {
        return curEventId;
    }

    function ERC20Address() public view returns (address erc20) {
        return sampleCoinAddr;
    }

    function owner() public view returns (address owneraddr) {
        return ownerAddr;
    }

    function nftContract() public view returns (TicketNFT) {
        return ticketNft;
    }

    /*
    function events(uint128 eid) public view returns (Event memory) {
        return events[eid];
    }
    */
    
    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) public {
        if (msg.sender != ownerAddr) revert("Unauthorized access");
        // if (eventId >= curEventId) revert("Invalid event id");

        if (events[eventId].maxTickets > newMaxTickets) revert("The new number of max tickets is too small!");
        events[eventId].maxTickets = newMaxTickets;

        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    function setPriceForTicketETH(uint128 eventId, uint256 price) public {
        if (msg.sender != ownerAddr) revert("Unauthorized access");
        // if (eventId >= curEventId) revert("Invalid event id");
        events[eventId].pricePerTicket = price;

        emit PriceUpdate(eventId, price, "ETH");
    }

    function setPriceForTicketERC20(uint128 eventId, uint256 price) public {
        if (msg.sender != ownerAddr) revert("Unauthorized access");
        // if (eventId >= curEventId) revert("Invalid event id");
        events[eventId].pricePerTicketERC20 = price;

        emit PriceUpdate(eventId, price, "ERC20");
    }

    function buyTickets(uint128 eventId, uint128 ticketCount) public payable {
        uint256 m = type(uint256).max / events[eventId].pricePerTicket;
        if (ticketCount > m) {
            revert("Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        }

        uint256 cost = ticketCount * events[eventId].pricePerTicket;
        // console.log("value", msg.value, "cost", cost);
        
        if (msg.value < cost) revert("Not enough funds supplied to buy the specified number of tickets.");

        if (events[eventId].nextTicketToSell + ticketCount > events[eventId].maxTickets)
            revert("We don't have that many tickets left to sell!");

        for (uint128 tid = 0; tid < ticketCount; tid += 1) {
            uint128 seat = events[eventId].nextTicketToSell + tid;
            uint256 nftid = ((uint256)(eventId) << 128) + seat;
            ticketNft.mintFromMarketPlace(msg.sender, nftid);
        }
        events[eventId].nextTicketToSell += ticketCount;

        emit TicketsBought(eventId, ticketCount, "ETH");
    }

    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) public {
        uint256 m = type(uint256).max / events[eventId].pricePerTicketERC20;
        if (ticketCount > m) {
            revert("Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        }

        uint256 cost = ticketCount * events[eventId].pricePerTicketERC20;

        IERC20 coin = IERC20(sampleCoinAddr);
        uint256 bal = coin.balanceOf(msg.sender);
        if (bal < cost) revert("Not enough funds supplied to buy the specified number of tickets.");
        coin.transferFrom(msg.sender, address(this), cost);

        if (events[eventId].nextTicketToSell + ticketCount > events[eventId].maxTickets)
            revert("We don't have that many tickets left to sell!");

        for (uint128 tid = 0; tid < ticketCount; tid += 1) {
            uint128 seat = events[eventId].nextTicketToSell + tid;
            uint256 nftid = ((uint256)(eventId) << 128) + seat;
            ticketNft.mintFromMarketPlace(msg.sender, nftid);
        }
        events[eventId].nextTicketToSell += ticketCount;

        
        emit TicketsBought(eventId, ticketCount, "ERC20");
    }

    function setERC20Address(address newERC20Address) public {
        if (msg.sender != ownerAddr) revert("Unauthorized access");
        sampleCoinAddr = newERC20Address;

        emit ERC20AddressUpdate(newERC20Address);
    }
}
