import hre, { ethers } from "hardhat";
import { Artifact } from "hardhat/types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import SushiBarPools from "../../../helpers/sushi-bar-pools.json";
import { SushiBarAdapter } from "../../../typechain";
import { TestDeFiAdapter } from "../../../typechain/TestDeFiAdapter";
import { LiquidityPool, Signers } from "../../types";
import { shouldBehaveLikeSushiBarAdapter } from "./SushiBarAdapter.behavior";
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

    // deploy Sushi Bar Adapter
    const sushiBarAdapterArtifact: Artifact = await hre.artifacts.readArtifact("SushiBarAdapter");
    this.sushiBarAdapter = <SushiBarAdapter>(
      await deployContract(
        this.signers.deployer,
        sushiBarAdapterArtifact,
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

  describe("SushiBarAdapter", function () {
    Object.keys(SushiBarPools).map((token: string) => {
      shouldBehaveLikeSushiBarAdapter(token, (SushiBarPools as LiquidityPool)[token]);
    });
  });
});
