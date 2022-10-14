// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.12;

import "./test.sol";
import "./token.sol";

import {Vat, TestVat} from './test_vat.sol';
import {Jug} from '../jug.sol';
import {GemJoin} from '../join.sol';

contract FrobTest2 is DSTest {
    TestVat vat;
    DSToken gold;
    Jug     jug;

    GemJoin gemA;
    address me;

    function try_frob(bytes32 ilk, int ink, int art) public returns (bool ok) {
        string memory sig = "frob(bytes32,address,address,address,int256,int256)";
        address self = address(this);
        (ok,) = address(vat).call(abi.encodeWithSignature(sig, ilk, self, self, self, ink, art));
    }

    function ray(uint wad) internal pure returns (uint) {
        return wad * 10 ** 9;
    }

    function setUp() public {
        vat = new TestVat();

        gold = new DSToken("GEM");
        gold.mint(1000 ether);

        vat.init("gold");
        gemA = new GemJoin(address(vat), "gold", address(gold));

        vat.file("gold", "spot",    ray(1 ether));
        vat.file("gold", "line", rad(1000 ether));
        vat.file("Line",         rad(1000 ether));
        jug = new Jug(address(vat));
        jug.init("gold");
        vat.rely(address(jug));

        gold.approve(address(gemA));
        gold.approve(address(vat));

        vat.rely(address(vat));
        vat.rely(address(gemA));

        gemA.join(address(this), 1000 ether);

        me = address(this);

        failed = false;
    }

    function gem(bytes32 ilk, address urn) internal view returns (uint) {
        return vat.gem(ilk, urn);
    }
    function ink(bytes32 ilk, address urn) internal view returns (uint) {
        (uint ink_, uint art_) = vat.urns(ilk, urn); art_;
        return ink_;
    }

    function test_nice() public {
        // nice means that the collateral has increased or the debt has
        // decreased. remaining unsafe is ok as long as you're nice

        vat.frob("gold", me, me, me, 10 ether, 10 ether);
        vat.file("gold", 'spot', ray(0.5 ether));  // now unsafe

        // debt can't increase if unsafe
        assertTrue(!try_frob("gold",  0 ether,  1 ether));
        // debt can decrease
        assertTrue( try_frob("gold",  0 ether, -1 ether));
        // ink can't decrease
        assertTrue(!try_frob("gold", -1 ether,  0 ether));
        // ink can increase
        assertTrue( try_frob("gold",  1 ether,  0 ether));

        // cdp is still unsafe
        // ink can't decrease, even if debt decreases more
        assertTrue(!this.try_frob("gold", -2 ether, -4 ether));
        // debt can't increase, even if ink increases more
        assertTrue(!this.try_frob("gold",  5 ether,  1 ether));

        // ink can decrease if end state is safe
        assertTrue( this.try_frob("gold", -1 ether, -4 ether));
        vat.file("gold", 'spot', ray(0.4 ether));  // now unsafe
        // debt can increase if end state is safe
        assertTrue( this.try_frob("gold",  5 ether, 1 ether));
    }

    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }

    function test_dust() public {
        assertTrue( try_frob("gold", 9 ether,  1 ether));
        vat.file("gold", "dust", rad(5 ether));
        assertTrue(!try_frob("gold", 5 ether,  2 ether));
        assertTrue( try_frob("gold", 0 ether,  5 ether));
        assertTrue(!try_frob("gold", 0 ether, -5 ether));
        assertTrue( try_frob("gold", 0 ether, -6 ether));
    }
}



