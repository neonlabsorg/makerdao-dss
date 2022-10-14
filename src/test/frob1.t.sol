// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.12;

import "./test.sol";
import "./token.sol";

import {Vat, TestVat} from './test_vat.sol';
import {Jug} from '../jug.sol';
import {GemJoin} from '../join.sol';

contract Usr {
    Vat public vat;
    constructor(Vat vat_) public {
        vat = vat_;
    }
    function try_call(address addr, bytes calldata data) external returns (bool) {
        bytes memory _data = data;
        assembly {
            let ok := call(gas(), addr, 0, add(_data, 0x20), mload(_data), 0, 0)
            let free := mload(0x40)
            mstore(free, ok)
            mstore(0x40, add(free, 32))
            revert(free, 32)
        }
    }
    function can_frob(bytes32 ilk, address u, address v, address w, int dink, int dart) public returns (bool) {
        string memory sig = "frob(bytes32,address,address,address,int256,int256)";
        bytes memory data = abi.encodeWithSignature(sig, ilk, u, v, w, dink, dart);

        bytes memory can_call = abi.encodeWithSignature("try_call(address,bytes)", vat, data);
        (bool ok, bytes memory success) = address(this).call(can_call);

        ok = abi.decode(success, (bool));
        if (ok) return true;
    }
    function can_fork(bytes32 ilk, address src, address dst, int dink, int dart) public returns (bool) {
        string memory sig = "fork(bytes32,address,address,int256,int256)";
        bytes memory data = abi.encodeWithSignature(sig, ilk, src, dst, dink, dart);

        bytes memory can_call = abi.encodeWithSignature("try_call(address,bytes)", vat, data);
        (bool ok, bytes memory success) = address(this).call(can_call);

        ok = abi.decode(success, (bool));
        if (ok) return true;
    }
    function frob(bytes32 ilk, address u, address v, address w, int dink, int dart) public {
        vat.frob(ilk, u, v, w, dink, dart);
    }
    function fork(bytes32 ilk, address src, address dst, int dink, int dart) public {
        vat.fork(ilk, src, dst, dink, dart);
    }
    function hope(address usr) public {
        vat.hope(usr);
    }
}

contract FrobTest1 is DSTest {
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

    function test_setup() public {
        assertEq(gold.balanceOf(address(gemA)), 1000 ether);
        assertEq(gem("gold",    address(this)), 1000 ether);
    }
    function test_join() public {
        address urn = address(this);
        gold.mint(500 ether);
        assertEq(gold.balanceOf(address(this)),    500 ether);
        assertEq(gold.balanceOf(address(gemA)),   1000 ether);
        gemA.join(urn,                             500 ether);
        assertEq(gold.balanceOf(address(this)),      0 ether);
        assertEq(gold.balanceOf(address(gemA)),   1500 ether);
        gemA.exit(urn,                             250 ether);
        assertEq(gold.balanceOf(address(this)),    250 ether);
        assertEq(gold.balanceOf(address(gemA)),   1250 ether);
    }
    function test_lock() public {
        assertEq(ink("gold", address(this)),    0 ether);
        assertEq(gem("gold", address(this)), 1000 ether);
        vat.frob("gold", me, me, me, 6 ether, 0);
        assertEq(ink("gold", address(this)),   6 ether);
        assertEq(gem("gold", address(this)), 994 ether);
        vat.frob("gold", me, me, me, -6 ether, 0);
        assertEq(ink("gold", address(this)),    0 ether);
        assertEq(gem("gold", address(this)), 1000 ether);
    }
    function test_calm() public {
        // calm means that the debt ceiling is not exceeded
        // it's ok to increase debt as long as you remain calm
        vat.file("gold", 'line', rad(10 ether));
        assertTrue( try_frob("gold", 10 ether, 9 ether));
        // only if under debt ceiling
        assertTrue(!try_frob("gold",  0 ether, 2 ether));
    }
    function test_cool() public {
        // cool means that the debt has decreased
        // it's ok to be over the debt ceiling as long as you're cool
        vat.file("gold", 'line', rad(10 ether));
        assertTrue(try_frob("gold", 10 ether,  8 ether));
        vat.file("gold", 'line', rad(5 ether));
        // can decrease debt when over ceiling
        assertTrue(try_frob("gold",  0 ether, -1 ether));
    }
    function test_safe() public {
        // safe means that the cdp is not risky
        // you can't frob a cdp into unsafe
        vat.frob("gold", me, me, me, 10 ether, 5 ether);                // safe draw
        assertTrue(!try_frob("gold", 0 ether, 6 ether));  // unsafe draw
    }

    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }
}



