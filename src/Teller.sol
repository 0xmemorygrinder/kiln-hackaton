// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Initializable} from "solady/utils/Initializable.sol";
import {ERC20} from "solady/tokens/ERC20.sol";
import {IOFT, SendParam, MessagingFee} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {IMetaVault} from "./interfaces/IMetaVault.sol";
import {AAccessControl} from "./utils/AAccessControl.sol";
import {Accountant} from "./Accountant.sol";

contract Teller is AAccessControl, Initializable {
    function init(address definitiveAccessControl) external initializer {
        _initAAccessControl(definitiveAccessControl);
    }

    /****************************************************
     *                 USER FUNCTIONS                    *
     ****************************************************/

    function deposit(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        address metaVault = getMetaVault();
        uint256 mintAmount = Accountant(getAccountant()).mint(asset, amount);
        IMetaVault(metaVault).deposit(asset, mintAmount, amount, msg.sender, to);

        return mintAmount;
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        address metaVault = getMetaVault();
        uint256 transferAmount = Accountant(getAccountant()).burn(
            asset,
            amount
        );
        IMetaVault(metaVault).withdraw(asset, amount, transferAmount, msg.sender, to);

        return transferAmount;
    }

    function depositAndBridge(
        address asset,
        uint256 amount,
        address to,
        SendParam memory sendParam,
        MessagingFee memory fee
    ) external payable returns (uint256) {
        address metaVault = getMetaVault();
        uint256 mintAmount = Accountant(getAccountant()).mint(asset, amount);
        IMetaVault(metaVault).deposit(
            asset,
            mintAmount,
            amount,
            msg.sender,
            address(this)
        );

        sendParam.amountLD = mintAmount;

        IOFT(metaVault).send{ value: msg.value }(
            sendParam,
            fee,
            to
        );

        return mintAmount;
    }

    function bridge(
      SendParam memory sendParam,
      MessagingFee memory fee
    ) external payable {
        IOFT(getMetaVault()).send{ value: msg.value }(
            sendParam,
            fee,
            msg.sender
        );
    }

    /****************************************************
     *                 VIEW FUNCTIONS                    *
     ****************************************************/

    function quoteMint(
        address asset,
        uint256 amount
    ) external view returns (uint256) {
        return Accountant(getAccountant()).quoteMint(asset, amount);
    }

    function quoteBurn(
        address asset,
        uint256 amount
    ) external view returns (uint256) {
        return Accountant(getAccountant()).quoteBurn(asset, amount);
    }
}
