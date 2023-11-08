/* Autogenerated file. Do not edit manually. */

/* tslint:disable */

/* eslint-disable */
import type { Diamond, DiamondInterface } from "../Diamond";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import {
  Signer,
  utils,
  Contract,
  ContractFactory,
  PayableOverrides,
} from "ethers";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_contractOwner",
        type: "address",
      },
      {
        internalType: "address",
        name: "_diamondCutFacet",
        type: "address",
      },
    ],
    stateMutability: "payable",
    type: "constructor",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_initializationContractAddress",
        type: "address",
      },
      {
        internalType: "bytes",
        name: "_calldata",
        type: "bytes",
      },
    ],
    name: "InitializationFunctionReverted",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        components: [
          {
            internalType: "address",
            name: "facetAddress",
            type: "address",
          },
          {
            internalType: "enum IDiamondCut.FacetCutAction",
            name: "action",
            type: "uint8",
          },
          {
            internalType: "bytes4[]",
            name: "functionSelectors",
            type: "bytes4[]",
          },
        ],
        indexed: false,
        internalType: "struct IDiamondCut.FacetCut[]",
        name: "_diamondCut",
        type: "tuple[]",
      },
      {
        indexed: false,
        internalType: "address",
        name: "_init",
        type: "address",
      },
      {
        indexed: false,
        internalType: "bytes",
        name: "_calldata",
        type: "bytes",
      },
    ],
    name: "DiamondCut",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "previousOwner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "OwnershipTransferred",
    type: "event",
  },
  {
    stateMutability: "payable",
    type: "fallback",
  },
  {
    stateMutability: "payable",
    type: "receive",
  },
];

const _bytecode =
  "0x6080604052604051610f62380380610f6283398101604081905261002291610b69565b61002b82610136565b604080516001808252818301909252600091816020015b604080516060808201835260008083526020830152918101919091528152602001906001900390816100425750506040805160018082528183019092529192506000919060208083019080368337019050509050631f931c1c60e01b816000815181106100b1576100b1610b9c565b6001600160e01b031990921660209283029190910182015260408051606081019091526001600160a01b038516815290810160008152602001828152508260008151811061010157610101610b9c565b602002602001018190525061012d8260006040518060200160405280600081525061018c60201b60201c565b50505050610df0565b600480546001600160a01b031981166001600160a01b038481169182179093556040516000939092169182907f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0908590a3505050565b60025460009061ffff81169081908390600716156101bc5750600381901c60009081526001840160205260409020545b60005b875181101561023f5761023283838a84815181106101df576101df610b9c565b6020026020010151600001518b85815181106101fd576101fd610b9c565b6020026020010151602001518c868151811061021b5761021b610b9c565b6020026020010151604001516102cb60201b60201c565b90935091506001016101bf565b5082821461025b5760028401805461ffff191661ffff84161790555b600782161561027d57600382901c600090815260018501602052604090208190555b7f8faa70878671ccd212d20771b795c50af8fd3ff6cf27f4bde57e5d4de0aeb6738787876040516102b093929190610c18565b60405180910390a16102c28686610a60565b50505050505050565b6000808060008451116103395760405162461bcd60e51b815260206004820152602b60248201527f4c69624469616d6f6e644375743a204e6f2073656c6563746f727320696e206660448201526a1858d95d081d1bc818dd5d60aa1b60648201526084015b60405180910390fd5b600085600281111561034d5761034d610bb2565b036104bb5761037486604051806060016040528060248152602001610eee60249139610b2c565b60005b84518110156104b557600085828151811061039457610394610b9c565b6020908102919091018101516001600160e01b03198116600090815291859052604090912054909150606081901c156104355760405162461bcd60e51b815260206004820152603560248201527f4c69624469616d6f6e644375743a2043616e2774206164642066756e6374696f60448201527f6e207468617420616c72656164792065786973747300000000000000000000006064820152608401610330565b6001600160e01b031980831660008181526020879052604090206001600160601b031960608d901b168e17905560e060058e901b811692831c199c909c1690821c179a8190036104995760038c901c600090815260018601602052604081209b909b555b8b6104a381610d2e565b9c505060019093019250610377915050565b50610a54565b60018560028111156104cf576104cf610bb2565b036106cb576104f686604051806060016040528060288152602001610f3a60289139610b2c565b60005b84518110156104b557600085828151811061051657610516610b9c565b6020908102919091018101516001600160e01b03198116600090815291859052604090912054909150606081901c3081036105ab5760405162461bcd60e51b815260206004820152602f60248201527f4c69624469616d6f6e644375743a2043616e2774207265706c61636520696d6d60448201526e3aba30b1363290333ab731ba34b7b760891b6064820152608401610330565b896001600160a01b0316816001600160a01b0316036106205760405162461bcd60e51b81526020600482015260386024820152600080516020610ece83398151915260448201527f6374696f6e20776974682073616d652066756e6374696f6e00000000000000006064820152608401610330565b6001600160a01b03811661068a5760405162461bcd60e51b81526020600482015260386024820152600080516020610ece83398151915260448201527f6374696f6e207468617420646f65736e277420657869737400000000000000006064820152608401610330565b506001600160e01b031990911660009081526020849052604090206001600160601b03919091166001600160601b031960608a901b161790556001016104f9565b60028560028111156106df576106df610bb2565b036109fc576001600160a01b038616156107615760405162461bcd60e51b815260206004820152603660248201527f4c69624469616d6f6e644375743a2052656d6f7665206661636574206164647260448201527f657373206d7573742062652061646472657373283029000000000000000000006064820152608401610330565b600388901c6007891660005b86518110156109dc5760008a90036107a9578261078981610d47565b60008181526001870160205260409020549b509350600792506107b79050565b816107b381610d47565b9250505b6000806000808a85815181106107cf576107cf610b9c565b6020908102919091018101516001600160e01b031981166000908152918a9052604090912054909150606081901c61086f5760405162461bcd60e51b815260206004820152603760248201527f4c69624469616d6f6e644375743a2043616e27742072656d6f76652066756e6360448201527f74696f6e207468617420646f65736e27742065786973740000000000000000006064820152608401610330565b30606082901c036108d95760405162461bcd60e51b815260206004820152602e60248201527f4c69624469616d6f6e644375743a2043616e27742072656d6f766520696d6d7560448201526d3a30b1363290333ab731ba34b7b760911b6064820152608401610330565b600587901b8f901b94506001600160e01b03198086169083161461092a576001600160e01b03198516600090815260208a90526040902080546001600160601b0319166001600160601b0383161790555b6001600160e01b031991909116600090815260208990526040812055600381901c611fff16925060051b60e016905085821461098f576000828152600188016020526040902080546001600160e01b031980841c19909116908516831c1790556109b3565b80836001600160e01b031916901c816001600160e01b031960001b901c198e16179c505b846000036109d157600086815260018801602052604081208190559c505b50505060010161076d565b50806109e9836008610d5e565b6109f39190610d7b565b99505050610a54565b60405162461bcd60e51b815260206004820152602760248201527f4c69624469616d6f6e644375743a20496e636f727265637420466163657443756044820152663a20b1ba34b7b760c91b6064820152608401610330565b50959694955050505050565b6001600160a01b038216610a72575050565b610a9482604051806060016040528060288152602001610f1260289139610b2c565b600080836001600160a01b031683604051610aaf9190610d8e565b600060405180830381855af49150503d8060008114610aea576040519150601f19603f3d011682016040523d82523d6000602084013e610aef565b606091505b509150915081610b2657805115610b095780518082602001fd5b838360405163192105d760e01b8152600401610330929190610daa565b50505050565b813b8181610b265760405162461bcd60e51b81526004016103309190610dd6565b80516001600160a01b0381168114610b6457600080fd5b919050565b60008060408385031215610b7c57600080fd5b610b8583610b4d565b9150610b9360208401610b4d565b90509250929050565b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052602160045260246000fd5b60005b83811015610be3578181015183820152602001610bcb565b50506000910152565b60008151808452610c04816020860160208601610bc8565b601f01601f19169290920160200192915050565b60006060808301818452808751808352608092508286019150828160051b8701016020808b0160005b84811015610ce857898403607f19018652815180516001600160a01b03168552838101518986019060038110610c8757634e487b7160e01b600052602160045260246000fd5b868601526040918201519186018a905281519081905290840190600090898701905b80831015610cd35783516001600160e01b0319168252928601926001929092019190860190610ca9565b50978501979550505090820190600101610c41565b50506001600160a01b038a16908801528681036040880152610d0a8189610bec565b9a9950505050505050505050565b634e487b7160e01b600052601160045260246000fd5b600060018201610d4057610d40610d18565b5060010190565b600081610d5657610d56610d18565b506000190190565b8082028115828204841417610d7557610d75610d18565b92915050565b80820180821115610d7557610d75610d18565b60008251610da0818460208701610bc8565b9190910192915050565b6001600160a01b0383168152604060208201819052600090610dce90830184610bec565b949350505050565b602081526000610de96020830184610bec565b9392505050565b60d080610dfe6000396000f3fe608060405236600a57005b600080356001600160e01b03191681526020819052604081205460601c8060775760405162461bcd60e51b815260206004820181905260248201527f4469616d6f6e643a2046756e6374696f6e20646f6573206e6f74206578697374604482015260640160405180910390fd5b3660008037600080366000845af43d6000803e8080156095573d6000f35b3d6000fdfea2646970667358221220a4f6d71f20793e9d76eba86de110c0dd8168a86499ad6d5d80e83760ab74db5364736f6c634300081400334c69624469616d6f6e644375743a2043616e2774207265706c6163652066756e4c69624469616d6f6e644375743a2041646420666163657420686173206e6f20636f64654c69624469616d6f6e644375743a205f696e6974206164647265737320686173206e6f20636f64654c69624469616d6f6e644375743a205265706c61636520666163657420686173206e6f20636f6465";

export class Diamond__factory extends ContractFactory {
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
    _contractOwner: string,
    _diamondCutFacet: string,
    overrides?: PayableOverrides & { from?: string | Promise<string> }
  ): Promise<Diamond> {
    return super.deploy(
      _contractOwner,
      _diamondCutFacet,
      overrides || {}
    ) as Promise<Diamond>;
  }
  getDeployTransaction(
    _contractOwner: string,
    _diamondCutFacet: string,
    overrides?: PayableOverrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(
      _contractOwner,
      _diamondCutFacet,
      overrides || {}
    );
  }
  attach(address: string): Diamond {
    return super.attach(address) as Diamond;
  }
  connect(signer: Signer): Diamond__factory {
    return super.connect(signer) as Diamond__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): DiamondInterface {
    return new utils.Interface(_abi) as DiamondInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): Diamond {
    return new Contract(address, _abi, signerOrProvider) as Diamond;
  }
}
