import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { SushiBarAdapter, SushiBarAdapter__factory } from "../../../typechain";

task("deploy-sushi-bar-adapter").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const sushiBarAdapterFactory: SushiBarAdapter__factory = await ethers.getContractFactory("SushiBarAdapter");
  const sushiBarAdapter: SushiBarAdapter = <SushiBarAdapter>await sushiBarAdapterFactory.deploy();
  await sushiBarAdapter.deployed();
  console.log("SushiBarAdapter deployed to: ", sushiBarAdapter.address);
});
