// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { ERC20Upgradeable } from "./base/ERC20Upgradeable.sol";
import { LayerZeroBase } from "./base/LayerZeroBase.sol";
import "forge-std/console.sol";

contract CrossCoinLZ is ERC20Upgradeable, LayerZeroBase {
    function initialize(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        uint16[2] memory dstChainIds
    ) external initializer (
    ) {
        __Ownable_init();
        __ERC20_init(_name, _symbol);
        __multilayerInit(_lzEndpoint, dstChainIds);
    }

    function _processRecieve(bytes memory _payload) internal override {
        (address _from, address _to, uint256 _amount) = abi.decode(_payload, (address, address, uint256));
        if (_from == address(0)) {
            _totalSupply = _totalSupply + _amount;
        } else if (_to == address(0)) {
            _totalSupply = _totalSupply - _amount;
        } else {
            revert InvalidEvent();
        }
    }

    function mint(address _user, uint256 _amount) external payable {
        _lzSend(
            abi.encodePacked(address(0), _user, _amount),
            payable(msg.sender),
            address(0x0),
            bytes(""),
            msg.value
        );
        _mint(_user, _amount);
    }

    function burn(address _user, uint256 _amount) external payable {
        _lzSend(
            abi.encodePacked(_user, address(0), _amount),
            payable(msg.sender),
            address(0x0),
            bytes(""),
            msg.value
        );
        _burn(_user, _amount);
    }
}
