// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { ERC20Upgradeable } from "./base/ERC20Upgradeable.sol";
import { HyperlaneBase } from "./base/HyperlaneBase.sol";
import "forge-std/console.sol";

contract CrossCoinHL is ERC20Upgradeable, HyperlaneBase {
    function initialize(
        string memory _name,
        string memory _symbol,
        address _mailbox,
        uint256 _mintCost,
        uint16[2] memory _dstChainIds
    ) external initializer {
        __Ownable_init();
        __ERC20_init(_name, _symbol);
        __hyperlaneInit(_mailbox, _mintCost, _dstChainIds);
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

    function mint(address _user, uint256 _amount) external {
        _hlSend(address(0), _user, _amount);
        _mint(_user, _amount);
    }

    function burn(address _user, uint256 _amount) external {
        _hlSend(_user, address(0), _amount);
        _burn(_user, _amount);
    }
}
