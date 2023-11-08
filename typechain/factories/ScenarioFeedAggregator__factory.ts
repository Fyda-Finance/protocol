/* Autogenerated file. Do not edit manually. */

/* tslint:disable */

/* eslint-disable */
import type {
  ScenarioFeedAggregator,
  ScenarioFeedAggregatorInterface,
} from "../ScenarioFeedAggregator";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";

const _abi = [
  {
    inputs: [
      {
        internalType: "uint80",
        name: "_roundId",
        type: "uint80",
      },
    ],
    name: "getRoundData",
    outputs: [
      {
        internalType: "uint80",
        name: "",
        type: "uint80",
      },
      {
        internalType: "int256",
        name: "answer",
        type: "int256",
      },
      {
        internalType: "uint256",
        name: "startedAt",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "updatedAt",
        type: "uint256",
      },
      {
        internalType: "uint80",
        name: "answeredInRound",
        type: "uint80",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "latestRoundData",
    outputs: [
      {
        internalType: "uint80",
        name: "",
        type: "uint80",
      },
      {
        internalType: "int256",
        name: "answer",
        type: "int256",
      },
      {
        internalType: "uint256",
        name: "startedAt",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "updatedAt",
        type: "uint256",
      },
      {
        internalType: "uint80",
        name: "answeredInRound",
        type: "uint80",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "price",
    outputs: [
      {
        internalType: "int256",
        name: "",
        type: "int256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "roundId",
    outputs: [
      {
        internalType: "uint80",
        name: "",
        type: "uint80",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint80",
        name: "",
        type: "uint80",
      },
    ],
    name: "roundPrice",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "int256",
        name: "_price",
        type: "int256",
      },
      {
        internalType: "uint80",
        name: "_roundId",
        type: "uint80",
      },
    ],
    name: "setPrice",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint80",
        name: "_roundId",
        type: "uint80",
      },
      {
        internalType: "uint256",
        name: "_price",
        type: "uint256",
      },
    ],
    name: "setRoundPrice",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

const _bytecode =
  "0x608060405234801561001057600080fd5b506102e0806100206000396000f3fe608060405234801561001057600080fd5b506004361061007d5760003560e01c80639a6fc8f51161005b5780639a6fc8f514610116578063a035b1fe1461015d578063a73513fb14610174578063feaf968c1461019457600080fd5b80632341f7361461008257806357a2b9f7146100bc5780638cd221c9146100e6575b600080fd5b6100ba610090366004610232565b6000919091556001805469ffffffffffffffffffff19166001600160501b03909216919091179055565b005b6100ba6100ca36600461025e565b6001600160501b03909116600090815260026020526040902055565b6001546100f9906001600160501b031681565b6040516001600160501b0390911681526020015b60405180910390f35b610129610124366004610288565b6101af565b604080516001600160501b03968716815260208101959095528401929092526060830152909116608082015260a00161010d565b61016660005481565b60405190815260200161010d565b610166610182366004610288565b60026020526000908152604090205481565b600154600080546001600160501b0390921691908080610129565b6001600160501b0381166000908152600260205260408120548190819081908190156101fd575050506001600160501b0383166000908152600260205260408120548493509150808061020d565b5084935060009250829150819050805b91939590929450565b80356001600160501b038116811461022d57600080fd5b919050565b6000806040838503121561024557600080fd5b8235915061025560208401610216565b90509250929050565b6000806040838503121561027157600080fd5b61027a83610216565b946020939093013593505050565b60006020828403121561029a57600080fd5b6102a382610216565b939250505056fea2646970667358221220fff65774f0e9e7ac76842f89cb891e215470db57e38e043a53e0047b94d2fccf64736f6c63430008140033";

export class ScenarioFeedAggregator__factory extends ContractFactory {
  constructor(
    ...args: [signer: Signer] | ConstructorParameters<typeof ContractFactory>
  ) {
    if (args.length === 1) {
      super(_abi, _bytecode, args[0]);
    } else {
      super(...args);
    }
  }

  deploy(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ScenarioFeedAggregator> {
    return super.deploy(overrides || {}) as Promise<ScenarioFeedAggregator>;
  }
  getDeployTransaction(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): ScenarioFeedAggregator {
    return super.attach(address) as ScenarioFeedAggregator;
  }
  connect(signer: Signer): ScenarioFeedAggregator__factory {
    return super.connect(signer) as ScenarioFeedAggregator__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): ScenarioFeedAggregatorInterface {
    return new utils.Interface(_abi) as ScenarioFeedAggregatorInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): ScenarioFeedAggregator {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as ScenarioFeedAggregator;
  }
}
