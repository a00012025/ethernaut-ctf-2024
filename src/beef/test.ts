import { bytesToHex, defineChain, serializeTransaction } from "viem";
import { FeeMarketEIP1559Transaction, LegacyTransaction } from "@ethereumjs/tx";
import { Common, Chain, Hardfork } from "@ethereumjs/common";
import * as util from "@ethereumjs/util";

const common = new Common({
  chain: Chain.Mainnet,
  hardfork: Hardfork.London,
});

async function main() {
  const tx = FeeMarketEIP1559Transaction.fromTxData({
    data: "0x095ea7b3000000000000000000000000ef0c7edfde9caf6983da64c44d46a70120a7b3730000000000000000000000000000000000000000000000000000000000000064",
    gasLimit: "0x9703",
    maxFeePerGas: "0x12a05f200",
    maxPriorityFeePerGas: "0xb2d05e00",
    nonce: "0x1",
    to: "0xef0c7edfde9caf6983da64c44d46a70120a7b373",
    value: "0x0",
    v: "0x1",
    r: "0x0000000000000000000000000000000000000000000000000000000000000001",
    s: "0x0000000000000000000000000000000000000000000000000000000000000001",
    chainId: 31337,
  });
  const hash = tx.hash();
  console.log(bytesToHex(hash));

  // const tx2 = LegacyTransaction.fromTxData({
  //   data: "0xa9059cbb0000000000000000000000001f4dbb55ee557c9836c423321d226656f4ac22330000000000000000000000000000000000000000000003a319b4935d77cf8000",
  //   gasLimit: util.intToHex(77697),
  //   gasPrice: util.intToHex(94258406254),
  //   nonce: util.intToHex(977),
  //   to: "0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD",
  //   value: "0x00",
  //   v: "0x26",
  //   r: "0x0",
  //   s: "0x0",
  // });
  // const hash2 = tx2.hash();
  // console.log(bytesToHex(hash2));
}

main().catch(console.error);
