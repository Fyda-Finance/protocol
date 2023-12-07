// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { AppStorage, Strategy, StrategyParameters, SellLegType, BuyLegType, FloorLegType, DCA_UNIT, DIP_SPIKE, TimeUnit, Status, CURRENT_PRICE, UpdateStruct } from "../AppStorage.sol";
import { Modifiers } from "../utils/Modifiers.sol";
import { InvalidImpact, InvalidInvestToken, InvalidStableToken, TokensMustDiffer, AlreadyCancelled, AtLeastOneOptionRequired, InvalidBuyValue, InvalidBuyType, InvalidFloorValue, InvalidFloorType, InvalidSellType, InvalidSellValue, InvalidStableAmount, BuyAndSellAtMisorder, InvalidInvestAmount, FloorValueGreaterThanBuyValue, FloorValueGreaterThanSellValue, BothBuyTwapAndBTD, BuyDCAWithoutBuy, BuyTwapTimeInvalid, BuyTwapTimeUnitNotSelected, BothSellTwapAndSTR, SellDCAWithoutSell, SellTwapTimeUnitNotSelected, SellTwapTimeInvalid, SellTwapOrStrWithoutSellDCAUnit, SellDCAUnitWithoutSellDCAValue, StrWithoutStrType, BTDWithoutBTDType, BuyDCAWithoutBuyDCAUnit, BuyDCAUnitWithoutBuyDCAValue, InvalidHighSellValue, SellDCAValueRangeIsNotValid, BuyDCAValueRangeIsNotValid, DCAValueShouldBeLessThanIntitialAmount, OrphandStrategy, BuyNeverExecute, InvalidSigner, InvalidNonce, StrategyIsNotActive, BuyNotSet, SellNotSelected, PercentageNotInRange, BuyTwapNotSelected, SellTwapNotSelected, FloorNotSet } from "../utils/GenericErrors.sol";
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
error SellDCANotSet();
error BuyDCANotSet();
error STRIsNotSet();
error BTDIsNotSet();
error InvestAmountMustBeProvided();
error FloorPercentageNotSet();
error SellPercentageNotSet();
error StrValueGreaterThan100();
error BtdValueGreaterThan100();

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
     * @param investTokenPrice The price of the invest token in USD.
     * @param stableTokenPrice The price of the stable token in USD.
     */
    event StrategyCancelled(uint256 indexed strategyId, uint256 investTokenPrice, uint256 stableTokenPrice);

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
    function cancelStrategy(uint256 id) external nonReentrant {
        _cancelStrategy(msg.sender, id);
    }

    /**
     * @notice Cancel a trade execution strategy on behalf of another user.
     * @dev This function allows users to cancel a trade execution strategy based on its unique ID.
     *      When cancelled, the strategy's status is updated to "CANCELLED."
     * @param id The unique ID of the strategy to cancel.
     */
    function cancelStrategyOnBehalf(
        uint256 id,
        uint256 nonce,
        bytes memory signature,
        address account
    ) external nonReentrant {
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
        uint256 investPrice = LibPrice.getUSDPrice(strategy.parameters._investToken);
        uint256 stablePrice = LibPrice.getUSDPrice(strategy.parameters._stableToken);
        emit StrategyCancelled(id, investPrice, stablePrice);
    }

    /**
     * @notice Get the next available strategy ID.
     * @dev This function returns the unique ID that will be assigned to the next created strategy.
     * @return The next available strategy ID.
     */
    function nextStrategyId() external view returns (uint256) {
        return s.nextStrategyId;
    }

    /**
     * @notice Create a new trade execution strategy based on the provided parameters.
     * @dev This function validates the input parameters to ensure they satisfy the criteria for creating a strategy.
     *      If the parameters are valid, a new strategy is created and an event is emitted to indicate the successful creation.
     *      If the parameters do not meet the criteria, an error is thrown.
     * @param _parameter The strategy parameters defining the behavior and conditions of the strategy.
     */
    function createStrategy(StrategyParameters memory _parameter) public nonReentrant {
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
    ) public nonReentrant {
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
        (uint256 price, uint80 investRoundId, uint80 stableRoundId) = LibPrice.getPrice(
            _parameter._investToken,
            _parameter._stableToken
        );

        if (_parameter._current_price == CURRENT_PRICE.BUY_CURRENT) {
            _parameter._buyType = BuyLegType.LIMIT_PRICE;
            _parameter._buyValue = price + (price * _parameter._impact) / LibTrade.MAX_PERCENTAGE;
        }
        if (_parameter._current_price == CURRENT_PRICE.SELL_CURRENT) {
            _parameter._sellType = SellLegType.LIMIT_PRICE;
            _parameter._sellValue = price - ((price * _parameter._impact) / LibTrade.MAX_PERCENTAGE);
        }

        if ((_parameter._floorValue == 0 && _parameter._sellValue == 0 && _parameter._buyValue == 0)) {
            revert AtLeastOneOptionRequired();
        }

        if (_parameter._buyValue > 0 && _parameter._buyTwapTime > 0 && _parameter._btdValue > 0) {
            revert BothBuyTwapAndBTD();
        }

        if ((_parameter._buyTwapTime > 0 || _parameter._btdValue > 0) && _parameter._buyValue == 0) {
            revert BuyDCAWithoutBuy();
        }

        if (_parameter._buyTwapTime > 0 && _parameter._buyTwapTimeUnit == TimeUnit.NO_UNIT) {
            revert BuyTwapTimeUnitNotSelected();
        }

        if (_parameter._sellTwapTime > 0 && _parameter._strValue > 0) {
            revert BothSellTwapAndSTR();
        }

        if ((_parameter._sellTwapTime > 0 || _parameter._strValue > 0) && _parameter._sellValue == 0) {
            revert SellDCAWithoutSell();
        }
        if (_parameter._sellTwapTime > 0 && _parameter._sellTwapTimeUnit == TimeUnit.NO_UNIT) {
            revert SellTwapTimeUnitNotSelected();
        }

        if ((_parameter._sellTwapTime > 0 || _parameter._strValue > 0) && _parameter._sellDCAUnit == DCA_UNIT.NO_UNIT) {
            revert SellTwapOrStrWithoutSellDCAUnit();
        }

        if (_parameter._sellDCAUnit != DCA_UNIT.NO_UNIT && _parameter._sellDCAValue == 0) {
            revert SellDCAUnitWithoutSellDCAValue();
        }

        if (_parameter._strValue > 0 && _parameter._strType == DIP_SPIKE.NO_SPIKE) {
            revert StrWithoutStrType();
        }

        if (
            _parameter._strValue > 0 &&
            _parameter._strType == DIP_SPIKE.DECREASE_BY &&
            _parameter._strValue > LibTrade.MAX_PERCENTAGE
        ) {
            revert StrValueGreaterThan100();
        }

        if (_parameter._btdValue > 0 && _parameter._btdType == DIP_SPIKE.NO_SPIKE) {
            revert BTDWithoutBTDType();
        }

        if (
            _parameter._btdValue > 0 &&
            _parameter._btdType == DIP_SPIKE.DECREASE_BY &&
            _parameter._btdValue > LibTrade.MAX_PERCENTAGE
        ) {
            revert BtdValueGreaterThan100();
        }

        if ((_parameter._btdValue > 0 || _parameter._buyTwapTime > 0) && _parameter._buyDCAUnit == DCA_UNIT.NO_UNIT) {
            revert BuyDCAWithoutBuyDCAUnit();
        }

        if (_parameter._buyDCAUnit != DCA_UNIT.NO_UNIT && _parameter._buyDCAValue == 0) {
            revert BuyDCAUnitWithoutBuyDCAValue();
        }

        if (_parameter._buyValue > 0 && _parameter._buyType == BuyLegType.NO_TYPE) {
            revert InvalidBuyType();
        }

        // Check if floor is chosen
        if (_parameter._floorValue > 0 && _parameter._floorType == FloorLegType.NO_TYPE) {
            revert InvalidFloorType();
        }

        if (_parameter._highSellValue != 0) {
            if (!(_parameter._strValue > 0 || _parameter._sellTwapTime > 0)) {
                revert HighSellValueIsChosenWithoutSeLLDCA();
            }
        }

        if (_parameter._sellValue > 0 || _parameter._strValue > 0 || _parameter._sellTwapTime > 0) {
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
        if (_parameter._buyValue > 0 && (_parameter._sellValue > 0 || _parameter._floorValue > 0)) {
            if (_parameter._stableAmount == 0 && _parameter._investAmount == 0) {
                revert NoAmountProvided();
            }
            if (_parameter._buyValue >= _parameter._sellValue && _parameter._sellType == SellLegType.LIMIT_PRICE) {
                revert BuyAndSellAtMisorder();
            }
        }
        // Check if only buy is chosen
        if (_parameter._buyValue > 0 && _parameter._sellValue == 0 && _parameter._floorValue == 0) {
            if (_parameter._stableAmount == 0) {
                revert InvalidStableAmount();
            }
            if (_parameter._investAmount > 0) {
                revert OrphandStrategy();
            }
        }

        if (_parameter._buyValue == 0 && _parameter._sellValue > 0 && _parameter._floorValue > 0) {
            if (_parameter._stableAmount > 0) {
                revert OrphandStrategy();
            }
        }

        if (
            (_parameter._sellValue > 0 || _parameter._floorValue > 0) &&
            _parameter._investAmount == 0 &&
            _parameter._buyValue == 0
        ) {
            revert InvestAmountMustBeProvided();
        }
        if (
            (_parameter._sellValue > 0 || _parameter._floorValue > 0) &&
            _parameter._investAmount > 0 &&
            (_parameter._completeOnSell || _parameter._cancelOnFloor) &&
            _parameter._buyValue > 0
        ) // Check if only sell is chosen
        {
            revert BuyNeverExecute();
        }

        // Check if floor and sell are chosen
        if (
            _parameter._floorValue > 0 &&
            _parameter._sellValue > 0 &&
            _parameter._sellType == SellLegType.LIMIT_PRICE &&
            _parameter._floorType == FloorLegType.LIMIT_PRICE
        ) {
            if (_parameter._floorValue >= _parameter._sellValue) {
                revert FloorValueGreaterThanSellValue();
            }
        }

        if (_parameter._floorValue > 0 && _parameter._floorType == FloorLegType.DECREASE_BY) {
            if (_parameter._floorValue > LibTrade.MAX_PERCENTAGE) {
                revert PercentageNotInRange();
            }
        }

        // Check if floor and buy are chosen
        if (
            _parameter._floorValue > 0 && _parameter._buyValue > 0 && _parameter._floorType == FloorLegType.LIMIT_PRICE
        ) {
            if (_parameter._floorValue >= _parameter._buyValue) {
                revert FloorValueGreaterThanBuyValue();
            }
        }

        if (_parameter._impact > LibTrade.MAX_PERCENTAGE || _parameter._impact == 0) {
            revert InvalidImpact();
        }

        if (
            (_parameter._sellTwapTime > 0 || _parameter._strValue > 0) && _parameter._sellDCAUnit == DCA_UNIT.PERCENTAGE
        ) {
            if (_parameter._sellDCAValue <= 0 || _parameter._sellDCAValue > LibTrade.MAX_PERCENTAGE) {
                revert SellDCAValueRangeIsNotValid();
            }
        }

        if (
            ((_parameter._sellTwapTime > 0 || _parameter._strValue > 0) && _parameter._sellDCAUnit == DCA_UNIT.FIXED) &&
            _parameter._investAmount > 0 &&
            (_parameter._sellDCAValue > _parameter._investAmount)
        ) {
            revert DCAValueShouldBeLessThanIntitialAmount();
        }

        if (
            (_parameter._buyTwapTime > 0 || _parameter._btdValue > 0) &&
            (_parameter._buyDCAUnit == DCA_UNIT.FIXED) &&
            _parameter._stableAmount > 0 &&
            (_parameter._buyDCAValue > _parameter._stableAmount)
        ) {
            revert DCAValueShouldBeLessThanIntitialAmount();
        }

        if (
            (_parameter._buyTwapTime > 0 || _parameter._btdValue > 0) && _parameter._buyDCAUnit == DCA_UNIT.PERCENTAGE
        ) {
            if (_parameter._buyDCAValue <= 0 || _parameter._buyDCAValue > LibTrade.MAX_PERCENTAGE) {
                revert BuyDCAValueRangeIsNotValid();
            }
        }

        if (_parameter._minimumProfit > 0 && _parameter._sellType != SellLegType.INCREASE_BY) {
            revert SellPercentageNotSet();
        }

        if (_parameter._minimumLoss > 0 && _parameter._floorType != FloorLegType.DECREASE_BY) {
            revert FloorPercentageNotSet();
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
        uint256 percentageAmountForSell = 0;
        if (_parameter._sellDCAUnit == DCA_UNIT.PERCENTAGE) {
            percentageAmountForSell = (_parameter._sellDCAValue * _parameter._investAmount) / LibTrade.MAX_PERCENTAGE;
        }
        uint256 percentageAmountForBuy = 0;
        if (_parameter._buyDCAUnit == DCA_UNIT.PERCENTAGE) {
            percentageAmountForBuy = (_parameter._buyDCAValue * _parameter._stableAmount) / LibTrade.MAX_PERCENTAGE;
        }
        s.strategies[s.nextStrategyId] = Strategy({
            user: user,
            sellTwapExecutedAt: 0,
            buyTwapExecutedAt: 0,
            investRoundIdForBTD: investRoundId,
            stableRoundIdForBTD: stableRoundId,
            investRoundIdForSTR: investRoundId,
            stableRoundIdForSTR: stableRoundId,
            parameters: _parameter,
            investPrice: investPrice,
            profit: 0,
            sellPercentageAmount: percentageAmountForSell,
            sellPercentageTotalAmount: percentageAmountForSell > 0 ? _parameter._investAmount : 0,
            buyPercentageAmount: percentageAmountForBuy,
            buyPercentageTotalAmount: percentageAmountForBuy > 0 ? _parameter._stableAmount : 0,
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
    function updateStrategy(uint256 strategyId, UpdateStruct calldata updateStruct) external nonReentrant {
        _updateStrategy(msg.sender, strategyId, updateStruct);
    }

    /**
     * @notice Get the message hash for a given strategy to update it.
     * @dev This function returns the message hash that must be signed by the user in order to update a strategy on behalf of another user.
     * @param id The strategy id
     * @param updateStruct updated parameters of the strategy
     * @param nonce The nonce of the user who created the strategy.
     * @param account The address of the user who created the strategy.
     * @return The message hash for the given strategy.
     */
    function getMessageHashToUpdate(
        uint256 id,
        UpdateStruct calldata updateStruct,
        uint256 nonce,
        address account
    ) public view returns (bytes32) {
        return keccak256(abi.encode(account, nonce, id, updateStruct, LibUtil.getChainID()));
    }

    /**
     * @dev Update an existing strategy with new parameters on behalf of another user.
     * @param strategyId The unique identifier of the strategy to update.
     * @param updateStruct A struct containing the updated parameters for the strategy.
     * @param account The address of the user who created the strategy.
     * @param nonce The nonce of the user who created the strategy.
     * @param signature The signature of the user who created the strategy.
     */
    function updateStrategyOnBehalf(
        uint256 strategyId,
        UpdateStruct calldata updateStruct,
        address account,
        uint256 nonce,
        bytes memory signature
    ) external nonReentrant {
        if (s.nonces[account] != nonce) {
            revert InvalidNonce();
        }

        bytes32 messageHash = getMessageHashToUpdate(strategyId, updateStruct, nonce, account);
        bytes32 ethSignedMessageHash = LibSignature.getEthSignedMessageHash(messageHash);
        address signer = LibSignature.recoverSigner(ethSignedMessageHash, signature);
        s.nonces[account] = s.nonces[account] + 1;

        if (signer != account) {
            revert InvalidSigner();
        }

        _updateStrategy(signer, strategyId, updateStruct);
    }

    /**
     * @dev Update an existing strategy with new parameters.
     * @param account The address of the user who created the strategy.
     * @param strategyId The unique identifier of the strategy to update.
     * @param updateStruct A struct containing the updated parameters for the strategy.
     */
    function _updateStrategy(address account, uint256 strategyId, UpdateStruct calldata updateStruct) internal {
        if (
            updateStruct.sellValue == 0 &&
            updateStruct.buyValue == 0 &&
            updateStruct.floorValue == 0 &&
            updateStruct.highSellValue == 0 &&
            updateStruct.buyTwapTime == 0 &&
            updateStruct.buyTwapTimeUnit == TimeUnit.NO_UNIT &&
            updateStruct.buyDCAValue == 0 &&
            updateStruct.sellDCAValue == 0 &&
            updateStruct.strValue == 0 &&
            updateStruct.btdValue == 0 &&
            updateStruct.sellTwapTime == 0 &&
            updateStruct.sellTwapTimeUnit == TimeUnit.NO_UNIT &&
            updateStruct.toggleCompleteOnSell == false &&
            updateStruct.toggleLiquidateOnFloor == false &&
            updateStruct.toggleCancelOnFloor == false &&
            updateStruct.impact == 0 &&
            updateStruct.minimumProfit == 0 &&
            updateStruct.minimumLoss == 0 &&
            updateStruct.current_price == CURRENT_PRICE.NOT_SELECTED
        ) {
            revert NothingToUpdate();
        }
        Strategy storage strategy = s.strategies[strategyId];
        if (strategy.user != account) {
            revert OnlyOwnerCanUpdateStrategies();
        }
        if (strategy.status != Status.ACTIVE) {
            revert StrategyIsNotActive();
        }

        if (updateStruct.sellValue > 0 && strategy.parameters._sellValue == 0) {
            revert SellNotSelected();
        }
        if (updateStruct.buyValue > 0 && (strategy.parameters._buyValue == 0)) {
            revert BuyNotSet();
        }
        if (updateStruct.floorValue > 0 && strategy.parameters._floorValue == 0) {
            revert FloorNotSet();
        }

        if (
            (updateStruct.highSellValue > 0 || updateStruct.sellDCAValue > 0) &&
            (strategy.parameters._strValue == 0 && strategy.parameters._sellTwapTime == 0)
        ) {
            revert SellDCANotSet();
        }

        if (strategy.parameters._strValue == 0 && updateStruct.strValue > 0) {
            revert STRIsNotSet();
        }

        if (
            updateStruct.strValue > LibTrade.MAX_PERCENTAGE && (strategy.parameters._strType == DIP_SPIKE.DECREASE_BY)
        ) {
            revert PercentageNotInRange();
        } else if (
            updateStruct.strValue > 0 &&
            (strategy.parameters._strType == DIP_SPIKE.INCREASE_BY ||
                strategy.parameters._strType == DIP_SPIKE.DECREASE_BY)
        ) {
            strategy.parameters._strValue = updateStruct.strValue;
        }
        if (
            updateStruct.strValue > 0 &&
            (strategy.parameters._strType == DIP_SPIKE.FIXED_DECREASE ||
                strategy.parameters._strType == DIP_SPIKE.FIXED_INCREASE)
        ) {
            strategy.parameters._strValue = updateStruct.strValue;
        }

        if (strategy.parameters._btdValue == 0 && updateStruct.btdValue > 0) {
            revert BTDIsNotSet();
        }

        if (
            updateStruct.btdValue > LibTrade.MAX_PERCENTAGE && (strategy.parameters._btdType == DIP_SPIKE.DECREASE_BY)
        ) {
            revert PercentageNotInRange();
        } else if (
            updateStruct.btdValue > 0 &&
            (strategy.parameters._btdType == DIP_SPIKE.INCREASE_BY ||
                strategy.parameters._btdType == DIP_SPIKE.DECREASE_BY)
        ) {
            strategy.parameters._btdValue = updateStruct.btdValue;
        }
        if (
            updateStruct.btdValue > 0 &&
            (strategy.parameters._btdType == DIP_SPIKE.FIXED_DECREASE ||
                strategy.parameters._btdType == DIP_SPIKE.FIXED_INCREASE)
        ) {
            strategy.parameters._btdValue = updateStruct.btdValue;
        }

        if (
            updateStruct.buyDCAValue > 0 &&
            (strategy.parameters._btdValue == 0 || strategy.parameters._buyTwapTime == 0)
        ) {
            revert BuyDCANotSet();
        }
        if (
            (updateStruct.buyTwapTime > 0 || updateStruct.buyTwapTimeUnit != TimeUnit.NO_UNIT) &&
            strategy.parameters._buyTwapTime == 0
        ) {
            revert BuyTwapNotSelected();
        }
        if (
            (updateStruct.sellTwapTime > 0 || updateStruct.sellTwapTimeUnit != TimeUnit.NO_UNIT) &&
            strategy.parameters._sellTwapTime == 0
        ) {
            revert SellTwapNotSelected();
        }
        if (updateStruct.impact > LibTrade.MAX_PERCENTAGE) {
            revert InvalidImpact();
        }

        if (updateStruct.impact > 0) {
            strategy.parameters._impact = updateStruct.impact;
        }

        (uint256 price, , ) = LibPrice.getPrice(strategy.parameters._investToken, strategy.parameters._stableToken);
        if (updateStruct.current_price == CURRENT_PRICE.BUY_CURRENT) {
            if (strategy.parameters._buyValue > 0) {
                strategy.parameters._buyValue =
                    price +
                    ((price * strategy.parameters._impact) / LibTrade.MAX_PERCENTAGE);
            } else {
                revert BuyNotSet();
            }
        }

        if (updateStruct.current_price == CURRENT_PRICE.SELL_CURRENT) {
            if (strategy.parameters._sellValue > 0 && strategy.parameters._sellType == SellLegType.LIMIT_PRICE) {
                strategy.parameters._sellValue =
                    price -
                    ((price * strategy.parameters._impact) / LibTrade.MAX_PERCENTAGE);
            } else {
                revert SellNotSelected();
            }
        }

        if (
            updateStruct.floorValue > 0 &&
            updateStruct.buyValue > 0 &&
            strategy.parameters._floorType == FloorLegType.LIMIT_PRICE &&
            strategy.parameters._buyValue > 0 &&
            updateStruct.floorValue >= updateStruct.buyValue
        ) {
            revert FloorValueGreaterThanBuyValue();
        }

        if (
            updateStruct.floorValue > 0 &&
            strategy.parameters._floorType == FloorLegType.LIMIT_PRICE &&
            strategy.parameters._buyValue > 0 &&
            updateStruct.floorValue >= strategy.parameters._buyValue
        ) {
            revert FloorValueGreaterThanBuyValue();
        }

        if (updateStruct.floorValue > 0 && strategy.parameters._floorType == FloorLegType.DECREASE_BY) {
            if (updateStruct.floorValue > LibTrade.MAX_PERCENTAGE) {
                revert PercentageNotInRange();
            } else {
                strategy.parameters._floorValue = updateStruct.floorValue;
            }
        }

        if (
            updateStruct.floorValue > 0 &&
            updateStruct.sellValue > 0 &&
            strategy.parameters._floorType == FloorLegType.LIMIT_PRICE &&
            strategy.parameters._sellValue > 0 &&
            strategy.parameters._sellType == SellLegType.LIMIT_PRICE &&
            updateStruct.floorValue >= updateStruct.sellValue
        ) {
            revert FloorValueGreaterThanSellValue();
        }

        if (
            updateStruct.sellValue > 0 &&
            strategy.parameters._floorType == FloorLegType.LIMIT_PRICE &&
            strategy.parameters._sellValue > 0 &&
            strategy.parameters._sellType == SellLegType.LIMIT_PRICE &&
            strategy.parameters._floorValue >= updateStruct.sellValue
        ) {
            revert FloorValueGreaterThanSellValue();
        }

        if (
            updateStruct.floorValue > 0 &&
            strategy.parameters._floorType == FloorLegType.LIMIT_PRICE &&
            strategy.parameters._sellValue > 0 &&
            strategy.parameters._sellType == SellLegType.LIMIT_PRICE &&
            updateStruct.floorValue >= strategy.parameters._sellValue
        ) {
            revert FloorValueGreaterThanSellValue();
        }

        if (
            updateStruct.buyValue > 0 &&
            updateStruct.sellValue > 0 &&
            strategy.parameters._buyValue > 0 &&
            strategy.parameters._sellValue > 0 &&
            strategy.parameters._sellType == SellLegType.LIMIT_PRICE &&
            updateStruct.buyValue >= updateStruct.sellValue
        ) {
            revert BuyAndSellAtMisorder();
        }

        if (
            updateStruct.buyValue > 0 &&
            strategy.parameters._sellType == SellLegType.LIMIT_PRICE &&
            strategy.parameters._buyType == BuyLegType.LIMIT_PRICE &&
            updateStruct.buyValue >= strategy.parameters._sellValue
        ) {
            revert BuyAndSellAtMisorder();
        }

        if (
            updateStruct.sellValue > 0 &&
            strategy.parameters._buyValue > 0 &&
            strategy.parameters._sellValue > 0 &&
            strategy.parameters._sellType == SellLegType.LIMIT_PRICE &&
            strategy.parameters._buyValue >= updateStruct.sellValue
        ) {
            revert BuyAndSellAtMisorder();
        }

        if (
            strategy.parameters._floorValue > 0 &&
            strategy.parameters._floorType == FloorLegType.LIMIT_PRICE &&
            updateStruct.floorValue > 0
        ) {
            strategy.parameters._floorValue = updateStruct.floorValue;
        }

        if (strategy.parameters._buyValue > 0 && updateStruct.buyValue > 0) {
            strategy.parameters._buyValue = updateStruct.buyValue;
        }

        if (strategy.parameters._sellValue > 0 && updateStruct.sellValue > 0) {
            strategy.parameters._sellValue = updateStruct.sellValue;
        }

        if (
            (strategy.parameters._buyTwapTime > 0 || strategy.parameters._btdValue > 0) &&
            strategy.parameters._buyDCAUnit == DCA_UNIT.PERCENTAGE
        ) {
            if (updateStruct.buyDCAValue <= 0 || updateStruct.buyDCAValue > LibTrade.MAX_PERCENTAGE) {
                revert BuyDCAValueRangeIsNotValid();
            }
        }

        if (
            ((strategy.parameters._buyTwapTime > 0 || strategy.parameters._btdValue > 0) &&
                strategy.parameters._buyDCAUnit == DCA_UNIT.FIXED) &&
            strategy.parameters._stableAmount > 0 &&
            (updateStruct.buyDCAValue > strategy.parameters._stableAmount)
        ) {
            revert DCAValueShouldBeLessThanIntitialAmount();
        }

        if (
            (strategy.parameters._btdValue > 0 || strategy.parameters._buyTwapTime > 0) && updateStruct.buyDCAValue > 0
        ) {
            strategy.parameters._buyDCAValue = updateStruct.buyDCAValue;
        }

        if (
            (strategy.parameters._sellTwapTime > 0 || strategy.parameters._strValue > 0) &&
            strategy.parameters._sellDCAUnit == DCA_UNIT.PERCENTAGE
        ) {
            if (updateStruct.sellDCAValue <= 0 || updateStruct.sellDCAValue > LibTrade.MAX_PERCENTAGE) {
                revert SellDCAValueRangeIsNotValid();
            }
        }

        if (
            ((strategy.parameters._sellTwapTime > 0 || strategy.parameters._strValue > 0) &&
                strategy.parameters._sellDCAUnit == DCA_UNIT.FIXED) &&
            strategy.parameters._investAmount > 0 &&
            (updateStruct.sellDCAValue > strategy.parameters._investAmount)
        ) {
            revert DCAValueShouldBeLessThanIntitialAmount();
        }

        if (updateStruct.minimumLoss > 0 && strategy.parameters._floorType != FloorLegType.DECREASE_BY) {
            revert FloorPercentageNotSet();
        }

        if (updateStruct.minimumProfit > 0 && strategy.parameters._sellType != SellLegType.INCREASE_BY) {
            revert SellPercentageNotSet();
        }

        if (updateStruct.minimumLoss > 0) {
            strategy.parameters._minimumLoss = updateStruct.minimumLoss;
        }

        if (updateStruct.minimumProfit > 0) {
            strategy.parameters._minimumProfit = updateStruct.minimumProfit;
        }

        if (
            (strategy.parameters._strValue > 0 || strategy.parameters._sellTwapTime > 0) &&
            updateStruct.sellDCAValue > 0
        ) {
            strategy.parameters._sellDCAValue = updateStruct.sellDCAValue;
        }

        if (
            strategy.parameters._buyTwapTime > 0 &&
            (updateStruct.buyTwapTime != strategy.parameters._buyTwapTime ||
                updateStruct.buyTwapTimeUnit != strategy.parameters._buyTwapTimeUnit)
        ) {
            strategy.parameters._buyTwapTime = updateStruct.buyTwapTime;

            if (updateStruct.buyTwapTimeUnit != TimeUnit.NO_UNIT) {
                strategy.parameters._buyTwapTimeUnit = updateStruct.buyTwapTimeUnit;
            }
        }

        if (
            strategy.parameters._sellTwapTime > 0 &&
            (updateStruct.sellTwapTime != strategy.parameters._sellTwapTime ||
                updateStruct.sellTwapTimeUnit != strategy.parameters._sellTwapTimeUnit)
        ) {
            if (updateStruct.sellTwapTime > 0) {
                strategy.parameters._sellTwapTime = updateStruct.sellTwapTime;
            }
            if (
                updateStruct.sellTwapTimeUnit != strategy.parameters._sellTwapTimeUnit &&
                updateStruct.sellTwapTimeUnit != TimeUnit.NO_UNIT
            ) {
                strategy.parameters._sellTwapTimeUnit = updateStruct.sellTwapTimeUnit;
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

        if (updateStruct.highSellValue != 0) {
            if ((strategy.parameters._strValue == 0 && strategy.parameters._sellTwapTime == 0)) {
                revert HighSellValueIsChosenWithoutSeLLDCA();
            }
        }

        if (strategy.parameters._strValue > 0 || strategy.parameters._sellTwapTime > 0) {
            if (updateStruct.highSellValue != 0 && strategy.parameters._sellValue > updateStruct.highSellValue) {
                revert InvalidHighSellValue();
            }
        }

        if (updateStruct.highSellValue != 0) {
            strategy.parameters._highSellValue = updateStruct.highSellValue;
        }

        if (updateStruct.buyDCAValue > 0) {
            strategy.buyPercentageAmount =
                (strategy.parameters._buyDCAValue * strategy.buyPercentageTotalAmount) /
                LibTrade.MAX_PERCENTAGE;
        }

        if (updateStruct.sellDCAValue > 0) {
            strategy.sellPercentageAmount =
                (strategy.parameters._sellDCAValue * strategy.sellPercentageTotalAmount) /
                LibTrade.MAX_PERCENTAGE;
        }
        emit StrategyUpdated(strategyId, strategy.parameters);
    }
}
