import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { PangolinStakeAdapter, PangolinStakeAdapter__factory } from "../../../typechain";

task("deploy-pangolin-stake-adapter").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const pangolinStakeAdapterFactory: PangolinStakeAdapter__factory = await ethers.getContractFactory(
    "PangolinStakeAdapter",
  );
  const pangolinStakeAdapter: PangolinStakeAdapter = <PangolinStakeAdapter>await pangolinStakeAdapterFactory.deploy();
  await pangolinStakeAdapter.deployed();
  console.log("PangolinStakeAdapter deployed to: ", pangolinStakeAdapter.address);
});
