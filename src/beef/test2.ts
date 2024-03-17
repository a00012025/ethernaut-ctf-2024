// read from "./t.json"
const rpcs = require("./t.json");

async function main() {
  for (const rpc of Object.keys(rpcs)) {
    const arr = rpcs[rpc].rpcs;

    if (arr && arr.length > 0 && arr[0]) {
      let url = arr[0];
      if (!(url.startsWith && url.startsWith("https://"))) {
        url = url["url"];
      }
      if (!url) {
        continue;
      }
      try {
        const res = await fetch(url, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            jsonrpc: "2.0",
            id: 1,
            method: "eth_getTransactionCount",
            params: ["0x00000f940f38270786962F6eC582B4EdEa4Bb440", "latest"],
          }),
        });
        const resJson = await res.json();
        console.log(rpc, resJson["result"], url);
      } catch (error) {}
    }
  }
}

main().catch(console.error);
