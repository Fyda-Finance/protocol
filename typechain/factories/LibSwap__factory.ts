/* Autogenerated file. Do not edit manually. */

/* tslint:disable */

/* eslint-disable */
import type { LibSwap, LibSwapInterface } from "../LibSwap";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";

const _abi = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "dex",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "fromAsset",
        type: "address",
      },
      {
        indexed: false,
        internalType: "address",
        name: "toAsset",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "fromAmount",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "receivedAmount",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "AssetSwapped",
    type: "event",
  },
];

const _bytecode =
  "0x60566037600b82828239805160001a607314602a57634e487b7160e01b600052600060045260246000fd5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600080fdfea2646970667358221220f17cf598243344d3102d28963dda407d0a51f7d67d9e4c195233dfc9dead783364736f6c63430008140033";

export class LibSwap__factory extends ContractFactory {
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
  ): Promise<LibSwap> {
    return super.deploy(overrides || {}) as Promise<LibSwap>;
  }
  getDeployTransaction(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): LibSwap {
    return super.attach(address) as LibSwap;
  }
  connect(signer: Signer): LibSwap__factory {
    return super.connect(signer) as LibSwap__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): LibSwapInterface {
    return new utils.Interface(_abi) as LibSwapInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): LibSwap {
    return new Contract(address, _abi, signerOrProvider) as LibSwap;
  }
}
