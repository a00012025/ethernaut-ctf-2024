// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Challenge} from "../../src/wombocombo/Challenge.sol";
import {Staking} from "../../src/wombocombo/Staking.sol";
import {Forwarder} from "../../src/wombocombo/Forwarder.sol";
import {Token} from "../../src/wombocombo/Token.sol";

contract ExplotTest is Test {
    Challenge public challenge;
    Token public token;
    Token public reward;
    Forwarder public forwarder;
    Staking public staking;
    address public player = address(0x123);

    function setUp() public {
        token = new Token("Staking", "STK", 100 * 10 ** 18);
        reward = new Token("Reward", "RWD", 100_000_000 * 10 ** 18);

        forwarder = new Forwarder();

        staking = new Staking(token, reward, address(forwarder));

        staking.setRewardsDuration(20);
        reward.transfer(address(staking), reward.totalSupply());
        token.transfer(player, token.totalSupply());

        challenge = new Challenge(staking, forwarder);
    }

    function test_Exploit() public {
        staking.setRewardsDuration(1);
        staking.notifyRewardAmount(100_000_000 * 10 ** 18);
    }
}
