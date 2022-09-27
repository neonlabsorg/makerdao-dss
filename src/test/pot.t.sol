// SPDX-License-Identifier: AGPL-3.0-or-later

// pot.t.sol -- tests for pot.sol

pragma solidity ^0.6.12;

import "./test.sol";
import {Vat} from '../vat.sol';
import {Pot} from '../pot.sol';

contract DSRTest is DSTest {
    Vat vat;
    Pot pot;

    address vow;
    address self;
    address potb;

    function rad(uint wad_) internal pure returns (uint) {
        return wad_ * 10 ** 27;
    }
    function wad(uint rad_) internal pure returns (uint) {
        return rad_ / 10 ** 27;
    }

    function setUp() public {
        vat = new Vat();
        pot = new Pot(address(vat));
        vat.rely(address(pot));
        self = address(this);
        potb = address(pot);

        vow = address(bytes20("vow"));
        pot.file("vow", vow);

        vat.suck(self, self, rad(100 ether));
        vat.hope(address(pot));

        failed = false;
    }
    function test_save_0d() public {
        assertEq(vat.dai(self), rad(100 ether));

        pot.join(100 ether);
        assertEq(wad(vat.dai(self)),   0 ether);
        assertEq(pot.pie(self),      100 ether);

        pot.drip();

        pot.exit(100 ether);
        assertEq(wad(vat.dai(self)), 100 ether);
    }
}
