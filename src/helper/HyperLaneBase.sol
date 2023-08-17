// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Package Imports
import { Strings } from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

interface IMailbox {
    function localDomain() external view returns (uint32);

    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external returns (bytes32);

    function process(bytes calldata _metadata, bytes calldata _message)
        external;

    function count() external view returns (uint32);

    function root() external view returns (bytes32);

    function latestCheckpoint() external view returns (bytes32, uint32);
}

abstract contract HyperLaneBase is OwnableUpgradeable {
    IMailbox public mailbox;
    uint256 private mintCost;

    event Executed(address indexed _from, bytes _value);

    error InsufficientFundsProvidedForMint();

    function __hyperlaneInit(
        address _mailbox, uint _mintCost
    ) internal initializer {
        mailbox = IMailbox(_mailbox);
        mintCost = _mintCost;
    }

    // To receive the message from Hyperlane
    function handle(
        uint32,
        bytes32,
        bytes calldata _payload
    ) public {
        _processRecieve(_payload);
    }

    // To send message to Hyperlane
    function _sendTransferEvent(
        uint32 _destinationDomain,
        address _recipient,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if(msg.value < mintCost) {
            revert InsufficientFundsProvidedForMint();
        }
        bytes memory _message = abi.encode(_from, _to, _amount);
        mailbox.dispatch(_destinationDomain, _addressToBytes32(_recipient), _message);
    }

    function _addressToBytes32(address _addr) private pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    /**
     * @dev abstract function for the importing contract to implement functionality accordingly
     * @param _payload message added to the source transaction
     */
    function _processRecieve(bytes memory _payload) internal virtual;
}