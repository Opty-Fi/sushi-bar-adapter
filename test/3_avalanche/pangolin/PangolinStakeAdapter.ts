import hre, { ethers } from "hardhat";
import { Artifact } from "hardhat/types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import PangolinStakePools from "../../../helpers/pangolin-stake-pools.json";
import { PangolinStakeAdapter } from "../../../typechain";
import { TestDeFiAdapter } from "../../../typechain/TestDeFiAdapter";
import { LiquidityPool, Signers } from "../../types";
import { shouldBehaveLikePangolinStakeAdapter } from "./PangolinStakeAdapter.behavior";
import { getOverrideOptions } from "../../utils";

const { deployContract } = hre.waffle;

describe("Unit tests", function () {
  before(async function () {
    this.signers = {} as Signers;
    const signers: SignerWithAddress[] = await hre.ethers.getSigners();
    this.signers.admin = signers[0];
    this.signers.owner = signers[1];
    this.signers.deployer = signers[2];
    this.signers.alice = signers[3];
    this.signers.operator = await hre.ethers.getSigner("0x6bd60f089B6E8BA75c409a54CDea34AA511277f6");

    // deploy Pangolin Stake Adapter
    const pangolinStakeAdapterArtifact: Artifact = await hre.artifacts.readArtifact("PangolinStakeAdapter");
    this.pangolinStakeAdapter = <PangolinStakeAdapter>(
      await deployContract(
        this.signers.deployer,
        pangolinStakeAdapterArtifact,
        [ethers.constants.AddressZero],
        getOverrideOptions(),
      )
    );

    // deploy TestDeFiAdapter Contract
    const testDeFiAdapterArtifact: Artifact = await hre.artifacts.readArtifact("TestDeFiAdapter");
    this.testDeFiAdapter = <TestDeFiAdapter>(
      await deployContract(this.signers.deployer, testDeFiAdapterArtifact, [], getOverrideOptions())
    );
  });

  describe("PangolinStakeAdapter", function () {
    Object.keys(PangolinStakePools).map((token: string) => {
      shouldBehaveLikePangolinStakeAdapter(token, (PangolinStakePools as LiquidityPool)[token]);
    });
  });
});
