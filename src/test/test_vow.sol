// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.12;

import {Vow} from '../vow.sol';

contract TestVow is Vow {
    constructor(address vat, address flapper, address flopper)
    public Vow(vat, flapper, flopper) {}

    // Total deficit
    function Awe() public view returns (uint) {
        return vat.sin(address(this));
    }
    // Total surplus
    function Joy() public view returns (uint) {
        return vat.dai(address(this));
    }
    // Unqueued, pre-auction debt
    function Woe() public view returns (uint) {
        return sub(sub(Awe(), Sin), Ash);
    }
}
