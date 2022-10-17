// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Dev is ERC20 {
    constructor() ERC20("DEV USDT", "devUSDC") {
        _mint(msg.sender, 1000000000 ether);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}
