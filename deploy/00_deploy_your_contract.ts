const MemoraNFTV2Module = require("../ignition/modules/MemoraNFTV2");

async function main() {
  const judgeAddress = "0x843E73b0143F4A7DeBF05a9646917787B06f3A46"; // Replace with actual judge address

  const { memoraNFT } = await MemoraNFTV2Module.ignition.deploy(MemoraNFTV2Module, {
    parameters: {
      judgeAddress: judgeAddress,
    },
  });

  console.log(`MemoraNFTV2 deployed to: ${await memoraNFT.getAddress()}`);
}

main().catch(console.error);