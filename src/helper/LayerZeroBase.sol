// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Package Imports
import { Initializable } from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

// Interfaces
import { ILayerZeroReceiverUpgradeable } from "../interfaces/ILayerZeroReceiverUpgradeable.sol";
import { ILayerZeroEndpointUpgradeable } from "../interfaces/ILayerZeroEndpointUpgradeable.sol";

abstract contract LayerZeroBase is OwnableUpgradeable, ILayerZeroReceiverUpgradeable {
    uint256 constant public DEFAULT_PAYLOAD_SIZE_LIMIT = 10000;

    ILayerZeroEndpointUpgradeable internal _lzEndpoint;
    uint16[2] internal _dstChainIds;

    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => uint256) public payloadSizeLimitLookup;

    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);

    /**
     * @dev Sets the values for {lzEndpoint} and {dstChainIds}.
     * @param lzEndpoint layer zero endpoint on this chain
     * @param dstChainIds destination chain ids
     */
    function __layerZeroInit(
        address lzEndpoint,
        uint16[2] memory dstChainIds
    ) internal initializer (
    ) {
        _lzEndpoint = ILayerZeroEndpointUpgradeable(lzEndpoint);
        uint256 noOfChains = dstChainIds.length;

        for(uint256 _index = 0; _index < noOfChains; _index++) {
            _dstChainIds[_index] = dstChainIds[_index]; // TODO: can try a more optimal way
        }
    }

    /**
     * @notice function executed by the layer zero endpoint on this chain, also checks for its validity
     * @param _srcChainId id of the source chain
     * @param _srcAddress address of the source chain contract
     * @param _nonce of the transaction
     * @param _payload message added to the source transaction
     */
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(_lzEndpoint), "LzApp: invalid endpoint caller"); // TODO: use revert instead

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(_srcAddress.length == trustedRemote.length && trustedRemote.length > 0 && keccak256(_srcAddress) == keccak256(trustedRemote), "LzApp: invalid source sending contract");

        _lzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    /**
     * @dev authorise remote chain address corresponding to each chain Id
     * @param _remoteChainId chain id of the target chain
     * @param _remoteAddress address of the contract on target chain
     */
    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external onlyOwner {
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    /**
     * @notice if the size is 0, it means default size limit
     * @dev setter for payload size limit
     * @param _dstChainId id of the chain for which we want to set
     * @param _size max sie of the payload
     */
    function setPayloadSizeLimit(uint16 _dstChainId, uint _size) external onlyOwner {
        payloadSizeLimitLookup[_dstChainId] = _size;
    }

    /**
     * @dev abstract function for the importing contract to implement functionality accordingly
     * @param _srcChainId id of the source chain
     * @param _srcAddress address of the source chain contract
     * @param _nonce of the transaction
     * @param _payload message added to the source transaction
     */
    function _lzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    /**
     * @dev function to make a call to layerzero endpoint on the current chain
     * @param _payload message to be transffered
     * @param _refundAddress address of the user to recieve refund // TODO
     * @param _zroPaymentAddress zero payment address // TODO
     * @param _adapterParams adapter params // TODO
     * @param _nativeFee native fee // TODO
     */
    function _lzSend(bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams, uint _nativeFee) internal virtual {
        uint256 noOfChains = _dstChainIds.length;
        uint16[2] memory dstChainIds = _dstChainIds;
        for(uint256 _index = 0; _index < noOfChains; _index++) {
            bytes memory trustedRemote = trustedRemoteLookup[dstChainIds[_index]];
            require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
            _checkPayloadSize(dstChainIds[_index], _payload.length);
            _lzEndpoint.send{value: _nativeFee}(dstChainIds[_index], trustedRemote, _payload, _refundAddress, _zroPaymentAddress, _adapterParams);
        }
    }

    function _checkPayloadSize(uint16 _dstChainId, uint _payloadSize) internal view virtual {
        uint payloadSizeLimit = payloadSizeLimitLookup[_dstChainId];
        if (payloadSizeLimit == 0) { // use default if not set
            payloadSizeLimit = DEFAULT_PAYLOAD_SIZE_LIMIT;
        }
        require(_payloadSize <= payloadSizeLimit, "LzApp: payload size is too large");
    }

    // GETTERS

    function getLayerZeroEndpoint() external view returns(address) {
        return address(_lzEndpoint);
    }
}
