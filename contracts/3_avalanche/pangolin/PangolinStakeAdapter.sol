// SPDX-License-Identifier:MIT

pragma solidity =0.8.11;
pragma experimental ABIEncoderV2;

// libraries
import { Address } from "@openzeppelin/contracts-0.8.x/utils/Address.sol";

// helper contracts
import { AdapterModifiersBase } from "../../utils/AdapterModifiersBase.sol";

// interfaces
import { IERC20 } from "@openzeppelin/contracts-0.8.x/token/ERC20/IERC20.sol";
import { IAdapter } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapter.sol";
import { IAdapterHarvestReward } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterHarvestReward.sol";
import "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterInvestLimit.sol";
import { IPangolinStake } from "./interfaces/IPangolinStake.sol";

/**
 * @title Adapter for TraderJoe protocol
 * @author Opty.fi
 * @dev Abstraction layer to TraderJoe's MasterChef contract
 */

contract PangolinStakeAdapter is IAdapter, IAdapterInvestLimit, IAdapterHarvestReward, AdapterModifiersBase {
    using Address for address;

    /** @notice max deposit value datatypes */
    MaxExposure public maxDepositProtocolMode;

    /** @notice max deposit's protocol value in percentage */
    uint256 public maxDepositProtocolPct; // basis points

    /** @notice Maps liquidityPool to max deposit value in percentage */
    mapping(address => uint256) public maxDepositPoolPct; // basis points

    /** @notice Maps liquidityPool to max deposit value in absolute value for a specific token */
    mapping(address => mapping(address => uint256)) public maxDepositAmount;

    constructor(address _registry) AdapterModifiersBase(_registry) {
        maxDepositProtocolPct = 10000;
        maxDepositProtocolMode = MaxExposure.Pct;
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositPoolPct(address _underlyingToken, uint256 _maxDepositPoolPct)
        external
        override
        onlyRiskOperator
    {
        maxDepositPoolPct[_underlyingToken] = _maxDepositPoolPct;
        emit LogMaxDepositPoolPct(maxDepositPoolPct[_underlyingToken], msg.sender);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositAmount(
        address _stakingPool,
        address _underlyingToken,
        uint256 _maxDepositAmount
    ) external override onlyRiskOperator {
        maxDepositAmount[_stakingPool][_underlyingToken] = _maxDepositAmount;
        emit LogMaxDepositAmount(maxDepositAmount[_stakingPool][_underlyingToken], msg.sender);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositProtocolMode(MaxExposure _mode) external override onlyRiskOperator {
        maxDepositProtocolMode = _mode;
        emit LogMaxDepositProtocolMode(maxDepositProtocolMode, msg.sender);
    }

    /**
     * @inheritdoc IAdapterInvestLimit
     */
    function setMaxDepositProtocolPct(uint256 _maxDepositProtocolPct) external override onlyRiskOperator {
        maxDepositProtocolPct = _maxDepositProtocolPct;
        emit LogMaxDepositProtocolPct(maxDepositProtocolPct, msg.sender);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getDepositAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _stakingPool
    ) external view override returns (bytes[] memory) {
        uint256 _amount = IERC20(_underlyingToken).balanceOf(_vault);
        return getDepositSomeCodes(_vault, _underlyingToken, _stakingPool, _amount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _stakingPool
    ) external view override returns (bytes[] memory) {
        uint256 _redeemAmount = getLiquidityPoolTokenBalance(_vault, _underlyingToken, _stakingPool);
        return getWithdrawSomeCodes(_vault, _underlyingToken, _stakingPool, _redeemAmount);
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getUnclaimedRewardTokenAmount(
        address payable _vault,
        address _stakingPool,
        address
    ) external view override returns (uint256) {
        return IPangolinStake(_stakingPool).earned(_vault);
    }

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getClaimRewardTokenCode(address payable _vault, address _stakingPool)
        external
        view
        override
        returns (bytes[] memory _codes)
    {
        uint256 unclaimedRewards = IPangolinStake(_stakingPool).earned(_vault);
        if (unclaimedRewards > uint256(0)) {
            _codes = new bytes[](1);
            _codes[0] = abi.encode(_stakingPool, abi.encodeWithSignature("getReward()"));
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateRedeemableLPTokenAmount(
        address payable _vault,
        address _underlyingToken,
        address _stakingPool,
        uint256
    ) external view override returns (uint256) {
        return getAllAmountInToken(_vault, _underlyingToken, _stakingPool);
    }

    /**
     * @inheritdoc IAdapter
     */
    function isRedeemableAmountSufficient(
        address payable _vault,
        address _underlyingToken,
        address _stakingPool,
        uint256 _redeemAmount
    ) external view override returns (bool) {
        uint256 _balanceInToken = getAllAmountInToken(_vault, _underlyingToken, _stakingPool);
        return _balanceInToken >= _redeemAmount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getUnderlyingTokens(address _liquidityPool, address)
        external
        view
        override
        returns (address[] memory _underlyingTokens)
    {
        _underlyingTokens = new address[](1);
        _underlyingTokens[0] = IPangolinStake(_liquidityPool).stakingToken();
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateAmountInLPToken(
        address,
        address,
        uint256 _depositAmount
    ) external pure override returns (uint256) {
        return _depositAmount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function canStake(address) external pure override returns (bool) {
        return false;
    }

    // solhint-disable no-empty-blocks

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getHarvestAllCodes(
        address payable,
        address,
        address
    ) external pure returns (bytes[] memory) {}

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getHarvestSomeCodes(
        address payable,
        address,
        address,
        uint256
    ) external pure override returns (bytes[] memory) {}

    /**
     * @inheritdoc IAdapterHarvestReward
     */
    function getAddLiquidityCodes(address payable, address) external pure override returns (bytes[] memory) {}

    // solhint-enable no-empty-blocks

    /**
     * @inheritdoc IAdapter
     */
    function getDepositSomeCodes(
        address payable, // solhint-disable-line no-unused-vars
        address _underlyingToken,
        address _stakingPool,
        uint256 _amount
    ) public view override returns (bytes[] memory _codes) {
        uint256 _depositAmount = _getDepositAmount(_stakingPool, _underlyingToken, _amount);
        if (_depositAmount > 0) {
            _codes = new bytes[](3);
            _codes[0] = abi.encode(
                _underlyingToken,
                abi.encodeWithSignature("approve(address,uint256)", _stakingPool, uint256(0))
            );
            _codes[1] = abi.encode(
                _underlyingToken,
                abi.encodeWithSignature("approve(address,uint256)", _stakingPool, _depositAmount)
            );
            _codes[2] = abi.encode(_stakingPool, abi.encodeWithSignature("stake(uint256)", _depositAmount));
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getPoolValue(address _stakingPool, address) public view override returns (uint256) {
        return IERC20(_stakingPool).totalSupply();
    }

    /**
     * @inheritdoc IAdapter
     */
    function getAllAmountInToken(
        address payable _vault,
        address,
        address _stakingPool
    ) public view override returns (uint256 _balance) {
        _balance = IERC20(_stakingPool).balanceOf(_vault);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolTokenBalance(
        address payable _vault,
        address,
        address _stakingPool
    ) public view override returns (uint256) {
        return IERC20(_stakingPool).balanceOf(_vault);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getRewardToken(address _liquidityPool) public view override returns (address) {
        return IPangolinStake(_liquidityPool).rewardsToken();
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawSomeCodes(
        address payable, // solhint-disable-line no-unused-vars
        address,
        address _stakingPool,
        uint256 _amount
    ) public pure override returns (bytes[] memory _codes) {
        _codes = new bytes[](1);
        _codes[0] = abi.encode(_stakingPool, abi.encodeWithSignature("withdraw(uint256)", _amount));
    }

    /**
     * @inheritdoc IAdapter
     */
    function getSomeAmountInToken(
        address,
        address,
        uint256 _amount
    ) public pure override returns (uint256) {
        return _amount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolToken(address, address _liquidityPool) public pure override returns (address) {
        return _liquidityPool;
    }

    function _getDepositAmount(
        address _stakingPool,
        address _underlyingToken,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 _limit = maxDepositProtocolMode == MaxExposure.Pct
            ? _getMaxDepositAmountByPct(_stakingPool, _underlyingToken)
            : maxDepositAmount[_stakingPool][_underlyingToken];
        return _amount > _limit ? _limit : _amount;
    }

    function _getMaxDepositAmountByPct(address _stakingPool, address _underlyingToken) internal view returns (uint256) {
        uint256 _poolValue = getPoolValue(_stakingPool, _underlyingToken);
        uint256 _poolPct = maxDepositPoolPct[_underlyingToken];
        uint256 _limit = _poolPct == 0
            ? (_poolValue * maxDepositProtocolPct) / uint256(10000)
            : (_poolValue * _poolPct) / uint256(10000);
        return _limit;
    }
}
