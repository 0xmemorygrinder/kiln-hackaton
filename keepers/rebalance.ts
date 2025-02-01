import { createWalletClient, erc20Abi, http, publicActions, zeroAddress } from 'viem'
import { privateKeyToAccount } from 'viem/accounts'
import { mainnet } from 'viem/chains'
import 'dotenv/config'

const MetaVaultAbi = [
    {
        "type": "function",
        "name": "SEND",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "uint16",
                "internalType": "uint16"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "SEND_AND_CALL",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "uint16",
                "internalType": "uint16"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "accessControl",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "addStrategy",
        "inputs": [
            {
                "name": "strategy",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "allowInitializePath",
        "inputs": [
            {
                "name": "origin",
                "type": "tuple",
                "internalType": "struct Origin",
                "components": [
                    {
                        "name": "srcEid",
                        "type": "uint32",
                        "internalType": "uint32"
                    },
                    {
                        "name": "sender",
                        "type": "bytes32",
                        "internalType": "bytes32"
                    },
                    {
                        "name": "nonce",
                        "type": "uint64",
                        "internalType": "uint64"
                    }
                ]
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "allowance",
        "inputs": [
            {
                "name": "owner",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "spender",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "approvalRequired",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "stateMutability": "pure"
    },
    {
        "type": "function",
        "name": "approve",
        "inputs": [
            {
                "name": "spender",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "value",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "assetsRevenueSharings",
        "inputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "outputs": [
            {
                "name": "recipient",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "weight",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "balanceOf",
        "inputs": [
            {
                "name": "account",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "combineOptions",
        "inputs": [
            {
                "name": "_eid",
                "type": "uint32",
                "internalType": "uint32"
            },
            {
                "name": "_msgType",
                "type": "uint16",
                "internalType": "uint16"
            },
            {
                "name": "_extraOptions",
                "type": "bytes",
                "internalType": "bytes"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "bytes",
                "internalType": "bytes"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "decimalConversionRate",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "decimals",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "uint8",
                "internalType": "uint8"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "decimalsNumber",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "uint8",
                "internalType": "uint8"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "deposit",
        "inputs": [
            {
                "name": "asset",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "mintAmount",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "amount",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "from",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "to",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "depositedAssets",
        "inputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "depositedAssetsByStrategy",
        "inputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "endpoint",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "contract ILayerZeroEndpointV2"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "enforcedOptions",
        "inputs": [
            {
                "name": "_eid",
                "type": "uint32",
                "internalType": "uint32"
            },
            {
                "name": "_msgType",
                "type": "uint16",
                "internalType": "uint16"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "bytes",
                "internalType": "bytes"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getAccountant",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getMetaVault",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getOwner",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "getTeller",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "init",
        "inputs": [
            {
                "name": "_accessControl",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_strategiesRegistry",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_lzEndpoint",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_name",
                "type": "string",
                "internalType": "string"
            },
            {
                "name": "_symbol",
                "type": "string",
                "internalType": "string"
            },
            {
                "name": "_decimals",
                "type": "uint8",
                "internalType": "uint8"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "isComposeMsgSender",
        "inputs": [
            {
                "name": "",
                "type": "tuple",
                "internalType": "struct Origin",
                "components": [
                    {
                        "name": "srcEid",
                        "type": "uint32",
                        "internalType": "uint32"
                    },
                    {
                        "name": "sender",
                        "type": "bytes32",
                        "internalType": "bytes32"
                    },
                    {
                        "name": "nonce",
                        "type": "uint64",
                        "internalType": "uint64"
                    }
                ]
            },
            {
                "name": "",
                "type": "bytes",
                "internalType": "bytes"
            },
            {
                "name": "_sender",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "isPeer",
        "inputs": [
            {
                "name": "_eid",
                "type": "uint32",
                "internalType": "uint32"
            },
            {
                "name": "_peer",
                "type": "bytes32",
                "internalType": "bytes32"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "isStrategy",
        "inputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "lzReceive",
        "inputs": [
            {
                "name": "_origin",
                "type": "tuple",
                "internalType": "struct Origin",
                "components": [
                    {
                        "name": "srcEid",
                        "type": "uint32",
                        "internalType": "uint32"
                    },
                    {
                        "name": "sender",
                        "type": "bytes32",
                        "internalType": "bytes32"
                    },
                    {
                        "name": "nonce",
                        "type": "uint64",
                        "internalType": "uint64"
                    }
                ]
            },
            {
                "name": "_guid",
                "type": "bytes32",
                "internalType": "bytes32"
            },
            {
                "name": "_message",
                "type": "bytes",
                "internalType": "bytes"
            },
            {
                "name": "_executor",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_extraData",
                "type": "bytes",
                "internalType": "bytes"
            }
        ],
        "outputs": [],
        "stateMutability": "payable"
    },
    {
        "type": "function",
        "name": "lzReceiveAndRevert",
        "inputs": [
            {
                "name": "_packets",
                "type": "tuple[]",
                "internalType": "struct InboundPacket[]",
                "components": [
                    {
                        "name": "origin",
                        "type": "tuple",
                        "internalType": "struct Origin",
                        "components": [
                            {
                                "name": "srcEid",
                                "type": "uint32",
                                "internalType": "uint32"
                            },
                            {
                                "name": "sender",
                                "type": "bytes32",
                                "internalType": "bytes32"
                            },
                            {
                                "name": "nonce",
                                "type": "uint64",
                                "internalType": "uint64"
                            }
                        ]
                    },
                    {
                        "name": "dstEid",
                        "type": "uint32",
                        "internalType": "uint32"
                    },
                    {
                        "name": "receiver",
                        "type": "address",
                        "internalType": "address"
                    },
                    {
                        "name": "guid",
                        "type": "bytes32",
                        "internalType": "bytes32"
                    },
                    {
                        "name": "value",
                        "type": "uint256",
                        "internalType": "uint256"
                    },
                    {
                        "name": "executor",
                        "type": "address",
                        "internalType": "address"
                    },
                    {
                        "name": "message",
                        "type": "bytes",
                        "internalType": "bytes"
                    },
                    {
                        "name": "extraData",
                        "type": "bytes",
                        "internalType": "bytes"
                    }
                ]
            }
        ],
        "outputs": [],
        "stateMutability": "payable"
    },
    {
        "type": "function",
        "name": "lzReceiveSimulate",
        "inputs": [
            {
                "name": "_origin",
                "type": "tuple",
                "internalType": "struct Origin",
                "components": [
                    {
                        "name": "srcEid",
                        "type": "uint32",
                        "internalType": "uint32"
                    },
                    {
                        "name": "sender",
                        "type": "bytes32",
                        "internalType": "bytes32"
                    },
                    {
                        "name": "nonce",
                        "type": "uint64",
                        "internalType": "uint64"
                    }
                ]
            },
            {
                "name": "_guid",
                "type": "bytes32",
                "internalType": "bytes32"
            },
            {
                "name": "_message",
                "type": "bytes",
                "internalType": "bytes"
            },
            {
                "name": "_executor",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "_extraData",
                "type": "bytes",
                "internalType": "bytes"
            }
        ],
        "outputs": [],
        "stateMutability": "payable"
    },
    {
        "type": "function",
        "name": "msgInspector",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "name",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "string",
                "internalType": "string"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "nextNonce",
        "inputs": [
            {
                "name": "",
                "type": "uint32",
                "internalType": "uint32"
            },
            {
                "name": "",
                "type": "bytes32",
                "internalType": "bytes32"
            }
        ],
        "outputs": [
            {
                "name": "nonce",
                "type": "uint64",
                "internalType": "uint64"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "oApp",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "oAppVersion",
        "inputs": [],
        "outputs": [
            {
                "name": "senderVersion",
                "type": "uint64",
                "internalType": "uint64"
            },
            {
                "name": "receiverVersion",
                "type": "uint64",
                "internalType": "uint64"
            }
        ],
        "stateMutability": "pure"
    },
    {
        "type": "function",
        "name": "oftVersion",
        "inputs": [],
        "outputs": [
            {
                "name": "interfaceId",
                "type": "bytes4",
                "internalType": "bytes4"
            },
            {
                "name": "version",
                "type": "uint64",
                "internalType": "uint64"
            }
        ],
        "stateMutability": "pure"
    },
    {
        "type": "function",
        "name": "owner",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "peers",
        "inputs": [
            {
                "name": "_eid",
                "type": "uint32",
                "internalType": "uint32"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "bytes32",
                "internalType": "bytes32"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "preCrime",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "profits",
        "inputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "quoteOFT",
        "inputs": [
            {
                "name": "_sendParam",
                "type": "tuple",
                "internalType": "struct SendParam",
                "components": [
                    {
                        "name": "dstEid",
                        "type": "uint32",
                        "internalType": "uint32"
                    },
                    {
                        "name": "to",
                        "type": "bytes32",
                        "internalType": "bytes32"
                    },
                    {
                        "name": "amountLD",
                        "type": "uint256",
                        "internalType": "uint256"
                    },
                    {
                        "name": "minAmountLD",
                        "type": "uint256",
                        "internalType": "uint256"
                    },
                    {
                        "name": "extraOptions",
                        "type": "bytes",
                        "internalType": "bytes"
                    },
                    {
                        "name": "composeMsg",
                        "type": "bytes",
                        "internalType": "bytes"
                    },
                    {
                        "name": "oftCmd",
                        "type": "bytes",
                        "internalType": "bytes"
                    }
                ]
            }
        ],
        "outputs": [
            {
                "name": "oftLimit",
                "type": "tuple",
                "internalType": "struct OFTLimit",
                "components": [
                    {
                        "name": "minAmountLD",
                        "type": "uint256",
                        "internalType": "uint256"
                    },
                    {
                        "name": "maxAmountLD",
                        "type": "uint256",
                        "internalType": "uint256"
                    }
                ]
            },
            {
                "name": "oftFeeDetails",
                "type": "tuple[]",
                "internalType": "struct OFTFeeDetail[]",
                "components": [
                    {
                        "name": "feeAmountLD",
                        "type": "int256",
                        "internalType": "int256"
                    },
                    {
                        "name": "description",
                        "type": "string",
                        "internalType": "string"
                    }
                ]
            },
            {
                "name": "oftReceipt",
                "type": "tuple",
                "internalType": "struct OFTReceipt",
                "components": [
                    {
                        "name": "amountSentLD",
                        "type": "uint256",
                        "internalType": "uint256"
                    },
                    {
                        "name": "amountReceivedLD",
                        "type": "uint256",
                        "internalType": "uint256"
                    }
                ]
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "quoteSend",
        "inputs": [
            {
                "name": "_sendParam",
                "type": "tuple",
                "internalType": "struct SendParam",
                "components": [
                    {
                        "name": "dstEid",
                        "type": "uint32",
                        "internalType": "uint32"
                    },
                    {
                        "name": "to",
                        "type": "bytes32",
                        "internalType": "bytes32"
                    },
                    {
                        "name": "amountLD",
                        "type": "uint256",
                        "internalType": "uint256"
                    },
                    {
                        "name": "minAmountLD",
                        "type": "uint256",
                        "internalType": "uint256"
                    },
                    {
                        "name": "extraOptions",
                        "type": "bytes",
                        "internalType": "bytes"
                    },
                    {
                        "name": "composeMsg",
                        "type": "bytes",
                        "internalType": "bytes"
                    },
                    {
                        "name": "oftCmd",
                        "type": "bytes",
                        "internalType": "bytes"
                    }
                ]
            },
            {
                "name": "_payInLzToken",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "outputs": [
            {
                "name": "msgFee",
                "type": "tuple",
                "internalType": "struct MessagingFee",
                "components": [
                    {
                        "name": "nativeFee",
                        "type": "uint256",
                        "internalType": "uint256"
                    },
                    {
                        "name": "lzTokenFee",
                        "type": "uint256",
                        "internalType": "uint256"
                    }
                ]
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "rebalance",
        "inputs": [
            {
                "name": "from",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "to",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "amount",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "outputs": [
            {
                "name": "depositedShares",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "renounceOwnership",
        "inputs": [],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "send",
        "inputs": [
            {
                "name": "_sendParam",
                "type": "tuple",
                "internalType": "struct SendParam",
                "components": [
                    {
                        "name": "dstEid",
                        "type": "uint32",
                        "internalType": "uint32"
                    },
                    {
                        "name": "to",
                        "type": "bytes32",
                        "internalType": "bytes32"
                    },
                    {
                        "name": "amountLD",
                        "type": "uint256",
                        "internalType": "uint256"
                    },
                    {
                        "name": "minAmountLD",
                        "type": "uint256",
                        "internalType": "uint256"
                    },
                    {
                        "name": "extraOptions",
                        "type": "bytes",
                        "internalType": "bytes"
                    },
                    {
                        "name": "composeMsg",
                        "type": "bytes",
                        "internalType": "bytes"
                    },
                    {
                        "name": "oftCmd",
                        "type": "bytes",
                        "internalType": "bytes"
                    }
                ]
            },
            {
                "name": "_fee",
                "type": "tuple",
                "internalType": "struct MessagingFee",
                "components": [
                    {
                        "name": "nativeFee",
                        "type": "uint256",
                        "internalType": "uint256"
                    },
                    {
                        "name": "lzTokenFee",
                        "type": "uint256",
                        "internalType": "uint256"
                    }
                ]
            },
            {
                "name": "_refundAddress",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "msgReceipt",
                "type": "tuple",
                "internalType": "struct MessagingReceipt",
                "components": [
                    {
                        "name": "guid",
                        "type": "bytes32",
                        "internalType": "bytes32"
                    },
                    {
                        "name": "nonce",
                        "type": "uint64",
                        "internalType": "uint64"
                    },
                    {
                        "name": "fee",
                        "type": "tuple",
                        "internalType": "struct MessagingFee",
                        "components": [
                            {
                                "name": "nativeFee",
                                "type": "uint256",
                                "internalType": "uint256"
                            },
                            {
                                "name": "lzTokenFee",
                                "type": "uint256",
                                "internalType": "uint256"
                            }
                        ]
                    }
                ]
            },
            {
                "name": "oftReceipt",
                "type": "tuple",
                "internalType": "struct OFTReceipt",
                "components": [
                    {
                        "name": "amountSentLD",
                        "type": "uint256",
                        "internalType": "uint256"
                    },
                    {
                        "name": "amountReceivedLD",
                        "type": "uint256",
                        "internalType": "uint256"
                    }
                ]
            }
        ],
        "stateMutability": "payable"
    },
    {
        "type": "function",
        "name": "setAssetBuffer",
        "inputs": [
            {
                "name": "asset",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "buffer",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "setDelegate",
        "inputs": [
            {
                "name": "_delegate",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "setEnforcedOptions",
        "inputs": [
            {
                "name": "_enforcedOptions",
                "type": "tuple[]",
                "internalType": "struct EnforcedOptionParam[]",
                "components": [
                    {
                        "name": "eid",
                        "type": "uint32",
                        "internalType": "uint32"
                    },
                    {
                        "name": "msgType",
                        "type": "uint16",
                        "internalType": "uint16"
                    },
                    {
                        "name": "options",
                        "type": "bytes",
                        "internalType": "bytes"
                    }
                ]
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "setMsgInspector",
        "inputs": [
            {
                "name": "_msgInspector",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "setPeer",
        "inputs": [
            {
                "name": "_eid",
                "type": "uint32",
                "internalType": "uint32"
            },
            {
                "name": "_peer",
                "type": "bytes32",
                "internalType": "bytes32"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "setPreCrime",
        "inputs": [
            {
                "name": "_preCrime",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "setRevenueSharings",
        "inputs": [
            {
                "name": "asset",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "newRevenueSharings",
                "type": "tuple[]",
                "internalType": "struct IMetaVault.RevenueSharing[]",
                "components": [
                    {
                        "name": "recipient",
                        "type": "address",
                        "internalType": "address"
                    },
                    {
                        "name": "weight",
                        "type": "uint256",
                        "internalType": "uint256"
                    }
                ]
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "setStrategyBounds",
        "inputs": [
            {
                "name": "strategy",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "lower",
                "type": "uint128",
                "internalType": "uint128"
            },
            {
                "name": "upper",
                "type": "uint128",
                "internalType": "uint128"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "shareRevenue",
        "inputs": [
            {
                "name": "asset",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "shareRevenues",
        "inputs": [
            {
                "name": "assets",
                "type": "address[]",
                "internalType": "address[]"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "sharedDecimals",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "uint8",
                "internalType": "uint8"
            }
        ],
        "stateMutability": "pure"
    },
    {
        "type": "function",
        "name": "strategies",
        "inputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "strategiesAssets",
        "inputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "strategiesAssetsBuffers",
        "inputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "strategiesBounds",
        "inputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [
            {
                "name": "lower",
                "type": "uint128",
                "internalType": "uint128"
            },
            {
                "name": "upper",
                "type": "uint128",
                "internalType": "uint128"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "strategiesRegistry",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "symbol",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "string",
                "internalType": "string"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "token",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "address",
                "internalType": "address"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "totalSupply",
        "inputs": [],
        "outputs": [
            {
                "name": "",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "stateMutability": "view"
    },
    {
        "type": "function",
        "name": "transfer",
        "inputs": [
            {
                "name": "to",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "value",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "transferFrom",
        "inputs": [
            {
                "name": "from",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "to",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "value",
                "type": "uint256",
                "internalType": "uint256"
            }
        ],
        "outputs": [
            {
                "name": "",
                "type": "bool",
                "internalType": "bool"
            }
        ],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "transferOwnership",
        "inputs": [
            {
                "name": "newOwner",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "function",
        "name": "withdraw",
        "inputs": [
            {
                "name": "asset",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "burnAmount",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "transferAmount",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "from",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "to",
                "type": "address",
                "internalType": "address"
            }
        ],
        "outputs": [],
        "stateMutability": "nonpayable"
    },
    {
        "type": "event",
        "name": "Approval",
        "inputs": [
            {
                "name": "owner",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "spender",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "value",
                "type": "uint256",
                "indexed": false,
                "internalType": "uint256"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "EnforcedOptionSet",
        "inputs": [
            {
                "name": "_enforcedOptions",
                "type": "tuple[]",
                "indexed": false,
                "internalType": "struct EnforcedOptionParam[]",
                "components": [
                    {
                        "name": "eid",
                        "type": "uint32",
                        "internalType": "uint32"
                    },
                    {
                        "name": "msgType",
                        "type": "uint16",
                        "internalType": "uint16"
                    },
                    {
                        "name": "options",
                        "type": "bytes",
                        "internalType": "bytes"
                    }
                ]
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "Initialized",
        "inputs": [
            {
                "name": "version",
                "type": "uint64",
                "indexed": false,
                "internalType": "uint64"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "MsgInspectorSet",
        "inputs": [
            {
                "name": "inspector",
                "type": "address",
                "indexed": false,
                "internalType": "address"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "OFTReceived",
        "inputs": [
            {
                "name": "guid",
                "type": "bytes32",
                "indexed": true,
                "internalType": "bytes32"
            },
            {
                "name": "srcEid",
                "type": "uint32",
                "indexed": false,
                "internalType": "uint32"
            },
            {
                "name": "toAddress",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "amountReceivedLD",
                "type": "uint256",
                "indexed": false,
                "internalType": "uint256"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "OFTSent",
        "inputs": [
            {
                "name": "guid",
                "type": "bytes32",
                "indexed": true,
                "internalType": "bytes32"
            },
            {
                "name": "dstEid",
                "type": "uint32",
                "indexed": false,
                "internalType": "uint32"
            },
            {
                "name": "fromAddress",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "amountSentLD",
                "type": "uint256",
                "indexed": false,
                "internalType": "uint256"
            },
            {
                "name": "amountReceivedLD",
                "type": "uint256",
                "indexed": false,
                "internalType": "uint256"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "OwnershipTransferred",
        "inputs": [
            {
                "name": "previousOwner",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "newOwner",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "PeerSet",
        "inputs": [
            {
                "name": "eid",
                "type": "uint32",
                "indexed": false,
                "internalType": "uint32"
            },
            {
                "name": "peer",
                "type": "bytes32",
                "indexed": false,
                "internalType": "bytes32"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "PreCrimeSet",
        "inputs": [
            {
                "name": "preCrimeAddress",
                "type": "address",
                "indexed": false,
                "internalType": "address"
            }
        ],
        "anonymous": false
    },
    {
        "type": "event",
        "name": "Transfer",
        "inputs": [
            {
                "name": "from",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "to",
                "type": "address",
                "indexed": true,
                "internalType": "address"
            },
            {
                "name": "value",
                "type": "uint256",
                "indexed": false,
                "internalType": "uint256"
            }
        ],
        "anonymous": false
    },
    {
        "type": "error",
        "name": "ERC20InsufficientAllowance",
        "inputs": [
            {
                "name": "spender",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "allowance",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "needed",
                "type": "uint256",
                "internalType": "uint256"
            }
        ]
    },
    {
        "type": "error",
        "name": "ERC20InsufficientBalance",
        "inputs": [
            {
                "name": "sender",
                "type": "address",
                "internalType": "address"
            },
            {
                "name": "balance",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "needed",
                "type": "uint256",
                "internalType": "uint256"
            }
        ]
    },
    {
        "type": "error",
        "name": "ERC20InvalidApprover",
        "inputs": [
            {
                "name": "approver",
                "type": "address",
                "internalType": "address"
            }
        ]
    },
    {
        "type": "error",
        "name": "ERC20InvalidReceiver",
        "inputs": [
            {
                "name": "receiver",
                "type": "address",
                "internalType": "address"
            }
        ]
    },
    {
        "type": "error",
        "name": "ERC20InvalidSender",
        "inputs": [
            {
                "name": "sender",
                "type": "address",
                "internalType": "address"
            }
        ]
    },
    {
        "type": "error",
        "name": "ERC20InvalidSpender",
        "inputs": [
            {
                "name": "spender",
                "type": "address",
                "internalType": "address"
            }
        ]
    },
    {
        "type": "error",
        "name": "InvalidDelegate",
        "inputs": []
    },
    {
        "type": "error",
        "name": "InvalidEndpointCall",
        "inputs": []
    },
    {
        "type": "error",
        "name": "InvalidInitialization",
        "inputs": []
    },
    {
        "type": "error",
        "name": "InvalidLocalDecimals",
        "inputs": []
    },
    {
        "type": "error",
        "name": "InvalidOptions",
        "inputs": [
            {
                "name": "options",
                "type": "bytes",
                "internalType": "bytes"
            }
        ]
    },
    {
        "type": "error",
        "name": "InvalidRebalance",
        "inputs": []
    },
    {
        "type": "error",
        "name": "InvalidRevenueSharing",
        "inputs": []
    },
    {
        "type": "error",
        "name": "InvalidStrategy",
        "inputs": [
            {
                "name": "strategy",
                "type": "address",
                "internalType": "address"
            }
        ]
    },
    {
        "type": "error",
        "name": "LzTokenUnavailable",
        "inputs": []
    },
    {
        "type": "error",
        "name": "NoPeer",
        "inputs": [
            {
                "name": "eid",
                "type": "uint32",
                "internalType": "uint32"
            }
        ]
    },
    {
        "type": "error",
        "name": "NotEnoughNative",
        "inputs": [
            {
                "name": "msgValue",
                "type": "uint256",
                "internalType": "uint256"
            }
        ]
    },
    {
        "type": "error",
        "name": "NotInitializing",
        "inputs": []
    },
    {
        "type": "error",
        "name": "OnlyEndpoint",
        "inputs": [
            {
                "name": "addr",
                "type": "address",
                "internalType": "address"
            }
        ]
    },
    {
        "type": "error",
        "name": "OnlyPeer",
        "inputs": [
            {
                "name": "eid",
                "type": "uint32",
                "internalType": "uint32"
            },
            {
                "name": "sender",
                "type": "bytes32",
                "internalType": "bytes32"
            }
        ]
    },
    {
        "type": "error",
        "name": "OnlySelf",
        "inputs": []
    },
    {
        "type": "error",
        "name": "OwnableInvalidOwner",
        "inputs": [
            {
                "name": "owner",
                "type": "address",
                "internalType": "address"
            }
        ]
    },
    {
        "type": "error",
        "name": "OwnableUnauthorizedAccount",
        "inputs": [
            {
                "name": "account",
                "type": "address",
                "internalType": "address"
            }
        ]
    },
    {
        "type": "error",
        "name": "SafeERC20FailedOperation",
        "inputs": [
            {
                "name": "token",
                "type": "address",
                "internalType": "address"
            }
        ]
    },
    {
        "type": "error",
        "name": "SimulationResult",
        "inputs": [
            {
                "name": "result",
                "type": "bytes",
                "internalType": "bytes"
            }
        ]
    },
    {
        "type": "error",
        "name": "SlippageExceeded",
        "inputs": [
            {
                "name": "amountLD",
                "type": "uint256",
                "internalType": "uint256"
            },
            {
                "name": "minAmountLD",
                "type": "uint256",
                "internalType": "uint256"
            }
        ]
    },
    {
        "type": "error",
        "name": "Unauthorized",
        "inputs": []
    },
    {
        "type": "error",
        "name": "UnauthorizedAccess",
        "inputs": []
    }
] as const;
export const metaVaultAddress = "0x8a5005c342893C8E70387ff9ED5D8e9F8c5E5bBA";

const config: { [key: string]: string[] } = {
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48": [
        "0x2db0B0fa84C3c8B342183FD0B777C521ec054325",
        "0x50913b45F278c39c8A7925b3C31DD88B95fb1AA2"
    ],
    "0xdAC17F958D2ee523a2206206994597C13D831ec7": [
        "0x924e38bdFDa04990Fc78FEc258E8B83B3478B1Af",
        "0x75e4cE661A49B6bfb2d5b1a8231E32aB47F8b706"
    ]
};
const BPS = 10000n;

(async () => {
    if (!process.env.PRIVATE_KEY) {
        throw new Error('PRIVATE_KEY is required')
    }

    const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`)
 
    const client = createWalletClient({ 
      account,
      chain: mainnet,
      transport: http()
    }).extend(publicActions);

    for (const collateral in config) {
        const strategies = config[collateral];
        const collateralBalance = await client.readContract({
            address: collateral as `0x${string}`,
            functionName: 'balanceOf',
            abi: erc20Abi,
            args: [metaVaultAddress ]
        });
        const buffer = await client.readContract({
            address: metaVaultAddress as `0x${string}`,
            functionName: 'strategiesAssetsBuffers',
            abi: MetaVaultAbi,
            args: [collateral as `0x${string}`]
        });
        let totalStrategyBalance = 0n;
        for (const strategy of strategies) {
            const strategyBalance = await client.readContract({
                address: metaVaultAddress as `0x${string}`,
                functionName: 'depositedAssetsByStrategy',
                abi: MetaVaultAbi,
                args: [collateral as `0x${string}`, strategy as `0x${string}`]
            });
            totalStrategyBalance += strategyBalance;
        }


        // Mock apy of the yield strategies
        let bestStrategy;
        if (collateral == "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48") {
            bestStrategy = "0x2db0B0fa84C3c8B342183FD0B777C521ec054325";
        } else {
            bestStrategy = "0x924e38bdFDa04990Fc78FEc258E8B83B3478B1Af"
        }

        // Compute % of the buffer(collateralBalance) out of the totalStrategyBalance + buffer
        const totalBalance = totalStrategyBalance + BigInt(collateralBalance);
        const bufferShare = (BigInt(collateralBalance) * BPS) / totalBalance;

        if (bufferShare < buffer) {
            const withdrawAmount = totalBalance * buffer / BPS;
            await client.writeContract({
                address: metaVaultAddress as `0x${string}`,
                functionName: 'rebalance',
                abi: MetaVaultAbi,
                args: [bestStrategy as `0x${string}`, zeroAddress, withdrawAmount]
            });
        } else {
            // compute the amount to deposit while maintaining the buffer
            const toDepositAmount = totalBalance * (BPS - buffer) / BPS;
            await client.writeContract({
                address: metaVaultAddress as `0x${string}`,
                functionName: 'rebalance',
                abi: MetaVaultAbi,
                args: [zeroAddress, bestStrategy as `0x${string}`, toDepositAmount]
            });
        }
    }
})();