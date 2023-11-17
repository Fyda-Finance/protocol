// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AppStorage, Strategy, StrategyParameters, SellLegType, BuyLegType, FloorLegType, DCA_UNIT, DIP_SPIKE, TimeUnit, Status, CURRENT_PRICE, UpdateStruct } from "../AppStorage.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { InvalidSlippage, InvalidInvestToken, InvalidStableToken, TokensMustDiffer, AlreadyCancelled, AtLeastOneOptionRequired, InvalidBuyValue, InvalidBuyType, InvalidFloorValue, InvalidFloorType, InvalidSellType, InvalidSellValue, InvalidStableAmount, BuyAndSellAtMisorder, InvalidInvestAmount, FloorValueGreaterThanBuyValue, FloorValueGreaterThanSellValue, SellPercentageWithDCA, FloorPercentageWithDCA, BothBuyTwapAndBTD, BuyDCAWithoutBuy, BuyTwapTimeInvalid, BuyTwapTimeUnitNotSelected, BothSellTwapAndSTR, SellDCAWithoutSell, SellTwapTimeUnitNotSelected, SellTwapTimeInvalid, SellTwapOrStrWithoutSellDCAUnit, SellDCAUnitWithoutSellDCAValue, StrWithoutStrValueOrType, BTDWithoutBTDType, BTDTypeWithoutBTDValue, BuyDCAWithoutBuyDCAUnit, BuyDCAUnitWithoutBuyDCAValue, InvalidHighSellValue, SellDCAValueRangeIsNotValid, BuyDCAValueRangeIsNotValid, DCAValueShouldBeLessThanIntitialAmount, OrphandStrategy, BuyNeverExecute, InvalidSigner, InvalidNonce, StrategyIsNotActive, BuyNotSet, SellNotSelected, PercentageNotInRange } from "../utils/GenericErrors.sol";
import { LibPrice } from "../libraries/LibPrice.sol";
import { LibTrade } from "../libraries/LibTrade.sol";
import { LibSignature } from "../libraries/LibSignature.sol";
import { LibUtil } from "../libraries/LibUtil.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

error BothStableAndInvestAmountProvided();
error OnlyOwnerCanCancelStrategies();
error NoAmountProvided();
error HighSellValueIsChosenWithoutSeLLDCA();
error OnlyOwnerCanUpdateStrategies();
error NothingToUpdate();

/**
 * @title StrategyFacet
 * @notice This contract handles the creation, retrieval, and cancellation of strategies.
 * Strategies define specific trade execution conditions and actions.
 * @dev StrategyFacet is one of the facets of the system, dedicated to strategy management.
 */
contract StrategyFacet is Modifiers {
    /**
     * @notice The `Permit` struct is used to hold the parameters for the permit function.
     * @param token The address of the token to spend.
     * @param owner The address of the owner of the token.
     * @param spender The address of the spender of the token.
     * @param value The amount of the token to spend.
     * @param deadline The deadline for the permit.
     * @param v The v parameter of the permit signature.
     * @param r The r parameter of the permit signature.
     * @param s The s parameter of the permit signature.
     */
    struct Permit {
        address token;
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /**
     * @notice The `AppStorage` state variable serves as the central data repository for this contract. Please
     * please look at AppStorage.sol for more detail
     */
    AppStorage internal s;

    /**
     * @notice Emitted when a new trading strategy is created.
     * @param strategyId The unique ID of the strategy.
     * @param user address of the user whose  for whose strategy is created
     * @param parameter The strategy parameter including settings for buying and selling.
     * @param investRoundId Round ID for the invest token price when the strategy is created.
     * @param stableRoundId Round ID for the stable token price when the strategy is created.
     * @param budget total budget of the user in the stable token
     * @param price price of the invest token w.r.t. the stable when strategy was created
     */

    event StrategyCreated(
        uint256 indexed strategyId,
        address user,
        StrategyParameters parameter,
        uint80 investRoundId,
        uint80 stableRoundId,
        uint256 budget,
        uint256 price
    );

    /**
     * @notice Emitted when a trade execution strategy is cancelled.
     * @param strategyId The unique ID of the cancelled strategy.
     */
    event StrategyCancelled(uint256 indexed strategyId);

    /**
     * @notice Emitted when a strategy is updated.
     * @param strategyId The unique ID of the strategy.
     * @param updateStruct updated parameters of the strategy
     */
    event StrategyUpdated(uint256 indexed strategyId, StrategyParameters updateStruct);

    /**
     * @notice Cancel a trade execution strategy.
     * @dev This function allows users to cancel a trade execution strategy based on its unique ID.
     *      When cancelled, the strategy's status is updated to "CANCELLED."
     * @param id The unique ID of the strategy to cancel.
     */
    function cancelStrategy(uint256 id) external {
        _cancelStrategy(msg.sender, id);
    }

    /**
     * @notice Cancel a trade execution strategy on behalf of another user.
     * @dev This function allows users to cancel a trade execution strategy based on its unique ID.
     *      When cancelled, the strategy's status is updated to "CANCELLED."
     * @param id The unique ID of the strategy to cancel.
     */
    function cancelStrategyOnBehalf(uint256 id, uint256 nonce, bytes memory signature, address account) external {
        bytes32 messageHash = getMessageHashToCancel(id, nonce, account);
        bytes32 ethSignedMessageHash = LibSignature.getEthSignedMessageHash(messageHash);
        address signer = LibSignature.recoverSigner(ethSignedMessageHash, signature);
        s.nonces[account] = s.nonces[account] + 1;

        if (signer != account) {
            revert InvalidSigner();
        }

        _cancelStrategy(account, id);
    }

    /**
     * @notice Cancel a trade execution strategy.
     * @dev This function allows users to cancel a trade execution strategy based on its unique ID.
     *      When cancelled, the strategy's status is updated to "CANCELLED."
     * @param user The address of the user who created the strategy.
     * @param id The unique ID of the strategy to cancel.
     */
    function _cancelStrategy(address user, uint256 id) internal {
        Strategy storage strategy = s.strategies[id];
        if (user != strategy.user) {
            revert OnlyOwnerCanCancelStrategies();
        }

        if (strategy.status == Status.CANCELLED) {
            revert AlreadyCancelled();
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
     * @notice Create a new trade execution strategy based on the provided parameters.
     * @dev This function validates the input parameters to ensure they satisfy the criteria for creating a strategy.
     *      If the parameters are valid, a new strategy is created and an event is emitted to indicate the successful creation.
     *      If the parameters do not meet the criteria, an error is thrown.
     * @param _parameter The strategy parameters defining the behavior and conditions of the strategy.
     */
    function createStrategy(StrategyParameters memory _parameter) public {
        _createStrategy(_parameter, msg.sender);
    }

    /**
     * @notice Create a new trade execution strategy based on the provided parameters on behalf of another user.
     * @dev This function validates the input parameters to ensure they satisfy the criteria for creating a strategy.
     *      If the parameters are valid, a new strategy is created and an event is emitted to indicate the successful creation.
     *      If the parameters do not meet the criteria, an error is thrown.
     * @param permits The array of `Permit` structs containing the parameters for the permit function.
     * @param _parameter The strategy parameters defining the behavior and conditions of the strategy.
     * @param account The address of the user who created the strategy.
     * @param nonce The nonce of the user who created the strategy.
     * @param signature The signature of the user who created the strategy.
     */
    function createStrategyOnBehalf(
        Permit[] memory permits,
        StrategyParameters memory _parameter,
        address account,
        uint256 nonce,
        bytes memory signature
    ) public {
        for (uint256 i = 0; i < permits.length; i++) {
            IERC20Permit(permits[i].token).permit(
                permits[i].owner,
                permits[i].spender,
                permits[i].value,
                permits[i].deadline,
                permits[i].v,
                permits[i].r,
                permits[i].s
            );
        }

        if (s.nonces[account] != nonce) {
            revert InvalidNonce();
        }

        bytes32 messageHash = getMessageHashToCreate(_parameter, nonce, account);
        bytes32 ethSignedMessageHash = LibSignature.getEthSignedMessageHash(messageHash);
        address signer = LibSignature.recoverSigner(ethSignedMessageHash, signature);
        s.nonces[account] = s.nonces[account] + 1;

        if (signer != account) {
            revert InvalidSigner();
        }

        _createStrategy(_parameter, account);
    }

    /**
     * @notice Get the message hash for a given strategy to create it.
     * @dev This function returns the message hash that must be signed by the user in order to create a strategy on behalf of another user.
     * @param _parameter The strategy parameters defining the behavior and conditions of the strategy.
     * @param nonce The nonce of the user who created the strategy.
     * @param account The address of the user who created the strategy.
     * @return The message hash for the given strategy.
     */
    function getMessageHashToCreate(
        StrategyParameters memory _parameter,
        uint256 nonce,
        address account
    ) public view returns (bytes32) {
        return keccak256(abi.encode(account, nonce, _parameter, LibUtil.getChainID()));
    }

    /**
     * @notice Get the message hash for a given strategy to cancel.
     * @dev This function returns the message hash that must be signed by the user in order to cancel a strategy on behalf of another user.
     * @param id The strategy id
     * @param nonce The nonce of the user who created the strategy.
     * @param account The address of the user who created the strategy.
     * @return The message hash for the given strategy.
     */
    function getMessageHashToCancel(uint256 id, uint256 nonce, address account) public view returns (bytes32) {
        return keccak256(abi.encode(account, nonce, id, LibUtil.getChainID()));
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

    /**
     * @notice Create a new trade execution strategy based on the provided parameters.
     * @dev This function validates the input parameters to ensure they satisfy the criteria for creating a strategy.
     *      If the parameters are valid, a new strategy is created and an event is emitted to indicate the successful creation.
     *      If the parameters do not meet the criteria, an error is thrown.
     * @param _parameter The strategy parameters defining the behavior and conditions of the strategy.
     * @param user The address of the user who created the strategy.
     */
    function _createStrategy(StrategyParameters memory _parameter, address user) internal {
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

        if (_parameter._sellType == SellLegType.INCREASE_BY && (_parameter._str || _parameter._sellTwap)) {
            revert SellPercentageWithDCA();
        }

        if (_parameter._floorType == FloorLegType.DECREASE_BY && (_parameter._buyTwap || _parameter._btd)) {
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
        if (_parameter._buyTwap && _parameter._buyTwapTimeUnit == TimeUnit.NO_UNIT) {
            revert BuyTwapTimeUnitNotSelected();
        }

        if (_parameter._sellTwap && _parameter._str) {
            revert BothSellTwapAndSTR();
        }

        if ((_parameter._sellTwap || _parameter._str) && !_parameter._sell) {
            revert SellDCAWithoutSell();
        }
        if (_parameter._sellTwap && _parameter._sellTwapTimeUnit == TimeUnit.NO_UNIT) {
            revert SellTwapTimeUnitNotSelected();
        }

        if (_parameter._sellTwap && _parameter._sellTwapTime <= 0) {
            revert SellTwapTimeInvalid();
        }

        if ((_parameter._sellTwap || _parameter._str) && _parameter._sellDCAUnit == DCA_UNIT.NO_UNIT) {
            revert SellTwapOrStrWithoutSellDCAUnit();
        }

        if (_parameter._sellDCAUnit != DCA_UNIT.NO_UNIT && _parameter._sellDCAValue == 0) {
            revert SellDCAUnitWithoutSellDCAValue();
        }

        if (_parameter._str && (_parameter._strValue == 0 || _parameter._strType == DIP_SPIKE.NO_SPIKE)) {
            revert StrWithoutStrValueOrType();
        }

        if (_parameter._btd && _parameter._btdType == DIP_SPIKE.NO_SPIKE) {
            revert BTDWithoutBTDType();
        }

        if (_parameter._btdType != DIP_SPIKE.NO_SPIKE && _parameter._btdValue == 0) {
            revert BTDTypeWithoutBTDValue();
        }

        if ((_parameter._btd || _parameter._buyTwap) && _parameter._buyDCAUnit == DCA_UNIT.NO_UNIT) {
            revert BuyDCAWithoutBuyDCAUnit();
        }

        if (_parameter._buyDCAUnit != DCA_UNIT.NO_UNIT && _parameter._buyDCAValue == 0) {
            revert BuyDCAUnitWithoutBuyDCAValue();
        }

        (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice.getPrice(
            _parameter._investToken,
            _parameter._stableToken
        );

        if (_parameter._current_price == CURRENT_PRICE.BUY_CURRENT) {
            _parameter._buyType = BuyLegType.LIMIT_PRICE;
            _parameter._buyValue = price;
        }
        if (_parameter._current_price == CURRENT_PRICE.SELL_CURRENT) {
            _parameter._sellType = SellLegType.LIMIT_PRICE;
            _parameter._sellValue = price;
        }

        if (_parameter._buy) {
            if (_parameter._buyValue == 0) {
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
            if (_parameter._sellValue == 0) {
                revert InvalidSellValue();
            }
            if (_parameter._highSellValue != 0 && _parameter._sellValue > _parameter._highSellValue) {
                revert InvalidHighSellValue();
            }
        }

        // Check if both buy and sell are chosen
        if (_parameter._buy && _parameter._sell) {
            if (!(_parameter._stableAmount > 0 || _parameter._investAmount > 0)) {
                revert NoAmountProvided();
            }
            if (_parameter._buyValue >= _parameter._sellValue && _parameter._sellType == SellLegType.LIMIT_PRICE) {
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
            if (_parameter._floorValue >= _parameter._sellValue) {
                revert FloorValueGreaterThanSellValue();
            }
        }

        if (_parameter._floor && _parameter._floorType == FloorLegType.DECREASE_BY) {
            if (_parameter._floorValue <= 0 || _parameter._floorValue > LibTrade.MAX_PERCENTAGE) {
                revert PercentageNotInRange();
            }
        }

        if (_parameter._sell && _parameter._sellType == SellLegType.INCREASE_BY) {
            if (_parameter._sellValue <= 0 || _parameter._sellValue > LibTrade.MAX_PERCENTAGE) {
                revert PercentageNotInRange();
            }
        }

        // Check if floor and buy are chosen
        if (_parameter._floor && _parameter._buy && _parameter._floorType == FloorLegType.LIMIT_PRICE) {
            if (_parameter._floorValue >= _parameter._buyValue) {
                revert FloorValueGreaterThanBuyValue();
            }
        }

        if (_parameter._slippage > LibTrade.MAX_PERCENTAGE) {
            revert InvalidSlippage();
        }

        if ((_parameter._sellTwap || _parameter._str) && _parameter._sellDCAUnit == DCA_UNIT.PERCENTAGE) {
            if (_parameter._sellDCAValue <= 0 || _parameter._sellDCAValue > LibTrade.MAX_PERCENTAGE) {
                revert SellDCAValueRangeIsNotValid();
            }
        }

        if (
            ((_parameter._sellTwap || _parameter._str) && _parameter._sellDCAUnit == DCA_UNIT.FIXED) &&
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

        if ((_parameter._buyTwap || _parameter._btd) && _parameter._buyDCAUnit == DCA_UNIT.PERCENTAGE) {
            if (_parameter._buyDCAValue < 0 || _parameter._buyDCAValue > LibTrade.MAX_PERCENTAGE) {
                revert BuyDCAValueRangeIsNotValid();
            }
        }

        uint256 decimals = 10 ** IERC20Metadata(_parameter._investToken).decimals();

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
            user: user,
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

        emit StrategyCreated((s.nextStrategyId - 1), user, _parameter, investRoundId, stableRoundId, budget, price);
    }

    /**
     * @dev Update an existing strategy with new parameters.
     * @param strategyId The unique identifier of the strategy to update.
     * @param updateStruct A struct containing the updated parameters for the strategy.
     */
    function UpdateStrategy(uint256 strategyId, UpdateStruct calldata updateStruct) public {
        if (
            updateStruct.sellLimitPrice == 0 &&
            updateStruct.buyLimitPrice == 0 &&
            updateStruct.floorLimitPrice == 0 &&
            updateStruct.highSellValue == 0 &&
            updateStruct.floorPercentageValue == 0 &&
            updateStruct.sellPercentageValue == 0 &&
            updateStruct._buyTwapTime == 0 &&
            updateStruct._buyTwapTimeUnit == TimeUnit.NO_UNIT &&
            updateStruct._buyDCAValue == 0 &&
            updateStruct._sellDCAValue == 0 &&
            updateStruct._sellTwapTime == 0 &&
            updateStruct._sellTwapTimeUnit == TimeUnit.NO_UNIT &&
            updateStruct.toggleCompleteOnSell == false &&
            updateStruct.toggleLiquidateOnFloor == false &&
            updateStruct.toggleCancelOnFloor == false &&
            updateStruct._current_price == CURRENT_PRICE.NOT_SELECTED
        ) {
            revert NothingToUpdate();
        }
        Strategy storage strategy = s.strategies[strategyId];
        if (strategy.user != msg.sender) {
            revert OnlyOwnerCanUpdateStrategies();
        }
        if (strategy.status != Status.ACTIVE) {
            revert StrategyIsNotActive();
        }
        (uint256 price, , ) = LibPrice.getPrice(strategy.parameters._investToken, strategy.parameters._stableToken);
        if (updateStruct._current_price == CURRENT_PRICE.BUY_CURRENT) {
            if (strategy.parameters._buy) {
                strategy.parameters._buyValue = price;
            } else {
                revert BuyNotSet();
            }
        }

        if (updateStruct._current_price == CURRENT_PRICE.SELL_CURRENT) {
            if (strategy.parameters._sell && strategy.parameters._sellType == SellLegType.LIMIT_PRICE) {
                strategy.parameters._sellValue = price;
            } else {
                revert SellNotSelected();
            }
        }
        if (
            updateStruct.floorLimitPrice > 0 &&
            updateStruct.buyLimitPrice > 0 &&
            strategy.parameters._floorType == FloorLegType.LIMIT_PRICE &&
            strategy.parameters._buy &&
            updateStruct.floorLimitPrice >= updateStruct.buyLimitPrice
        ) {
            revert FloorValueGreaterThanBuyValue();
        }

        if (
            updateStruct.floorLimitPrice > 0 &&
            strategy.parameters._floorType == FloorLegType.LIMIT_PRICE &&
            strategy.parameters._buy &&
            updateStruct.floorLimitPrice >= strategy.parameters._buyValue
        ) {
            revert FloorValueGreaterThanBuyValue();
        }

        if (updateStruct.floorPercentageValue > 0 && strategy.parameters._floorType == FloorLegType.DECREASE_BY) {
            if (updateStruct.floorPercentageValue > LibTrade.MAX_PERCENTAGE) {
                revert PercentageNotInRange();
            } else {
                strategy.parameters._floorValue = updateStruct.floorPercentageValue;
            }
        }

        if (updateStruct.sellPercentageValue > 0 && strategy.parameters._sellType == SellLegType.INCREASE_BY) {
            if (updateStruct.sellPercentageValue > LibTrade.MAX_PERCENTAGE) {
                revert PercentageNotInRange();
            } else {
                strategy.parameters._sellValue = updateStruct.sellPercentageValue;
            }
        }

        if (
            updateStruct.floorLimitPrice > 0 &&
            updateStruct.sellLimitPrice > 0 &&
            strategy.parameters._floorType == FloorLegType.LIMIT_PRICE &&
            strategy.parameters._sell &&
            strategy.parameters._sellType == SellLegType.LIMIT_PRICE &&
            updateStruct.floorLimitPrice >= updateStruct.sellLimitPrice
        ) {
            revert FloorValueGreaterThanSellValue();
        }

        if (
            updateStruct.floorLimitPrice > 0 &&
            strategy.parameters._floorType == FloorLegType.LIMIT_PRICE &&
            strategy.parameters._sell &&
            strategy.parameters._sellType == SellLegType.LIMIT_PRICE &&
            updateStruct.floorLimitPrice >= strategy.parameters._sellValue
        ) {
            revert FloorValueGreaterThanSellValue();
        }

        if (
            updateStruct.buyLimitPrice > 0 &&
            updateStruct.sellLimitPrice > 0 &&
            strategy.parameters._buy &&
            strategy.parameters._sell &&
            strategy.parameters._sellType == SellLegType.LIMIT_PRICE &&
            updateStruct.buyLimitPrice >= updateStruct.sellLimitPrice
        ) {
            revert BuyAndSellAtMisorder();
        }

        if (
            updateStruct.buyLimitPrice > 0 &&
            strategy.parameters._sellType == SellLegType.LIMIT_PRICE &&
            strategy.parameters._buyType == BuyLegType.LIMIT_PRICE &&
            updateStruct.buyLimitPrice >= strategy.parameters._sellValue
        ) {
            revert BuyAndSellAtMisorder();
        }

        if (
            strategy.parameters._floor &&
            strategy.parameters._floorType == FloorLegType.LIMIT_PRICE &&
            updateStruct.floorLimitPrice > 0
        ) {
            strategy.parameters._floorValue = updateStruct.floorLimitPrice;
        }

        if (
            strategy.parameters._buy &&
            strategy.parameters._buyType == BuyLegType.LIMIT_PRICE &&
            updateStruct.buyLimitPrice > 0
        ) {
            strategy.parameters._buyValue = updateStruct.buyLimitPrice;
        }

        if (
            strategy.parameters._sell &&
            strategy.parameters._sellType == SellLegType.LIMIT_PRICE &&
            updateStruct.sellLimitPrice > 0
        ) {
            strategy.parameters._sellValue = updateStruct.sellLimitPrice;
        }

        if (
            (strategy.parameters._buyTwap || strategy.parameters._btd) &&
            strategy.parameters._buyDCAUnit == DCA_UNIT.PERCENTAGE
        ) {
            if (updateStruct._buyDCAValue <= 0 || updateStruct._buyDCAValue > LibTrade.MAX_PERCENTAGE) {
                revert BuyDCAValueRangeIsNotValid();
            }
        }

        if (
            ((strategy.parameters._buyTwap || strategy.parameters._btd) &&
                strategy.parameters._buyDCAUnit == DCA_UNIT.FIXED) &&
            strategy.parameters._stableAmount > 0 &&
            (updateStruct._buyDCAValue > strategy.parameters._stableAmount)
        ) {
            revert DCAValueShouldBeLessThanIntitialAmount();
        }

        if (strategy.parameters._btd || strategy.parameters._buyTwap) {
            strategy.parameters._buyDCAValue = updateStruct._buyDCAValue;
        }

        if (
            (strategy.parameters._sellTwap || strategy.parameters._str) &&
            strategy.parameters._sellDCAUnit == DCA_UNIT.PERCENTAGE
        ) {
            if (updateStruct._sellDCAValue <= 0 || updateStruct._sellDCAValue > LibTrade.MAX_PERCENTAGE) {
                revert SellDCAValueRangeIsNotValid();
            }
        }

        if (
            ((strategy.parameters._sellTwap || strategy.parameters._str) &&
                strategy.parameters._sellDCAUnit == DCA_UNIT.FIXED) &&
            strategy.parameters._investAmount > 0 &&
            (updateStruct._sellDCAValue > strategy.parameters._investAmount)
        ) {
            revert DCAValueShouldBeLessThanIntitialAmount();
        }

        if (strategy.parameters._str || strategy.parameters._sellTwap) {
            strategy.parameters._sellDCAValue = updateStruct._sellDCAValue;
        }

        if (
            strategy.parameters._buyTwap &&
            (updateStruct._buyTwapTime != strategy.parameters._buyTwapTime ||
                updateStruct._buyTwapTimeUnit != strategy.parameters._buyTwapTimeUnit)
        ) {
            if (updateStruct._buyTwapTime > 0) {
                strategy.parameters._buyTwapTime = updateStruct._buyTwapTime;
            }
            if (
                updateStruct._buyTwapTimeUnit != strategy.parameters._buyTwapTimeUnit &&
                updateStruct._buyTwapTimeUnit != TimeUnit.NO_UNIT
            ) {
                strategy.parameters._buyTwapTimeUnit = updateStruct._buyTwapTimeUnit;
            }
        }

        if (
            strategy.parameters._sellTwap &&
            (updateStruct._sellTwapTime != strategy.parameters._sellTwapTime ||
                updateStruct._sellTwapTimeUnit != strategy.parameters._sellTwapTimeUnit)
        ) {
            if (updateStruct._sellTwapTime > 0) {
                strategy.parameters._sellTwapTime = updateStruct._sellTwapTime;
            }
            if (
                updateStruct._sellTwapTimeUnit != strategy.parameters._sellTwapTimeUnit &&
                updateStruct._sellTwapTimeUnit != TimeUnit.NO_UNIT
            ) {
                strategy.parameters._sellTwapTimeUnit = updateStruct._sellTwapTimeUnit;
            }
        }

        if (updateStruct.toggleCompleteOnSell) {
            strategy.parameters._completeOnSell = !strategy.parameters._completeOnSell;
        }
        if (updateStruct.toggleLiquidateOnFloor) {
            strategy.parameters._liquidateOnFloor = !strategy.parameters._liquidateOnFloor;
        }
        if (updateStruct.toggleCancelOnFloor) {
            strategy.parameters._cancelOnFloor = !strategy.parameters._cancelOnFloor;
        }

        if (strategy.parameters._highSellValue != 0) {
            if (!(strategy.parameters._str || strategy.parameters._sellTwap)) {
                revert HighSellValueIsChosenWithoutSeLLDCA();
            }
        }

        if (strategy.parameters._str || strategy.parameters._sellTwap) {
            if (
                updateStruct.highSellValue != 0 && strategy.parameters._sellValue > strategy.parameters._highSellValue
            ) {
                revert InvalidHighSellValue();
            } else {
                strategy.parameters._highSellValue = updateStruct.highSellValue;
            }
        }
        emit StrategyUpdated(strategyId, strategy.parameters);
    }
}
