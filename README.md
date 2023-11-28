# Fyda Protocol

Fyda protocol is a set of contracts that validate and execute strategies onchain. Fyda trading bot submits transactions to the on-chain contracts to execute user trades.

## Installation

1. Clone this repo:

```console
git clone git@github.com:Fyda-Finance/protocol.git
```

2. Install NPM packages:

```console
cd protocol
npm install
```

## Test

```console
npx hardhat test
```

## Diamond

Fyda contracts use gas-optimized implementation of [EIP-2535 Diamonds](https://github.com/ethereum/EIPs/issues/2535). This repo uses boilerplate code from [https://github.com/mudgen/diamond-2-hardhat](https://github.com/mudgen/diamond-2-hardhat).

To learn more about it visit [https://medium.com/@MarqyMarq/how-to-implement-the-diamond-standard-69e87dae44e6](https://medium.com/@MarqyMarq/how-to-implement-the-diamond-standard-69e87dae44e6)

### How the scripts/deploy.ts script works

1. DiamondCutFacet is deployed.
1. The diamond is deployed, passing as arguments to the diamond constructor the owner address of the diamond and the DiamondCutFacet address. DiamondCutFacet has the `diamondCut` external function which is used to upgrade the diamond to add more functions.
1. The `DiamondInit` contract is deployed. This contains an `init` function which is called on the first diamond upgrade to initialize state of some state variables. Information on how the `diamondCut` function works is here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface
1. Facets are deployed.
1. The diamond is upgraded. The `diamondCut` function is used to add functions from facets to the diamond. In addition the `diamondCut` function calls the `init` function from the `DiamondInit` contract using `delegatecall` to initialize state variables.

How a diamond is deployed is not part of the EIP-2535 Diamonds standard.

### Upgrade a diamond

Check the `scripts/deploy.ts` and or the `test/diamondTest.ts` file for examples of upgrades.

Any number of functions from any number of facets can be added/replaced/removed on a diamond in a single transaction. In addition an initialization function can be executed in the same transaction as an upgrade to initialize any state variables required for an upgrade. This 'everything done in a single transaction' capability ensures a diamond maintains a correct and consistent state during upgrades.

### Facet Information

**Note:** The loupe functions are NOT gas optimized. The `facets`, `facetFunctionSelectors`, `facetAddresses` loupe functions are not meant to be called on-chain and may use too much gas or run out of gas when called in on-chain transactions. These functions should be called by off-chain software like websites and Javascript libraries etc., where gas costs do not matter.

However the `facetAddress` loupe function is gas efficient and can be called in on-chain transactions.

The `contracts/Diamond.sol` file is the implementation of the diamond.

The `contracts/facets/DiamondCutFacet.sol` implements the `diamondCut` external function.

The `contracts/facets/DiamondLoupeFacet.sol` file implements the four standard loupe functions.

The `contracts/libraries/LibDiamond.sol` file implements Diamond Storage and a `diamondCut` internal function.

The `scripts/deploy.ts` file is used to deploy the diamond.

The `test/diamondTest.ts` file gives tests for the `diamondCut` function and the Diamond Loupe functions.

### Calling Diamond Functions

In order to call a function that exists in a diamond you need to use the ABI information of the facet that has the function.

Here is an example that uses web3.js:

```javascript
let myUsefulFacet = new web3.eth.Contract(MyUsefulFacet.abi, diamondAddress);
```

In the code above we create a contract variable so we can call contract functions with it.

In this example we know we will use a diamond because we pass a diamond's address as the second argument. But we are using an ABI from the MyUsefulFacet facet so we can call functions that are defined in that facet. MyUsefulFacet's functions must have been added to the diamond (using diamondCut) in order for the diamond to use the function information provided by the ABI of course.

Similarly you need to use the ABI of a facet in Solidity code in order to call functions from a diamond. Here's an example of Solidity code that calls a function from a diamond:

```solidity
string result = MyUsefulFacet(address(diamondContract)).getResult()
```

## Linting

```
yarn lint
yarn prettier
```

## Testnet Deployment

```
npx hardhat deploy --tags deployMock --network goerli
```

## Diamond Address

_Ethereum Goerli Testnet_

```
DiamondCutFacet deployed: 0x22fDCee1dD785C85A17Af893bB7029d027436aa8
Diamond deployed: 0x41fC7D436f6EEb725ac7124b0348A858773DC870
DiamondInit deployed: 0x56Dc597Ac7D8D9672f50eD1d8cB543ca0f05D843

Deploying facets
DiamondLoupeFacet deployed: 0xedD8D4af8C072Ee892410FD5B91B51766cf070a1
OwnershipFacet deployed: 0x394eaB3620170129EA956a32B9D2F6DD8D30A98C
StrategyFacet deployed: 0xCA85a2E0079e29c6221cEd6fBadA1e532f6D90d6
BuyFacet deployed: 0x0f407d6B9bad00BC79904B546c6Ac6c0d4573901
SellFacet deployed: 0xcd9AB6a4E2f3C0575008Bc61495570C0530252fc
FloorFacet deployed: 0xC97E0f31d8f884E6a561035a3Ba456BA8aac4082
PriceOracleFacet deployed: 0xe528f19e72639Fe080004CE9284b7C0DD4255Baf
LensFacet deployed: 0x5A65b05B0a5cD87c82f423Df5Bf29Ca983d2Bd58
```
