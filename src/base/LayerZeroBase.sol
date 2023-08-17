// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Package Imports
import { MultilayerBase } from "./MultilayerBase.sol";

// Interfaces
import { ILayerZeroReceiverUpgradeable } from "../interfaces/ILayerZeroReceiverUpgradeable.sol";
import { ILayerZeroEndpointUpgradeable } from "../interfaces/ILayerZeroEndpointUpgradeable.sol";

abstract contract LayerZeroBase is MultilayerBase, ILayerZeroReceiverUpgradeable {
    uint256 constant public DEFAULT_PAYLOAD_SIZE_LIMIT = 10000;

    mapping(uint16 => uint256) public payloadSizeLimitLookup;

    /**
     * @notice function executed by the layer zero endpoint on this chain, also checks for its validity
     * @param _srcChainId id of the source chain
     * @param _srcAddress address of the source chain contract
     * param(unused) _nonce of the transaction
     * @param _payload message added to the source transaction
     */
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 /*_nonce*/, bytes calldata _payload) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == chainEndpoint, "LzApp: invalid endpoint caller"); // TODO: use revert instead

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(_srcAddress.length == trustedRemote.length && trustedRemote.length > 0 && keccak256(_srcAddress) == keccak256(trustedRemote), "LzApp: invalid source sending contract");
        _processRecieve(_payload);
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
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
     */
    function _lzSend(bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams, uint _nativeFee) internal virtual {
        uint256 noOfChains = dstChainIds.length;
        uint16[2] memory dstChainIds = dstChainIds;
        for(uint256 _index = 0; _index < noOfChains; _index++) {
            bytes memory trustedRemote = trustedRemoteLookup[dstChainIds[_index]];
            require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
            _checkPayloadSize(dstChainIds[_index], _payload.length);
            ILayerZeroEndpointUpgradeable(chainEndpoint)
                .send{value: _nativeFee}(
                    dstChainIds[_index],
                    trustedRemote,
                    _payload,
                    _refundAddress,
                    _zroPaymentAddress,
                    _adapterParams
                );
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
        return chainEndpoint;
    }
}
