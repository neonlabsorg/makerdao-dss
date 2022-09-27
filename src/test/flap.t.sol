// SPDX-License-Identifier: AGPL-3.0-or-later

// flap.t.sol -- tests for flap.sol

pragma solidity ^0.6.12;

import "./test.sol";
import {DSToken} from "ds-token/token.sol";
import "../flap.sol";
import "../vat.sol";

contract Guy {
    Flapper flap;
    constructor(Flapper flap_) public {
        flap = flap_;
        Vat(address(flap.vat())).hope(address(flap));
        DSToken(address(flap.gem())).approve(address(flap));
    }
    function tend(uint id, uint lot, uint bid) public {
        flap.tend(id, lot, bid);
    }
    function deal(uint id) public {
        flap.deal(id);
    }
    function try_tend(uint id, uint lot, uint bid)
        public returns (bool ok)
    {
        string memory sig = "tend(uint256,uint256,uint256)";
        (ok,) = address(flap).call(abi.encodeWithSignature(sig, id, lot, bid));
    }
    function try_deal(uint id)
        public returns (bool ok)
    {
        string memory sig = "deal(uint256)";
        (ok,) = address(flap).call(abi.encodeWithSignature(sig, id));
    }
    function try_tick(uint id)
        public returns (bool ok)
    {
        string memory sig = "tick(uint256)";
        (ok,) = address(flap).call(abi.encodeWithSignature(sig, id));
    }
}

contract FlapTest is DSTest {
    Flapper flap;
    Vat     vat;
    DSToken gem;

    address ali;
    address bob;

    function setUp() public {
        vat = new Vat();
        gem = new DSToken('');

        flap = new Flapper(address(vat), address(gem));
        flap.file("lid", 500 ether);

        ali = address(new Guy(flap));
        bob = address(new Guy(flap));

        vat.hope(address(flap));
        gem.approve(address(flap));

        vat.suck(address(this), address(this), 1000 ether);

        gem.mint(1000 ether);
        gem.setOwner(address(flap));

        gem.push(ali, 200 ether);
        gem.push(bob, 200 ether);

        failed = false;
    }
    function test_kick() public {
        assertEq(vat.dai(address(this)), 1000 ether);
        assertEq(vat.dai(address(flap)),    0 ether);
        assertEq(flap.fill(),               0 ether);
        flap.kick({ lot: 100 ether
                  , bid: 0
                  });
        assertEq(vat.dai(address(this)),  900 ether);
        assertEq(vat.dai(address(flap)),  100 ether);
        assertEq(flap.fill(),             100 ether);
    }

    function test_tend_same_bidder() public {
        uint id = flap.kick({ lot: 100 ether
                            , bid: 0
                            });
        Guy(ali).tend(id, 100 ether, 190 ether);
        assertEq(gem.balanceOf(ali), 10 ether);
        Guy(ali).tend(id, 100 ether, 200 ether);
        assertEq(gem.balanceOf(ali), 0);
    }
    function test_beg() public {
        uint id = flap.kick({ lot: 100 ether
                            , bid: 0
                            });
        assertTrue( Guy(ali).try_tend(id, 100 ether, 1.00 ether));
        assertTrue(!Guy(bob).try_tend(id, 100 ether, 1.01 ether));
        // high bidder is subject to beg
        assertTrue(!Guy(ali).try_tend(id, 100 ether, 1.01 ether));
        assertTrue( Guy(bob).try_tend(id, 100 ether, 1.07 ether));
    }

    function testFail_kick_over_lid() public {
        flap.kick({ lot: 501 ether
                  , bid: 0
                  });
    }
    function testFail_kick_over_lid_2_auctions() public {
        // Just up to the lid
        flap.kick({ lot: 500 ether
                  , bid: 0
                  });
        // Just over the lid
        flap.kick({ lot: 1
                  , bid: 0
                  });
    }
}
