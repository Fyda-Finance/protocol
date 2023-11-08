/* Autogenerated file. Do not edit manually. */

/* tslint:disable */

/* eslint-disable */
import type {
  DiamondLoupeFacet,
  DiamondLoupeFacetInterface,
} from "../DiamondLoupeFacet";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";

const _abi = [
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "_functionSelector",
        type: "bytes4",
      },
    ],
    name: "facetAddress",
    outputs: [
      {
        internalType: "address",
        name: "facetAddress_",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "facetAddresses",
    outputs: [
      {
        internalType: "address[]",
        name: "facetAddresses_",
        type: "address[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_facet",
        type: "address",
      },
    ],
    name: "facetFunctionSelectors",
    outputs: [
      {
        internalType: "bytes4[]",
        name: "_facetFunctionSelectors",
        type: "bytes4[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "facets",
    outputs: [
      {
        components: [
          {
            internalType: "address",
            name: "facetAddress",
            type: "address",
          },
          {
            internalType: "bytes4[]",
            name: "functionSelectors",
            type: "bytes4[]",
          },
        ],
        internalType: "struct IDiamondLoupe.Facet[]",
        name: "facets_",
        type: "tuple[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "_interfaceId",
        type: "bytes4",
      },
    ],
    name: "supportsInterface",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];

const _bytecode =
  "0x608060405234801561001057600080fd5b50610a5a806100206000396000f3fe608060405234801561001057600080fd5b50600436106100575760003560e01c806301ffc9a71461005c57806352ef6b2c1461009e5780637a0ed627146100b3578063adfca15e146100c8578063cdffacc6146100e8575b600080fd5b61008961006a36600461082c565b6001600160e01b03191660009081526003602052604090205460ff1690565b60405190151581526020015b60405180910390f35b6100a661012d565b604051610095919061085d565b6100bb6102c5565b60405161009591906108ef565b6100db6100d636600461096c565b6106e7565b6040516100959190610995565b6101156100f636600461082c565b6001600160e01b03191660009081526020819052604090205460601c90565b6040516001600160a01b039091168152602001610095565b60025460609060009061ffff1667ffffffffffffffff811115610152576101526109a8565b60405190808252806020026020018201604052801561017b578160200160208202803683370190505b50915060008060005b600284015461ffff168210156102bd576000818152600185016020526040812054905b60088110156102a857836101ba816109d4565b600288015490955061ffff16851190506102a857600581901b82901b6001600160e01b0319811660009081526020889052604081205460601c90805b8881101561024b578a8181518110610210576102106109ed565b60200260200101516001600160a01b0316836001600160a01b031603610239576001915061024b565b80610243816109d4565b9150506101f6565b50801561025a57505050610296565b818a898151811061026d5761026d6109ed565b6001600160a01b03909216602092830291909101909101528761028f816109d4565b9850505050505b806102a0816109d4565b9150506101a7565b505080806102b5906109d4565b915050610184565b505082525090565b60025460609060009061ffff1667ffffffffffffffff8111156102ea576102ea6109a8565b60405190808252806020026020018201604052801561033057816020015b6040805180820190915260008152606060208201528152602001906001900390816103085790505b50600282015490925060009061ffff1667ffffffffffffffff811115610358576103586109a8565b604051908082528060200260200182016040528015610381578160200160208202803683370190505b50905060008060005b600285015461ffff16821015610674576000818152600186016020526040812054905b600881101561065f57836103c0816109d4565b600289015490955061ffff168511905061065f57600581901b82901b6001600160e01b0319811660009081526020899052604081205460601c90805b8881101561051c57826001600160a01b03168c8281518110610420576104206109ed565b6020026020010151600001516001600160a01b03160361050a57838c828151811061044d5761044d6109ed565b6020026020010151602001518b838151811061046b5761046b6109ed565b602002602001015161ffff1681518110610487576104876109ed565b60200260200101906001600160e01b03191690816001600160e01b0319168152505060ff8a82815181106104bd576104bd6109ed565b602002602001015161ffff16106104d357600080fd5b8981815181106104e5576104e56109ed565b6020026020010180518091906104fa90610a03565b61ffff169052506001915061051c565b80610514816109d4565b9150506103fc565b50801561052b5750505061064d565b818b898151811061053e5761053e6109ed565b60209081029190910101516001600160a01b03909116905260028a015461ffff1667ffffffffffffffff811115610577576105776109a8565b6040519080825280602002602001820160405280156105a0578160200160208202803683370190505b508b89815181106105b3576105b36109ed565b602002602001015160200181905250828b89815181106105d5576105d56109ed565b6020026020010151602001516000815181106105f3576105f36109ed565b60200260200101906001600160e01b03191690816001600160e01b031916815250506001898981518110610629576106296109ed565b61ffff9092166020928302919091019091015287610646816109d4565b9850505050505b80610657816109d4565b9150506103ad565b5050808061066c906109d4565b91505061038a565b5060005b828110156106dc576000848281518110610694576106946109ed565b602002602001015161ffff16905060008783815181106106b6576106b66109ed565b6020026020010151602001519050818152505080806106d4906109d4565b915050610678565b508185525050505090565b600254606090600090819061ffff1667ffffffffffffffff81111561070e5761070e6109a8565b604051908082528060200260200182016040528015610737578160200160208202803683370190505b5092506000805b600284015461ffff16821015610822576000818152600185016020526040812054905b600881101561080d5783610774816109d4565b600288015490955061ffff168511905061080d57600581901b82901b6001600160e01b0319811660009081526020889052604090205460601c6001600160a01b038a168190036107f857818988815181106107d1576107d16109ed565b6001600160e01b031990921660209283029190910190910152866107f4816109d4565b9750505b50508080610805906109d4565b915050610761565b5050808061081a906109d4565b91505061073e565b5050825250919050565b60006020828403121561083e57600080fd5b81356001600160e01b03198116811461085657600080fd5b9392505050565b6020808252825182820181905260009190848201906040850190845b8181101561089e5783516001600160a01b031683529284019291840191600101610879565b50909695505050505050565b600081518084526020808501945080840160005b838110156108e45781516001600160e01b031916875295820195908201906001016108be565b509495945050505050565b60006020808301818452808551808352604092508286019150828160051b87010184880160005b8381101561095e57888303603f19018552815180516001600160a01b0316845287015187840187905261094b878501826108aa565b9588019593505090860190600101610916565b509098975050505050505050565b60006020828403121561097e57600080fd5b81356001600160a01b038116811461085657600080fd5b60208152600061085660208301846108aa565b634e487b7160e01b600052604160045260246000fd5b634e487b7160e01b600052601160045260246000fd5b6000600182016109e6576109e66109be565b5060010190565b634e487b7160e01b600052603260045260246000fd5b600061ffff808316818103610a1a57610a1a6109be565b600101939250505056fea26469706673582212205e2ebb0237bc69874f5e8d31ab946c083e9c269ea642058485446255c02c84a164736f6c63430008140033";

export class DiamondLoupeFacet__factory extends ContractFactory {
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
  ): Promise<DiamondLoupeFacet> {
    return super.deploy(overrides || {}) as Promise<DiamondLoupeFacet>;
  }
  getDeployTransaction(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(overrides || {});
  }
  attach(address: string): DiamondLoupeFacet {
    return super.attach(address) as DiamondLoupeFacet;
  }
  connect(signer: Signer): DiamondLoupeFacet__factory {
    return super.connect(signer) as DiamondLoupeFacet__factory;
  }
  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): DiamondLoupeFacetInterface {
    return new utils.Interface(_abi) as DiamondLoupeFacetInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): DiamondLoupeFacet {
    return new Contract(address, _abi, signerOrProvider) as DiamondLoupeFacet;
  }
}
