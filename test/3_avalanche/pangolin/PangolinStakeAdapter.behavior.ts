import hre from "hardhat";
import chai, { expect } from "chai";
import { solidity } from "ethereum-waffle";
import { getAddress } from "ethers/lib/utils";
import { utils } from "ethers";
import { PoolItem } from "../types";
import { getOverrideOptions, setTokenBalanceInStorage } from "../../utils";

chai.use(solidity);

const rewardToken = "0x60781C2586D68229fde47564546784ab3fACA982";

export function shouldBehaveLikePangolinStakeAdapter(token: string, pool: PoolItem): void {
  it(`should stake ${token}, claim PNG, harvest PNG and unstake ${token} in ${token} staking pool of Pangolin`, async function () {
    if (pool.deprecated === true) {
      this.skip();
    }
    // underlying token instance
    const underlyingTokenInstance = await hre.ethers.getContractAt("ERC20", pool.tokens[0]);
    // pangolin's staking pool instance
    const pangolinStakingPoolInstance = await hre.ethers.getContractAt("IPangolinStake", pool.pool);
    await setTokenBalanceInStorage(underlyingTokenInstance, this.testDeFiAdapter.address, "200");
    // 1. deposit all underlying tokens
    await this.testDeFiAdapter.testGetDepositAllCodes(
      pool.tokens[0],
      pool.pool,
      this.pangolinStakeAdapter.address,
      getOverrideOptions(),
    );
    // 1.1 assert whether lptoken balance is as expected or not after deposit
    const actualLPTokenBalanceAfterDeposit = await this.pangolinStakeAdapter.getLiquidityPoolTokenBalance(
      this.testDeFiAdapter.address,
      this.testDeFiAdapter.address, // placeholder of type address
      pool.pool,
    );
    const expectedLPTokenBalanceAfterDeposit = await pangolinStakingPoolInstance.balanceOf(
      this.testDeFiAdapter.address,
    );
    expect(actualLPTokenBalanceAfterDeposit).to.be.eq(expectedLPTokenBalanceAfterDeposit);
    // 1.2 assert whether underlying token balance is as expected or not after deposit
    const actualUnderlyingTokenBalanceAfterDeposit = await this.testDeFiAdapter.getERC20TokenBalance(
      (
        await this.pangolinStakeAdapter.getUnderlyingTokens(pool.pool, pool.pool)
      )[0],
      this.testDeFiAdapter.address,
    );
    const expectedUnderlyingTokenBalanceAfterDeposit = await underlyingTokenInstance.balanceOf(
      this.testDeFiAdapter.address,
    );
    expect(actualUnderlyingTokenBalanceAfterDeposit).to.be.eq(expectedUnderlyingTokenBalanceAfterDeposit);
    // 1.3 assert whether the amount in token is as expected or not after depositing
    const actualAmountInTokenAfterDeposit = await this.pangolinStakeAdapter.getAllAmountInToken(
      this.testDeFiAdapter.address,
      pool.tokens[0],
      pool.pool,
    );
    const expectedAmountInTokenAfterDeposit = await pangolinStakingPoolInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualAmountInTokenAfterDeposit).to.be.eq(expectedAmountInTokenAfterDeposit);
    // 2.2 assert whether the reward token is as expected or not
    const actualRewardToken = await this.pangolinStakeAdapter.getRewardToken(pool.pool);
    const expectedRewardToken = rewardToken;
    expect(getAddress(actualRewardToken)).to.be.eq(getAddress(expectedRewardToken));
    // 2.3 make a transaction for mining a block to get finite unclaimed reward amount
    await this.signers.admin.sendTransaction({
      value: utils.parseEther("0"),
      to: await this.signers.admin.getAddress(),
      ...getOverrideOptions(),
    });
    // 2.4 assert whether the unclaimed reward amount is as expected or not after staking
    const actualUnclaimedRewardAfterStake = await this.pangolinStakeAdapter.getUnclaimedRewardTokenAmount(
      this.testDeFiAdapter.address,
      pool.pool,
      pool.tokens[0],
    );
    const expectedUnclaimedRewardAfterStake = await pangolinStakingPoolInstance.earned(this.testDeFiAdapter.address);
    expect(actualUnclaimedRewardAfterStake).to.be.eq(expectedUnclaimedRewardAfterStake);
    // 3. claim the reward token
    await this.testDeFiAdapter.testClaimRewardTokenCode(
      pool.pool,
      this.pangolinStakeAdapter.address,
      getOverrideOptions(),
    );
    // 3.1 assert whether the reward token's balance is as expected or not after claiming
    const actualRewardTokenBalanceAfterClaim = await this.testDeFiAdapter.getERC20TokenBalance(
      await this.pangolinStakeAdapter.getRewardToken(pool.pool),
      this.testDeFiAdapter.address,
    );
    const expectedRewardTokenBalanceAfterClaim = await underlyingTokenInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualRewardTokenBalanceAfterClaim).to.be.eq(expectedRewardTokenBalanceAfterClaim);
    // 6. Withdraw all lpToken balance
    await this.testDeFiAdapter.testGetWithdrawAllCodes(
      pool.tokens[0],
      pool.pool,
      this.pangolinStakeAdapter.address,
      getOverrideOptions(),
    );
    // 6.1 assert whether staked balance is as expected or not
    const actualLPTokenBalanceAfterWithdraw = await this.pangolinStakeAdapter.getLiquidityPoolTokenBalance(
      this.testDeFiAdapter.address,
      this.testDeFiAdapter.address, // placeholder of type address
      pool.pool,
    );
    const expectedLPTokenBalanceAfterWithdraw = await pangolinStakingPoolInstance.balanceOf(
      this.testDeFiAdapter.address,
    );
    expect(actualLPTokenBalanceAfterWithdraw).to.be.eq(expectedLPTokenBalanceAfterWithdraw);
    // 6.2 assert whether underlying token balance is as expected or not after withdraw
    const actualUnderlyingTokenBalanceAfterWithdraw = await this.testDeFiAdapter.getERC20TokenBalance(
      (
        await this.pangolinStakeAdapter.getUnderlyingTokens(pool.pool, pool.pool)
      )[0],
      this.testDeFiAdapter.address,
    );
    const expectedUnderlyingTokenBalanceAfterWithdraw = await underlyingTokenInstance.balanceOf(
      this.testDeFiAdapter.address,
    );
    expect(actualUnderlyingTokenBalanceAfterWithdraw).to.be.eq(expectedUnderlyingTokenBalanceAfterWithdraw);
  }).timeout(100000);
}
