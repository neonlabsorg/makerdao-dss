// SPDX-License-Identifier: AGPL-3.0-or-later

// flop.t.sol -- tests for flop.sol

pragma solidity ^0.6.12;

import "./test.sol";
import {DSToken} from "./token.sol";
import "../flop.sol";
import "../vat.sol";

contract Guy {
    Flopper flop;
    constructor(Flopper flop_) public {
        flop = flop_;
        Vat(address(flop.vat())).hope(address(flop));
        DSToken(address(flop.gem())).approve(address(flop));
    }
    function dent(uint id, uint lot, uint bid) public {
        flop.dent(id, lot, bid);
    }
    function deal(uint id) public {
        flop.deal(id);
    }
    function try_dent(uint id, uint lot, uint bid)
        public returns (bool ok)
    {
        string memory sig = "dent(uint256,uint256,uint256)";
        (ok,) = address(flop).call(abi.encodeWithSignature(sig, id, lot, bid));
    }
    function try_deal(uint id)
        public returns (bool ok)
    {
        string memory sig = "deal(uint256)";
        (ok,) = address(flop).call(abi.encodeWithSignature(sig, id));
    }
    function try_tick(uint id)
        public returns (bool ok)
    {
        string memory sig = "tick(uint256)";
        (ok,) = address(flop).call(abi.encodeWithSignature(sig, id));
    }
}

contract Gal {
    uint public Ash;
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function kick(Flopper flop, uint lot, uint bid) external returns (uint) {
        Ash += bid;
        return flop.kick(address(this), lot, bid);
    }
    function kiss(uint rad) external {
        Ash = sub(Ash, rad);
    }
    function cage(Flopper flop) external {
        flop.cage();
    }
}

contract Vatish is DSToken('') {
    uint constant ONE = 10 ** 27;
    function hope(address usr) public {
         approve(usr, uint(-1));
    }
    function dai(address usr) public view returns (uint) {
         return balanceOf[usr];
    }
}

contract FlopTest1 is DSTest {
    Flopper flop;
    Vat     vat;
    DSToken gem;

    address ali;
    address bob;
    address gal;

    function kiss(uint) public pure { }  // arbitrary callback

    function setUp() public {
        vat = new Vat();
        gem = new DSToken('');

        flop = new Flopper(address(vat), address(gem));

        ali = address(new Guy(flop));
        bob = address(new Guy(flop));
        gal = address(new Gal());

        flop.rely(gal);
        flop.deny(address(this));

        vat.hope(address(flop));
        vat.rely(address(flop));
        gem.approve(address(flop));

        vat.suck(address(this), address(this), 1000 ether);

        vat.move(address(this), ali, 200 ether);
        vat.move(address(this), bob, 200 ether);

        failed = false;
    }

    function test_kick() public {
        assertEq(vat.dai(gal), 0);
        assertEq(gem.balanceOf(gal), 0 ether);
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 5000 ether);
        // no value transferred
        assertEq(vat.dai(gal), 0);
        assertEq(gem.balanceOf(gal), 0 ether);
        // auction created with appropriate values
        assertEq(flop.kicks(), id);
        (uint256 bid, uint256 lot, address guy, uint48 tic, uint48 end) = flop.bids(id);
        assertEq(bid, 5000 ether);
        assertEq(lot, 200 ether);
        assertTrue(guy == gal);
        assertEq(uint256(tic), 0);
        assertEq(uint256(end), now + flop.tau());
    }

    function test_dent_same_bidder() public {
        uint id = Gal(gal).kick(flop, /*lot*/ 200 ether, /*bid*/ 200 ether);

        Guy(ali).dent(id, 100 ether, 200 ether);
        assertEq(vat.dai(ali), 0);
        Guy(ali).dent(id, 50 ether, 200 ether);
    }
}
