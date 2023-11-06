/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import type { ScenarioDEX, ScenarioDEXInterface } from "../ScenarioDEX";

const _abi = [
  {
    inputs: [],
    name: "USD_DECIMALS",
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
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "exchangeRate",
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
        internalType: "address",
        name: "fromAsset",
        type: "address",
      },
      {
        internalType: "address",
        name: "toAsset",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "fromAmount",
        type: "uint256",
      },
    ],
    name: "swap",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "asset",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "rate",
        type: "uint256",
      },
    ],
    name: "updateExchangeRate",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

const _bytecode =
  "0x608060405234801561001057600080fd5b50610975806100206000396000f3fe608060405234801561001057600080fd5b506004361061004c5760003560e01c80632d2ee26e146100515780632f6ee6951461007d578063dc3b7c8b14610097578063df791e50146100b7575b600080fd5b61007b61005f366004610680565b6001600160a01b03909116600090815260208190526040902055565b005b610085600881565b60405190815260200160405180910390f35b6100856100a53660046106aa565b60006020819052908152604090205481565b61007b6100c53660046106c5565b6001600160a01b0383166000908152602081905260409020546101035760405162461bcd60e51b81526004016100fa90610701565b60405180910390fd5b6001600160a01b0382166000908152602081905260409020546101385760405162461bcd60e51b81526004016100fa90610701565b6000811161019f5760405162461bcd60e51b815260206004820152602e60248201527f5363656e6172696f4445583a2066726f6d416d6f756e74206d7573742062652060448201526d067726561746572207468616e20360941b60648201526084016100fa565b600083905060008390506000826001600160a01b031663313ce5676040518163ffffffff1660e01b8152600401602060405180830381865afa1580156101e9573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061020d9190610743565b61021890600a610862565b6001600160a01b03871660009081526020819052604090205461023b9086610871565b6102459190610888565b90506000806000876001600160a01b03166001600160a01b0316815260200190815260200160002054836001600160a01b031663313ce5676040518163ffffffff1660e01b8152600401602060405180830381865afa1580156102ac573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906102d09190610743565b6102db90600a610862565b6102e59084610871565b6102ef9190610888565b6040516340c10f1960e01b8152306004820152602481018290529091506001600160a01b038716906340c10f1990604401600060405180830381600087803b15801561033a57600080fd5b505af115801561034e573d6000803e3d6000fd5b5050505061035d863383610372565b610369873330886103da565b50505050505050565b6040516001600160a01b0383166024820152604481018290526103d590849063a9059cbb60e01b906064015b60408051601f198184030181529190526020810180516001600160e01b03166001600160e01b031990931692909217909152610418565b505050565b6040516001600160a01b03808516602483015283166044820152606481018290526104129085906323b872dd60e01b9060840161039e565b50505050565b600061046d826040518060400160405280602081526020017f5361666545524332303a206c6f772d6c6576656c2063616c6c206661696c6564815250856001600160a01b03166104ea9092919063ffffffff16565b8051909150156103d5578080602001905181019061048b91906108aa565b6103d55760405162461bcd60e51b815260206004820152602a60248201527f5361666545524332303a204552433230206f7065726174696f6e20646964206e6044820152691bdd081cdd58d8d9595960b21b60648201526084016100fa565b60606104f98484600085610503565b90505b9392505050565b6060824710156105645760405162461bcd60e51b815260206004820152602660248201527f416464726573733a20696e73756666696369656e742062616c616e636520666f6044820152651c8818d85b1b60d21b60648201526084016100fa565b843b6105b25760405162461bcd60e51b815260206004820152601d60248201527f416464726573733a2063616c6c20746f206e6f6e2d636f6e747261637400000060448201526064016100fa565b600080866001600160a01b031685876040516105ce91906108f0565b60006040518083038185875af1925050503d806000811461060b576040519150601f19603f3d011682016040523d82523d6000602084013e610610565b606091505b509150915061062082828661062b565b979650505050505050565b6060831561063a5750816104fc565b82511561064a5782518084602001fd5b8160405162461bcd60e51b81526004016100fa919061090c565b80356001600160a01b038116811461067b57600080fd5b919050565b6000806040838503121561069357600080fd5b61069c83610664565b946020939093013593505050565b6000602082840312156106bc57600080fd5b6104fc82610664565b6000806000606084860312156106da57600080fd5b6106e384610664565b92506106f160208501610664565b9150604084013590509250925092565b60208082526022908201527f5363656e6172696f4445583a2065786368616e67652072617465206e6f742073604082015261195d60f21b606082015260800190565b60006020828403121561075557600080fd5b815160ff811681146104fc57600080fd5b634e487b7160e01b600052601160045260246000fd5b600181815b808511156107b757816000190482111561079d5761079d610766565b808516156107aa57918102915b93841c9390800290610781565b509250929050565b6000826107ce5750600161085c565b816107db5750600061085c565b81600181146107f157600281146107fb57610817565b600191505061085c565b60ff84111561080c5761080c610766565b50506001821b61085c565b5060208310610133831016604e8410600b841016171561083a575081810a61085c565b610844838361077c565b806000190482111561085857610858610766565b0290505b92915050565b60006104fc60ff8416836107bf565b808202811582820484141761085c5761085c610766565b6000826108a557634e487b7160e01b600052601260045260246000fd5b500490565b6000602082840312156108bc57600080fd5b815180151581146104fc57600080fd5b60005b838110156108e75781810151838201526020016108cf565b50506000910152565b600082516109028184602087016108cc565b9190910192915050565b602081526000825180602084015261092b8160408501602087016108cc565b601f01601f1916919091016040019291505056fea2646970667358221220d8804e87302a897896dba24924337055b9ee611900e6eb8ec708760c19a4a3b664736f6c63430008140033";

export class ScenarioDEX__factory extends ContractFactory {
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
  ): Promise<ScenarioDEX> {
    return super.deploy(overrides || {}) as Promise<ScenarioDEX>;
  }
  getDeployTransaction(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): ScenarioDEX {
    return super.attach(address) as ScenarioDEX;
  }
  connect(signer: Signer): ScenarioDEX__factory {
    return super.connect(signer) as ScenarioDEX__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): ScenarioDEXInterface {
    return new utils.Interface(_abi) as ScenarioDEXInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): ScenarioDEX {
    return new Contract(address, _abi, signerOrProvider) as ScenarioDEX;
  }
}
