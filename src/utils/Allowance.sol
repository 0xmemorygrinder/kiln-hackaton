//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { ERC20 } from "solady/tokens/ERC20.sol";

library Allowance {
    /**
     * @notice Approve the router/aggregator to spend the token if needed
     * @param _token address of the token to approve
      * @param amount minimum allowance to check for
     * @param _spender address of the router/aggregator
     */
    function approveTokenIfNeeded(address _token, uint256 amount, address _spender) public {
        if (ERC20(_token).allowance(address(this), _spender) < amount) {
            SafeTransferLib.safeApprove(_token, _spender, type(uint256).max);
        }
    }
}