// SPDX-License-Identifier:MIT

pragma solidity =0.8.11;
pragma experimental ABIEncoderV2;

// helper contracts
import { AdapterModifiersBase } from "../../utils/AdapterModifiersBase.sol";

// interfaces
import { IERC20 } from "@openzeppelin/contracts-0.8.x/token/ERC20/IERC20.sol";
import { IAdapter } from "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapter.sol";
import "@optyfi/defi-legos/interfaces/defiAdapters/contracts/IAdapterInvestLimit.sol";
import { ISushiBar } from "./interfaces/ISushiBar.sol";

/**
 * @title Adapter for Sushiswap protocol
 * @author Opty.fi
 * @dev Abstraction layer to Sushiswap's SushiBar contract
 */

contract SushiBarAdapter is IAdapter, IAdapterInvestLimit, AdapterModifiersBase {
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
        address _sushiBar,
        address _underlyingToken,
        uint256 _maxDepositAmount
    ) external override onlyRiskOperator {
        maxDepositAmount[_sushiBar][_underlyingToken] = _maxDepositAmount;
        emit LogMaxDepositAmount(maxDepositAmount[_sushiBar][_underlyingToken], msg.sender);
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
        address _sushiBar
    ) external view override returns (bytes[] memory) {
        uint256 _amount = IERC20(_underlyingToken).balanceOf(_vault);
        return getDepositSomeCodes(_vault, _underlyingToken, _sushiBar, _amount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawAllCodes(
        address payable _vault,
        address _underlyingToken,
        address _sushiBar
    ) external view override returns (bytes[] memory) {
        uint256 _redeemAmount = getLiquidityPoolTokenBalance(_vault, _underlyingToken, _sushiBar);
        return getWithdrawSomeCodes(_vault, _underlyingToken, _sushiBar, _redeemAmount);
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateRedeemableLPTokenAmount(
        address payable _vault,
        address _underlyingToken,
        address _sushiBar,
        uint256 _redeemAmount
    ) external view override returns (uint256) {
        uint256 _liquidityPoolTokenBalance = getLiquidityPoolTokenBalance(_vault, _underlyingToken, _sushiBar);
        uint256 _balanceInToken = getAllAmountInToken(_vault, _underlyingToken, _sushiBar);
        return (_liquidityPoolTokenBalance * _redeemAmount) / _balanceInToken;
    }

    /**
     * @inheritdoc IAdapter
     */
    function isRedeemableAmountSufficient(
        address payable _vault,
        address _underlyingToken,
        address _sushiBar,
        uint256 _redeemAmount
    ) external view override returns (bool) {
        uint256 _balanceInToken = getAllAmountInToken(_vault, _underlyingToken, _sushiBar);
        return _balanceInToken >= _redeemAmount;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getUnderlyingTokens(address _sushiBar, address)
        external
        view
        override
        returns (address[] memory _underlyingTokens)
    {
        _underlyingTokens = new address[](1);
        _underlyingTokens[0] = ISushiBar(_sushiBar).sushi();
    }

    /**
     * @inheritdoc IAdapter
     */
    function calculateAmountInLPToken(
        address _underlyingToken,
        address _sushiBar,
        uint256 _depositAmount
    ) external view override returns (uint256) {
        return (_depositAmount * IERC20(_sushiBar).totalSupply()) / IERC20(_underlyingToken).balanceOf(_sushiBar);
    }

    /**
     * @inheritdoc IAdapter
     */
    function canStake(address) external pure override returns (bool) {
        return false;
    }

    /**
     * @inheritdoc IAdapter
     */
    function getDepositSomeCodes(
        address payable, // solhint-disable-line no-unused-vars
        address _underlyingToken,
        address _sushiBar,
        uint256 _amount
    ) public view override returns (bytes[] memory _codes) {
        uint256 _depositAmount = _getDepositAmount(_sushiBar, _underlyingToken, _amount);
        if (_depositAmount > 0) {
            _codes = new bytes[](3);
            _codes[0] = abi.encode(
                _underlyingToken,
                abi.encodeWithSignature("approve(address,uint256)", _sushiBar, uint256(0))
            );
            _codes[1] = abi.encode(
                _underlyingToken,
                abi.encodeWithSignature("approve(address,uint256)", _sushiBar, _depositAmount)
            );
            _codes[2] = abi.encode(_sushiBar, abi.encodeWithSignature("enter(uint256)", _depositAmount));
        }
    }

    /**
     * @inheritdoc IAdapter
     */
    function getPoolValue(address _sushiBar, address _underlyingToken) public view override returns (uint256) {
        return IERC20(_underlyingToken).balanceOf(_sushiBar);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getAllAmountInToken(
        address payable _vault,
        address _underlyingToken,
        address _sushiBar
    ) public view override returns (uint256) {
        return
            getSomeAmountInToken(
                _underlyingToken,
                _sushiBar,
                getLiquidityPoolTokenBalance(_vault, _underlyingToken, _sushiBar)
            );
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolTokenBalance(
        address payable _vault,
        address,
        address _sushiBar
    ) public view override returns (uint256) {
        return IERC20(_sushiBar).balanceOf(_vault);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getSomeAmountInToken(
        address _underlyingToken,
        address _sushiBar,
        uint256 _amount
    ) public view override returns (uint256) {
        return (_amount * IERC20(_underlyingToken).balanceOf(_sushiBar)) / ISushiBar(_sushiBar).totalSupply();
    }

    /**
     * @inheritdoc IAdapter
     */
    function getRewardToken(address) public pure override returns (address) {
        return address(0);
    }

    /**
     * @inheritdoc IAdapter
     */
    function getWithdrawSomeCodes(
        address payable, // solhint-disable-line no-unused-vars
        address,
        address _sushiBar,
        uint256 _amount
    ) public pure override returns (bytes[] memory _codes) {
        _codes = new bytes[](1);
        _codes[0] = abi.encode(_sushiBar, abi.encodeWithSignature("leave(uint256)", _amount));
    }

    /**
     * @inheritdoc IAdapter
     */
    function getLiquidityPoolToken(address, address _sushiBar) public pure override returns (address) {
        return _sushiBar;
    }

    function _getDepositAmount(
        address _sushiBar,
        address _underlyingToken,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 _limit = maxDepositProtocolMode == MaxExposure.Pct
            ? _getMaxDepositAmountByPct(_sushiBar, _underlyingToken)
            : maxDepositAmount[_sushiBar][_underlyingToken];
        return _amount > _limit ? _limit : _amount;
    }

    function _getMaxDepositAmountByPct(address _sushiBar, address _underlyingToken) internal view returns (uint256) {
        uint256 _poolValue = getPoolValue(_sushiBar, _underlyingToken);
        uint256 _poolPct = maxDepositPoolPct[_underlyingToken];
        uint256 _limit = _poolPct == 0
            ? (_poolValue * maxDepositProtocolPct) / uint256(10000)
            : (_poolValue * _poolPct) / uint256(10000);
        return _limit;
    }
}
