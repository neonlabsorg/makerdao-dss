// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.12;

import "./test.sol";

interface IDSToken {
    function owner() external returns (address);
    function setOwner(address owner_) external;
    function stopped() external returns (bool);
    function totalSupply() external returns (uint256);
    function balanceOf(address usr) external returns (uint256);
    function allowance(address usr1, address usr2) external returns (uint256);
    function symbol() external returns (string memory);
    function decimals() external returns (uint8);
    function name() external returns (string memory);
    function approve(address guy) external returns (bool);
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function push(address dst, uint wad) external;
    function pull(address src, uint wad) external;
    function move(address src, address dst, uint wad) external;
    function mint(uint wad) external;
    function burn(uint wad) external;
    function mint(address guy, uint wad) external;
    function burn(address guy, uint wad) external;
    function stop() external;
    function start() external;
    function setName(string memory name_) external;
}

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

contract FrobTest4 is DSTest {
    TestVat vat;
    IDSToken gold;
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

    function setUp(address _goldAddress) public {
        vat = new TestVat();

        gold = IDSToken(_goldAddress);
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

    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }

    function test_alt_callers() public {
        Usr ali = new Usr(vat);
        Usr bob = new Usr(vat);
        Usr che = new Usr(vat);

        address a = address(ali);
        address b = address(bob);
        address c = address(che);

        vat.slip("gold", a, int(rad(20 ether)));
        vat.slip("gold", b, int(rad(20 ether)));
        vat.slip("gold", c, int(rad(20 ether)));

        ali.frob("gold", a, a, a, 10 ether, 5 ether);

        // anyone can lock
        assertTrue( ali.can_frob("gold", a, a, a,  1 ether,  0 ether));
        assertTrue( bob.can_frob("gold", a, b, b,  1 ether,  0 ether));
        assertTrue( che.can_frob("gold", a, c, c,  1 ether,  0 ether));
        // but only with their own gems
        assertTrue(!ali.can_frob("gold", a, b, a,  1 ether,  0 ether));
        assertTrue(!bob.can_frob("gold", a, c, b,  1 ether,  0 ether));
        assertTrue(!che.can_frob("gold", a, a, c,  1 ether,  0 ether));

        // only the lad can free
        assertTrue( ali.can_frob("gold", a, a, a, -1 ether,  0 ether));
        assertTrue(!bob.can_frob("gold", a, b, b, -1 ether,  0 ether));
        assertTrue(!che.can_frob("gold", a, c, c, -1 ether,  0 ether));
        // the lad can free to anywhere
        assertTrue( ali.can_frob("gold", a, b, a, -1 ether,  0 ether));
        assertTrue( ali.can_frob("gold", a, c, a, -1 ether,  0 ether));

        // only the lad can draw
        assertTrue( ali.can_frob("gold", a, a, a,  0 ether,  1 ether));
        assertTrue(!bob.can_frob("gold", a, b, b,  0 ether,  1 ether));
        assertTrue(!che.can_frob("gold", a, c, c,  0 ether,  1 ether));
        // the lad can draw to anywhere
        assertTrue( ali.can_frob("gold", a, a, b,  0 ether,  1 ether));
        assertTrue( ali.can_frob("gold", a, a, c,  0 ether,  1 ether));

        vat.mint(address(bob), 1 ether);
        vat.mint(address(che), 1 ether);

        // anyone can wipe
        assertTrue( ali.can_frob("gold", a, a, a,  0 ether, -1 ether));
        assertTrue( bob.can_frob("gold", a, b, b,  0 ether, -1 ether));
        assertTrue( che.can_frob("gold", a, c, c,  0 ether, -1 ether));
        // but only with their own dai
        assertTrue(!ali.can_frob("gold", a, a, b,  0 ether, -1 ether));
        assertTrue(!bob.can_frob("gold", a, b, c,  0 ether, -1 ether));
        assertTrue(!che.can_frob("gold", a, c, a,  0 ether, -1 ether));
    }
}



