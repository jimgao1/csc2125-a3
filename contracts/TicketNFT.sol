// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ITicketNFT} from "./interfaces/ITicketNFT.sol";

// Uncomment this line to use console.log
import "hardhat/console.sol";

contract TicketNFT is ERC1155, ITicketNFT {

    address ownerAddr;
    address senderAddr;

    constructor(address marketAddr) ERC1155("https://cs.toronto.edu/{id}.json") {
        // maybe should be to
        ownerAddr = marketAddr;
        senderAddr = msg.sender;
    }

    function mintFromMarketPlace(address to, uint256 nftId) public {
        _mint(to, nftId, 1, "");
    }

    function owner() public view returns (address owneraddr) {
        return ownerAddr;
    }
}
