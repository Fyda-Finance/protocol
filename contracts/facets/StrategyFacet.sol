// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AppStorage, Strategy, StrategyParameters, SellLegType, BuyLegType, FloorLegType, DCA_UNIT, DIP_SPIKE, TimeUnit, Status, CURRENT_PRICE} from "../AppStorage.sol";
import {Modifiers} from "../utils/Modifiers.sol";
import {InvalidSlippage, InvalidInvestToken, InvalidStableToken, TokensMustDiffer, AtLeastOneOptionRequired, InvalidBuyValue, InvalidBuyType, InvalidFloorValue, InvalidFloorType, InvalidSellType, InvalidSellValue, InvalidStableAmount, BuyAndSellAtMisorder, InvalidInvestAmount, FloorValueGreaterThanBuyValue, FloorValueGreaterThanSellValue, SellPercentageWithDCA, FloorPercentageWithDCA, BothBuyTwapAndBTD, BuyDCAWithoutBuy, BuyTwapTimeInvalid, BuyTwapTimeUnitNotSelected, BothSellTwapAndSTR, SellDCAWithoutSell, SellTwapTimeUnitNotSelected, SellTwapTimeInvalid, SellTwapOrStrWithoutSellDCAUnit, SellDCAUnitWithoutSellDCAValue, StrWithoutStrValueOrType, BTDWithoutBTDType, BTDTypeWithoutBTDValue, BuyDCAWithoutBuyDCAUnit, BuyDCAUnitWithoutBuyDCAValue, InvalidHighSellValue, SellDCAValueRangeIsNotValid, BuyDCAValueRangeIsNotValid, DCAValueShouldBeLessThanIntitialAmount, OrphandStrategy, BuyNeverExecute} from "../utils/GenericErrors.sol";
import {LibPrice} from "../libraries/LibPrice.sol";
import {LibTrade} from "../libraries/LibTrade.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

error BothStableAndInvestAmountProvided();
error OnlyOwnerCanCancelStrategies();
error NoAmountProvided();
error HighSellValueIsChosenWithoutSeLLDCA();

/**
 * @title StrategyFacet
 * @notice This contract handles the creation, retrieval, and cancellation of strategies.
 * Strategies define specific trade execution conditions and actions.
 * @dev StrategyFacet is one of the facets of the system, dedicated to strategy management.
 */
contract StrategyFacet is Modifiers {
    /**
     * @notice The `AppStorage` state variable serves as the central data repository for this contract. Please
     * please look at AppStorage.sol for more detail
     */
    AppStorage internal s;

    /**
     * @notice Emitted when a new trading strategy is created.
     * @param investToken The address of the invest token used in the strategy.
     * @param stableToken The address of the stable token used in the strategy.
     * @param parameter The strategy parameter including settings for buying and selling.
     * @param timestamp Timestamp when the strategy is created.
     * @param investRoundId Round ID for the invest token price when the strategy is created.
     * @param stableRoundId Round ID for the stable token price when the strategy is created.
     * @param price The price of the invest token at the time of strategy creation.
     */

    event StrategyCreated(
        address indexed investToken,
        address indexed stableToken,
        StrategyParameters parameter,
        uint256 timestamp,
        uint256 investRoundId,
        uint256 stableRoundId,
        uint256 price
    );

    /**
     * @notice Emitted when a trade execution strategy is cancelled.
     * @param strategyId The unique ID of the cancelled strategy.
     */
    event StrategyCancelled(uint256 indexed strategyId);

    /**
     * @notice Create a new trade execution strategy based on the provided parameters.
     * @dev This function validates the input parameters to ensure they satisfy the criteria for creating a strategy.
     *      If the parameters are valid, a new strategy is created and an event is emitted to indicate the successful creation.
     *      If the parameters do not meet the criteria, an error is thrown.
     * @param _parameter The strategy parameters defining the behavior and conditions of the strategy.
     */
    function createStrategy(StrategyParameters memory _parameter) external {
        if (_parameter._investToken == address(0)) {
            revert InvalidInvestToken();
        }

        if (_parameter._stableToken == address(0)) {
            revert InvalidStableToken();
        }

        if (_parameter._investToken == _parameter._stableToken) {
            revert TokensMustDiffer();
        }

        if (!(_parameter._floor || _parameter._sell || _parameter._buy)) {
            revert AtLeastOneOptionRequired();
        }

        if (
            _parameter._sellType == SellLegType.INCREASE_BY &&
            (_parameter._str || _parameter._sellTwap)
        ) {
            revert SellPercentageWithDCA();
        }

        if (
            _parameter._floorType == FloorLegType.DECREASE_BY &&
            (_parameter._buyTwap || _parameter._btd)
        ) {
            revert FloorPercentageWithDCA();
        }

        if (_parameter._buy && _parameter._buyTwap && _parameter._btd) {
            revert BothBuyTwapAndBTD();
        }

        if ((_parameter._buyTwap || _parameter._btd) && !_parameter._buy) {
            revert BuyDCAWithoutBuy();
        }

        if (_parameter._buyTwap && _parameter._buyTwapTime <= 0) {
            revert BuyTwapTimeInvalid();
        }
        if (
            _parameter._buyTwap &&
            _parameter._buyTwapTimeUnit == TimeUnit.NO_UNIT
        ) {
            revert BuyTwapTimeUnitNotSelected();
        }

        if (_parameter._sellTwap && _parameter._str) {
            revert BothSellTwapAndSTR();
        }

        if ((_parameter._sellTwap || _parameter._str) && !_parameter._sell) {
            revert SellDCAWithoutSell();
        }
        if (
            _parameter._sellTwap &&
            _parameter._sellTwapTimeUnit == TimeUnit.NO_UNIT
        ) {
            revert SellTwapTimeUnitNotSelected();
        }

        if (_parameter._sellTwap && _parameter._sellTwapTime <= 0) {
            revert SellTwapTimeInvalid();
        }

        if (
            (_parameter._sellTwap || _parameter._str) &&
            _parameter._sellDCAUnit == DCA_UNIT.NO_UNIT
        ) {
            revert SellTwapOrStrWithoutSellDCAUnit();
        }

        if (
            _parameter._sellDCAUnit != DCA_UNIT.NO_UNIT &&
            _parameter._sellDCAValue == 0
        ) {
            revert SellDCAUnitWithoutSellDCAValue();
        }

        if (
            _parameter._str &&
            (_parameter._strValue == 0 ||
                _parameter._strType == DIP_SPIKE.NO_SPIKE)
        ) {
            revert StrWithoutStrValueOrType();
        }

        if (_parameter._btd && _parameter._btdType == DIP_SPIKE.NO_SPIKE) {
            revert BTDWithoutBTDType();
        }

        if (
            _parameter._btdType != DIP_SPIKE.NO_SPIKE &&
            _parameter._btdValue == 0
        ) {
            revert BTDTypeWithoutBTDValue();
        }

        if (
            (_parameter._btd || _parameter._buyTwap) &&
            _parameter._buyDCAUnit == DCA_UNIT.NO_UNIT
        ) {
            revert BuyDCAWithoutBuyDCAUnit();
        }

        if (
            _parameter._buyDCAUnit != DCA_UNIT.NO_UNIT &&
            _parameter._buyDCAValue == 0
        ) {
            revert BuyDCAUnitWithoutBuyDCAValue();
        }

        (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice
            .getPrice(_parameter._investToken, _parameter._stableToken);

        uint256 buyValue = _parameter._buyValue;
        if (_parameter._current_price == CURRENT_PRICE.BUY_CURRENT) {
            buyValue = price;
            _parameter._buyType = BuyLegType.LIMIT_PRICE;
            if (_parameter._btd) {
                _parameter._buyValue = price;
                _parameter._current_price = CURRENT_PRICE.EXECUTED;
            }
        }
        uint256 sellValue = _parameter._sellValue;
        if (_parameter._current_price == CURRENT_PRICE.SELL_CURRENT) {
            sellValue = price;
            _parameter._sellType = SellLegType.LIMIT_PRICE;
            if (_parameter._str) {
                _parameter._sellValue = price;
                _parameter._current_price = CURRENT_PRICE.EXECUTED;
            }
        }

        if (_parameter._buy) {
            if (buyValue == 0) {
                revert InvalidBuyValue();
            }
            if (_parameter._buyType == BuyLegType.NO_TYPE) {
                revert InvalidBuyType();
            }
        }

        // Check if floor is chosen
        if (_parameter._floor) {
            if (_parameter._floorValue == 0) {
                revert InvalidFloorValue();
            }
            if (_parameter._floorType == FloorLegType.NO_TYPE) {
                revert InvalidFloorType();
            }
        }

        if (_parameter._highSellValue != 0) {
            if (!(_parameter._str || _parameter._sellTwap)) {
                revert HighSellValueIsChosenWithoutSeLLDCA();
            }
        }

        if (_parameter._sell || _parameter._str || _parameter._sellTwap) {
            if (_parameter._sellType == SellLegType.NO_TYPE) {
                revert InvalidSellType();
            }
            if (sellValue == 0) {
                revert InvalidSellValue();
            }
            if (
                _parameter._highSellValue != 0 &&
                sellValue > _parameter._highSellValue
            ) {
                revert InvalidHighSellValue();
            }
        }

        // Check if both buy and sell are chosen
        if (_parameter._buy && _parameter._sell) {
            if (
                !(_parameter._stableAmount > 0 || _parameter._investAmount > 0)
            ) {
                revert NoAmountProvided();
            }
            if (
                buyValue >= sellValue &&
                _parameter._sellType == SellLegType.LIMIT_PRICE
            ) {
                revert BuyAndSellAtMisorder();
            }
        }
        // Check if only buy is chosen
        if (_parameter._buy && !_parameter._sell && !_parameter._floor) {
            if (!(_parameter._stableAmount > 0)) {
                revert InvalidStableAmount();
            }
        }

        if (_parameter._buy && !_parameter._sell && !_parameter._floor) {
            if (_parameter._investAmount > 0) {
                revert OrphandStrategy();
            }
        }
        if (!_parameter._buy && _parameter._sell && _parameter._floor) {
            if (_parameter._stableAmount > 0) {
                revert OrphandStrategy();
            }
        }

        // Check if only sell is chosen
        if (
            (_parameter._sell || _parameter._floor) &&
            _parameter._investAmount > 0 &&
            (_parameter._completeOnSell || _parameter._cancelOnFloor) &&
            _parameter._buy
        ) {
            revert BuyNeverExecute();
        }

        // Check if floor and sell are chosen
        if (
            _parameter._floor &&
            _parameter._sell &&
            _parameter._sellType == SellLegType.LIMIT_PRICE &&
            _parameter._floorType == FloorLegType.LIMIT_PRICE
        ) {
            if (_parameter._floorValue >= sellValue) {
                revert FloorValueGreaterThanSellValue();
            }
        }

        // Check if floor and buy are chosen
        if (
            _parameter._floor &&
            _parameter._buy &&
            _parameter._floorType == FloorLegType.LIMIT_PRICE
        ) {
            if (_parameter._floorValue >= buyValue) {
                revert FloorValueGreaterThanBuyValue();
            }
        }

        if (_parameter._slippage > LibTrade.MAX_PERCENTAGE) {
            revert InvalidSlippage();
        }

        if (
            (_parameter._sellTwap || _parameter._str) &&
            _parameter._sellDCAUnit == DCA_UNIT.PERCENTAGE
        ) {
            if (
                _parameter._sellDCAValue < 0 ||
                _parameter._sellDCAValue > LibTrade.MAX_PERCENTAGE
            ) {
                revert SellDCAValueRangeIsNotValid();
            }
        }

        if (
            ((_parameter._sellTwap || _parameter._str) &&
                _parameter._sellDCAUnit == DCA_UNIT.FIXED) &&
            _parameter._investAmount > 0 &&
            (_parameter._sellDCAValue > _parameter._investAmount)
        ) {
            revert DCAValueShouldBeLessThanIntitialAmount();
        }

        if (
            (_parameter._buyTwap || _parameter._btd) &&
            (_parameter._buyDCAUnit == DCA_UNIT.FIXED) &&
            _parameter._stableAmount > 0 &&
            (_parameter._buyDCAValue > _parameter._stableAmount)
        ) {
            revert DCAValueShouldBeLessThanIntitialAmount();
        }

        if (
            (_parameter._buyTwap || _parameter._btd) &&
            _parameter._buyDCAUnit == DCA_UNIT.PERCENTAGE
        ) {
            if (
                _parameter._buyDCAValue < 0 ||
                _parameter._buyDCAValue > LibTrade.MAX_PERCENTAGE
            ) {
                revert BuyDCAValueRangeIsNotValid();
            }
        }

        uint256 decimals = 10 **
            IERC20Metadata(_parameter._investToken).decimals();

        if (_parameter._investAmount > 0 && _parameter._stableAmount > 0) {
            revert BothStableAndInvestAmountProvided();
        }
        uint256 budget = 0;

        if (_parameter._investAmount > 0) {
            budget = ((_parameter._investAmount * price) / decimals);
        }

        if (_parameter._stableAmount > 0) {
            budget = _parameter._stableAmount;
        }
        uint256 investPrice = 0;
        if (_parameter._investAmount > 0) {
            investPrice = price;
        }
        s.strategies[s.nextStrategyId] = Strategy({
            user: msg.sender,
            sellTwapExecutedAt: 0,
            buyTwapExecutedAt: 0,
            investRoundId: investRoundId,
            stableRoundId: stableRoundId,
            parameters: _parameter,
            investPrice: investPrice,
            profit: 0,
            budget: budget,
            status: Status.ACTIVE
        });

        s.nextStrategyId++;

        emit StrategyCreated(
            _parameter._investToken,
            _parameter._stableToken,
            _parameter,
            block.timestamp,
            investRoundId,
            stableRoundId,
            price
        );
    }

    /**
     * @notice Cancel a trade execution strategy.
     * @dev This function allows users to cancel a trade execution strategy based on its unique ID.
     *      When cancelled, the strategy's status is updated to "CANCELLED."
     * @param id The unique ID of the strategy to cancel.
     */
    function cancelStrategy(uint256 id) external {
        Strategy storage strategy = s.strategies[id];
        if (msg.sender != strategy.user) {
            revert OnlyOwnerCanCancelStrategies();
        }
        strategy.status = Status.CANCELLED;
        emit StrategyCancelled(id);
    }

    /**
     * @notice Get the next available strategy ID.
     * @dev This function returns the unique ID that will be assigned to the next created strategy.
     * @return The next available strategy ID.
     */
    function nextStartegyId() external view returns (uint256) {
        return s.nextStrategyId;
    }

    /**
     * @notice Retrieve the details of a trade execution strategy.
     * @dev This function allows users to query and retrieve information about a trade execution strategy
     *      based on its unique ID.
     * @param id The unique ID of the strategy to retrieve.
     * @return A `Strategy` struct containing details of the specified strategy.
     */
    function getStrategy(uint256 id) external view returns (Strategy memory) {
        return s.strategies[id];
    }
}
