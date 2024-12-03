// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IConnector {
    /// @notice Core actions that a protocol can perform
    enum ActionType {
        SUPPLY, // Supply assets
        WITHDRAW, // Withdraw assets
        BORROW, // Borrow assets
        REPAY, // Repay debt
        STAKE, // Stake assets
        UNSTAKE, // Unstake assets
        SWAP, // Swap assets
        CLAIM // Claim rewards

    }

    enum ConnectorType {
        LENDING,
        DEX,
        YIELD
    }

    function getConnectorName() external view returns (bytes32);
    function getConnectorType() external view returns (ConnectorType);
    /// @notice Standard action execution interface
    function execute(ActionType actionType, bytes calldata data) external payable returns (bytes memory result);
}