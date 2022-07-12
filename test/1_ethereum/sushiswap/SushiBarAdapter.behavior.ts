import hre, { ethers } from "hardhat";
import chai, { expect } from "chai";
import { solidity } from "ethereum-waffle";
import { getAddress } from "ethers/lib/utils";
import { PoolItem } from "../types";
import { getOverrideOptions, setTokenBalanceInStorage } from "../../utils";

chai.use(solidity);

export function shouldBehaveLikeSushiBarAdapter(token: string, pool: PoolItem): void {
  it(`should stake ${token} and unstake x${token} in ${token} bar contract of Sushiswap`, async function () {
    if (pool.deprecated === true) {
      this.skip();
    }
    // underlying token instance
    const underlyingTokenInstance = await hre.ethers.getContractAt("ERC20", pool.tokens[0]);
    // sushi bar instance
    const sushiBarInstance = await hre.ethers.getContractAt("ISushiBar", pool.pool);
    await setTokenBalanceInStorage(underlyingTokenInstance, this.testDeFiAdapter.address, "200");
    // 1. deposit all underlying tokens
    await this.testDeFiAdapter.testGetDepositAllCodes(
      pool.tokens[0],
      pool.pool,
      this.sushiBarAdapter.address,
      getOverrideOptions(),
    );
    // 2. assert whether lptoken balance is as expected or not after deposit
    const actualLPTokenBalanceAfterDeposit = await this.sushiBarAdapter.getLiquidityPoolTokenBalance(
      this.testDeFiAdapter.address,
      this.testDeFiAdapter.address, // placeholder of type address
      pool.pool,
    );
    const expectedLPTokenBalanceAfterDeposit = await sushiBarInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualLPTokenBalanceAfterDeposit).to.be.eq(expectedLPTokenBalanceAfterDeposit);
    // 3. assert whether underlying token balance is as expected or not after deposit
    const actualUnderlyingTokenBalanceAfterDeposit = await this.testDeFiAdapter.getERC20TokenBalance(
      (
        await this.sushiBarAdapter.getUnderlyingTokens(pool.pool, pool.pool)
      )[0],
      this.testDeFiAdapter.address,
    );
    const expectedUnderlyingTokenBalanceAfterDeposit = await underlyingTokenInstance.balanceOf(
      this.testDeFiAdapter.address,
    );
    expect(actualUnderlyingTokenBalanceAfterDeposit).to.be.eq(expectedUnderlyingTokenBalanceAfterDeposit);
    // 4. assert whether the amount in token is as expected or not after depositing
    const actualAmountInTokenAfterDeposit = await this.sushiBarAdapter.getAllAmountInToken(
      this.testDeFiAdapter.address,
      pool.tokens[0],
      pool.pool,
    );
    const xSushiBalance = await sushiBarInstance.balanceOf(this.testDeFiAdapter.address);
    const xSushiTotalSupply = await sushiBarInstance.totalSupply();
    const totalSushiInSushiBar = await underlyingTokenInstance.balanceOf(pool.pool);
    const expectedAmountInTokenAfterDeposit = xSushiBalance.mul(totalSushiInSushiBar).div(xSushiTotalSupply);
    expect(actualAmountInTokenAfterDeposit).to.be.eq(expectedAmountInTokenAfterDeposit);
    // 5. assert whether the reward token is as expected or not
    const actualRewardToken = await this.sushiBarAdapter.getRewardToken(pool.pool);
    const expectedRewardToken = ethers.constants.AddressZero;
    expect(getAddress(actualRewardToken)).to.be.eq(getAddress(expectedRewardToken));
    // 6. Withdraw all lpToken balance
    await this.testDeFiAdapter.testGetWithdrawAllCodes(
      pool.tokens[0],
      pool.pool,
      this.sushiBarAdapter.address,
      getOverrideOptions(),
    );
    // 7. assert whether staked balance is as expected or not
    const actualLPTokenBalanceAfterWithdraw = await this.sushiBarAdapter.getLiquidityPoolTokenBalance(
      this.testDeFiAdapter.address,
      this.testDeFiAdapter.address, // placeholder of type address
      pool.pool,
    );
    const expectedLPTokenBalanceAfterWithdraw = await sushiBarInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualLPTokenBalanceAfterWithdraw).to.be.eq(expectedLPTokenBalanceAfterWithdraw);
    // 8. assert whether underlying token balance is as expected or not after withdraw
    const actualUnderlyingTokenBalanceAfterWithdraw = await this.testDeFiAdapter.getERC20TokenBalance(
      (
        await this.sushiBarAdapter.getUnderlyingTokens(pool.pool, pool.pool)
      )[0],
      this.testDeFiAdapter.address,
    );
    const expectedUnderlyingTokenBalanceAfterWithdraw = await underlyingTokenInstance.balanceOf(
      this.testDeFiAdapter.address,
    );
    expect(actualUnderlyingTokenBalanceAfterWithdraw).to.be.eq(expectedUnderlyingTokenBalanceAfterWithdraw);
    // 9. assert whether underlying token balance after withdraw is greater than underlying token balance before deposit
    expect(actualUnderlyingTokenBalanceAfterWithdraw).to.be.gt(actualUnderlyingTokenBalanceAfterDeposit);
  }).timeout(100000);
}
