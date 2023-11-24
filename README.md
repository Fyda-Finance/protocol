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
DiamondCutFacet deployed: 0x196C5A1cab44A2fA49fC3A9ECFEfF93e4D1c9CB0
Diamond deployed: 0xF2fb5df69e2936F9737f1bF9c9e8c41f0dFE3584
DiamondInit deployed: 0xc73361B62c6C3A71c43dB17C0674e73b17036bf2

Deploying facets
DiamondLoupeFacet deployed: 0x2750DEd57A8AFB7e7a2594FbA77CA348438B0Adb
OwnershipFacet deployed: 0xe4a246af1A9D58959fd4d98d1Dc4225c86035788
StrategyFacet deployed: 0xca5DcD2F8FBd3fAeDe21D35AdBd07aB0213FbcaE
BuyFacet deployed: 0xf5979Cd3d2221Da0c29973cD80D1679529118C36
SellFacet deployed: 0xBFf785420C896d3AD180D40c711492F0Cf894e4c
FloorFacet deployed: 0x49FB83495c80c32ffD7E6b64ac9F42Caf8852D24
PriceOracleFacet deployed: 0xC5F97f88A8b97b4C71eae1F3e69D560D5D9A4435
LensFacet deployed: 0xa786abaD1683F6B18442123E46762adbAbC96E32
```
