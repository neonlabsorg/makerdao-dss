// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.12;

interface IToken {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
}

contract Exchange {
    IToken gold;
    IToken dai;
    uint256 goldPrice;

    constructor(IToken gold_, IToken dai_, uint256 goldPrice_) public {
        gold = gold_;
        dai = dai_;
        goldPrice = goldPrice_;
    }

    function sellGold(uint256 goldAmt) external {
        gold.transferFrom(msg.sender, address(this), goldAmt);
        uint256 daiAmt = goldAmt * goldPrice / 1E18;
        dai.transfer(msg.sender, daiAmt);
    }
}
