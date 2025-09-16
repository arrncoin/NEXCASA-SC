// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CustomERC20 is ERC20, Ownable {
    uint8 private _customDecimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply, // jumlah tanpa decimals
        address initialHolder
    ) ERC20(name_, symbol_) Ownable(initialHolder) {
        _customDecimals = decimals_;
        require(initialHolder != address(0), "initialHolder 0");

        if (initialSupply > 0) {
            _mint(initialHolder, initialSupply * (10 ** uint256(_customDecimals)));
        }
    }

    function decimals() public view virtual override returns (uint8) {
        return _customDecimals;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount * (10 ** uint256(_customDecimals)));
    }
}
