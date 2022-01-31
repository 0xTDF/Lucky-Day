// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract wETHmock is ERC20 {

    constructor() ERC20('wETHmock', 'wETHm') {
        _mint(msg.sender, 10000000000000000000); // 10 wETH
    }

}