// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.28;

import {Ownable} from "solady/auth/Ownable.sol";

/// @title StrategiesRegistry contract
/// @notice Contract to manage the available strategies on the MetaVault (kiln vaults)
/// @author 0xmemorygrinder
contract StrategiesRegistry is Ownable {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Event emitted when a new strategy is marked as valid
     */
    event StrategyAdded(address strategy);

    /**
     * @notice Event emitted when a strategy is marked as invalid
     */
    event StrategyRemoved(address strategy);

    /*//////////////////////////////////////////////////////////////
                          MUTABLE VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(address => bool) public isValidStrategy;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _initializeOwner(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                          OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Change a strategy status to valid or invalid
     * @dev Multiple calls to this function will overwrite the previous status
     * @param _strategy Address of the strategy to change status
     * @param _isValid New status of the strategy
     */
    function setStrategyStatus(address _strategy, bool _isValid) public onlyOwner {
        isValidStrategy[_strategy] = _isValid;
        if (_isValid) emit StrategyAdded(_strategy);
        else emit StrategyRemoved(_strategy);
    }

    /**
     * @notice Change multiple strategies status to valid or invalid
     * @dev Multiple calls to this function will overwrite the previous status
     * @param _strategies Array of strategies to change status
     * @param _isValid New status of the strategies
     */
    function setStrategiesStatus(address[] calldata _strategies, bool _isValid) external onlyOwner {
        for (uint256 i = 0; i < _strategies.length; i++) {
            setStrategyStatus(_strategies[i], _isValid);
        }
    }
}
