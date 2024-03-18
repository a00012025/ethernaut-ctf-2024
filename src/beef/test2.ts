// read from "./t.json"
const rpcs = require("./t.json");

async function main() {
  for (const rpc of Object.keys(rpcs)) {
    const arr = rpcs[rpc].rpcs;

    if (arr && arr.length > 0 && arr[0]) {
      for (const urlObj of arr) {
        let url = urlObj;
        if (!(url.startsWith && url.startsWith("https://"))) {
          url = url["url"];
        }
        if (!url) {
          continue;
        }
        try {
          // console.log("fetching", url);
          const res = await fetch(url, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              jsonrpc: "2.0",
              id: 1,
              method: "eth_getTransactionCount",
              params: ["0xa5d6a55a36bbef4863c1fA2b0A3d20fD68225775", "latest"],
            }),
          });
          const resJson = await res.json();
          console.log(rpc, resJson["result"], url);
          break;
        } catch (error) {
          // console.log(error);
        }
      }
    }
  }
}

main().catch(console.error);
