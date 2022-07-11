import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { Fixture } from "ethereum-waffle";
import { PangolinStakeAdapter } from "../typechain/PangolinStakeAdapter";
import { IUniswapV2Router02 } from "../typechain/IUniswapV2Router02";
import { TestDeFiAdapter } from "../typechain/TestDeFiAdapter";

export interface Signers {
  admin: SignerWithAddress;
  owner: SignerWithAddress;
  deployer: SignerWithAddress;
  alice: SignerWithAddress;
  bob: SignerWithAddress;
  charlie: SignerWithAddress;
  dave: SignerWithAddress;
  eve: SignerWithAddress;
  operator: SignerWithAddress;
}

export interface PoolItem {
  pool: string;
  lpToken: string;
  rewardTokens?: string[];
  tokens: string[];
  deprecated?: boolean;
}

export interface LiquidityPool {
  [name: string]: PoolItem;
}

declare module "mocha" {
  export interface Context {
    pangolinStakeAdapter: PangolinStakeAdapter;
    testDeFiAdapter: TestDeFiAdapter;
    uniswapV2Router02: IUniswapV2Router02;
    loadFixture: <T>(fixture: Fixture<T>) => Promise<T>;
    signers: Signers;
  }
}
