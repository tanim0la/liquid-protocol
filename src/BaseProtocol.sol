// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./interface/IProtocol.sol";

/**
 * @title BaseProtocol
 * @dev Abstract contract implementing basic protocol functionality.
 * This contract serves as a base for specific protocol implementations.
 */
abstract contract BaseProtocol is IProtocol {
    /// @notice Name of the protocol
    bytes32 public immutable protocolName;

    /// @notice Type of the protocol
    ProtocolType public immutable protocolType;

    /**
     * @dev Constructor to set the name and type of the protocol
     * @param _protocolName Name of the connector
     */
    constructor(string memory _protocolName, ProtocolType _protocolType) {
        protocolName = keccak256(bytes(_protocolName));
        protocolType = _protocolType;
    }

    /**
     * @notice Gets the name of the protocol
     * @return bytes32 The name of the protocol
     */
    function getProtocolName() external view override returns (bytes32) {
        return protocolName;
    }

    /**
     * @notice gets the type of the protocol
     * @return ProtocolType The type of protocol
     */
    function getProtocolType() external view override returns (ProtocolType) {
        return protocolType;
    }

    /**
     * @notice Executes a function call on the connected protocol
     * @dev This function must be implemented by derived contracts
     * @param data The calldata for the function call
     * @return bytes The return data from the function call
     */
    function execute(bytes calldata data) external payable virtual returns (bytes memory);

    /**
     * @dev Internal function to get the function selector from calldata
     * @param data The calldata to extract the selector from
     * @return bytes4 The function selector
     */
    function _getSelector(bytes calldata data) internal pure returns (bytes4) {
        return bytes4(data[:4]);
    }
}