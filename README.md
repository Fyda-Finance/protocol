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
DiamondCutFacet deployed: 0x67f97Cb202D5244A2d9b39c35107b181e5A6A341
Diamond deployed: 0x64517cb7a2284EEE3D07D4e808F1D624F5Af425D
DiamondInit deployed: 0x86B6c887836Ff39382FFC76b8bc5eC9e89a978D3

Deploying facets
DiamondLoupeFacet deployed: 0x55fe792FDc820a39AB0900BbB820B35B263eD908
OwnershipFacet deployed: 0x0aCCC8C4f1B0DBC5cC771f4B9d9F8Cd2c72e1Df2
StrategyFacet deployed: 0xf7e7F6B08459d45Ce5F2Fef173400BB00704c751
BuyFacet deployed: 0x044588dA92b6942Bc86C949F6fFbA03909c45109
SellFacet deployed: 0x25Af3D209e139147580ca1bCDf0cD4EF1C6b0eE9
FloorFacet deployed: 0xaeD7cCfa3D010d65a01375624915aBdA23FD6b7A
PriceOracleFacet deployed: 0xD156AcAAa82458690F66FA1D2177A95F8294cbD8
LensFacet deployed: 0x0b826bde8bA4e13850468D941AABE7F4C671d2c4
```
