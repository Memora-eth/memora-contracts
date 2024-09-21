const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const MemoraNFTV2Module = buildModule("MemoraNFTV2Module", (m) => {
  const name = m.getParameter("name", "MemoraNFT");
  const symbol = m.getParameter("symbol", "MNFT");
  const judgeAddress = m.getParameter("judgeAddress", "0x843E73b0143F4A7DeBF05a9646917787B06f3A46");

  const memoraNFT = m.contract("MemoraNFTV2", [name, symbol, judgeAddress]);

  return { memoraNFT };
});

module.exports = MemoraNFTV2Module;