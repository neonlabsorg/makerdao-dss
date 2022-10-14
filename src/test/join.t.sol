// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.12;

import "./test.sol";
import "./token.sol";

import {TestVat} from './test_vat.sol';
import {GemJoin, DaiJoin} from '../join.sol';

contract JoinTest is DSTest {
    TestVat vat;
    DSToken gem;
    GemJoin gemA;
    DaiJoin daiA;
    DSToken dai;
    address me;

    function setUp() public {
        vat = new TestVat();
        vat.init("eth");

        gem  = new DSToken("Gem");
        gemA = new GemJoin(address(vat), "gem", address(gem));
        vat.rely(address(gemA));

        dai  = new DSToken("Dai");
        daiA = new DaiJoin(address(vat), address(dai));
        vat.rely(address(daiA));
        dai.setOwner(address(daiA));

        me = address(this);

        failed = false;
    }
    function try_cage(address a) public payable returns (bool ok) {
        string memory sig = "cage()";
        (ok,) = a.call(abi.encodeWithSignature(sig));
    }
    function try_join_gem(address usr, uint wad) public returns (bool ok) {
        string memory sig = "join(address,uint256)";
        (ok,) = address(gemA).call(abi.encodeWithSignature(sig, usr, wad));
    }
    function try_exit_dai(address usr, uint wad) public returns (bool ok) {
        string memory sig = "exit(address,uint256)";
        (ok,) = address(daiA).call(abi.encodeWithSignature(sig, usr, wad));
    }
    function test_gem_join() public {
        gem.mint(20 ether);
        gem.approve(address(gemA), 20 ether);
        assertTrue( try_join_gem(address(this), 10 ether));
        assertEq(vat.gem("gem", me), 10 ether);
        assertTrue( try_cage(address(gemA)));
        assertTrue(!try_join_gem(address(this), 10 ether));
        assertEq(vat.gem("gem", me), 10 ether);
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }
    function test_dai_exit() public {
        address urn = address(this);
        vat.mint(address(this), 100 ether);
        vat.hope(address(daiA));
        assertTrue( try_exit_dai(urn, 40 ether));
        assertEq(dai.balanceOf(address(this)), 40 ether);
        assertEq(vat.dai(me),              rad(60 ether));
        assertTrue( try_cage(address(daiA)));
        assertTrue(!try_exit_dai(urn, 40 ether));
        assertEq(dai.balanceOf(address(this)), 40 ether);
        assertEq(vat.dai(me),              rad(60 ether));
    }
    function test_dai_exit_join() public {
        address urn = address(this);
        vat.mint(address(this), 100 ether);
        vat.hope(address(daiA));
        daiA.exit(urn, 60 ether);
        dai.approve(address(daiA), uint(-1));
        daiA.join(urn, 30 ether);
        assertEq(dai.balanceOf(address(this)),     30 ether);
        assertEq(vat.dai(me),                  rad(70 ether));
    }
    function test_cage_no_access() public {
        gemA.deny(address(this));
        assertTrue(!try_cage(address(gemA)));
        daiA.deny(address(this));
        assertTrue(!try_cage(address(daiA)));
    }
}
