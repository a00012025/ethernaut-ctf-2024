#!/bin/bash

RPC_URL=http://34.32.151.200:8545/nQiWsqxybRCgqyCOYXQiupBW/main
CHALLENGE=0x7B84Ee4546520B3C0769659318c718C5BC86A5d7
RES=$(cast call $CHALLENGE 'BEEF()' --rpc-url $RPC_URL)
BEEF="0x${RES: -40}"
echo "Beef Contract: $BEEF"

RES=$(cast call "$BEEF" 'owner()' --rpc-url $RPC_URL)
OWNER="0x${RES: -40}"
echo "Owner: $OWNER" # 0xccd73c18a8f2d80163ae1a4b852c960261ee028d
echo "User: 0xa5d6a55a36bbef4863c1fA2b0A3d20fD68225775"
echo "New user: 0xbeef6B156a9cd241B95A841CDF3B18995C2E35CC"