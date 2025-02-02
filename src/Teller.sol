// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Initializable} from "solady/utils/Initializable.sol";
import {ERC20} from "solady/tokens/ERC20.sol";
import {IOFT, SendParam, MessagingFee} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import {IMetaVault} from "./interfaces/IMetaVault.sol";
import {AAccessControl} from "./utils/AAccessControl.sol";
import {Accountant} from "./Accountant.sol";

/// @title Teller
/// @notice This contract is responsible for handling deposits and withdrawals of assets as well as bridging assets to other chains
/// @author 0xMemoryGrinder
contract Teller is AAccessControl, Initializable {
    /****************************************************
     *                   INITIALIZER                    *
     ****************************************************/

    /**
     * @notice Initializes the Teller contract
     * @param definitiveAccessControl The address of the AccessControl contract
     */
    function init(address definitiveAccessControl) external initializer {
        _initAAccessControl(definitiveAccessControl);
    }

    /****************************************************
     *                 USER FUNCTIONS                   *
     ****************************************************/

    /**
     * @notice Deposit assets into the MetaVault
     * @dev Updates the Accountant and mint on the MetaVault
     */
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

    /**
     * @notice Withdraw assets from the MetaVault
     * @dev Updates the Accountant and burn on the MetaVault
     */
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

    /**
     * @notice Deposit assets into the MetaVault and bridge them to another chain
     * @dev Updates the Accountant and mint on the MetaVault then bridges the minted tokens
     */
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

    /**
     * @notice Bridge assets from the MetaVault to another chain
     * @dev Proxy to MetaVault
     */
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

    /**
     * @notice Returns the amount of asset that will be minted when depositing `amount` of `asset`
     * @dev Proxy to Accountant  
     */
    function quoteMint(
        address asset,
        uint256 amount
    ) external view returns (uint256) {
        return Accountant(getAccountant()).quoteMint(asset, amount);
    }

    /**
     * @notice Returns the amount of asset that will be burned when withdrawing `amount` of `asset`
     * @dev Proxy to Accountant
     */
    function quoteBurn(
        address asset,
        uint256 amount
    ) external view returns (uint256) {
        return Accountant(getAccountant()).quoteBurn(asset, amount);
    }
}
