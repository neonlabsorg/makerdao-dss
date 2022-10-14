// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.12;

import {Vat} from '../vat.sol';

contract TestVat is Vat {
    uint256 constant ONE = 10 ** 27;
    function mint(address usr, uint wad) public {
        dai[usr] += wad * ONE;
        debt += wad * ONE;
    }
}
