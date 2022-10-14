// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.12;

import "./test.sol";

import {Flopper as Flop} from '../flop.sol';
import {Flapper as Flap} from '../flap.sol';
import {Vow}     from '../vow.sol';

interface IVat {
    function hope(address usr) external;
    function init(bytes32 ilk) external;
    function suck(address u, address v, uint rad) external;
    function can(address _vow, address _flap) external returns (uint);
    function mint(address usr, uint wad) external;
}

contract Gem2 {
    mapping (address => uint256) public balanceOf;
    function mint(address usr, uint rad) public {
        balanceOf[usr] += rad;
    }
}

contract VowTest2 is DSTest {
    IVat  vat;
    Vow  vow;
    Flop flop;
    Flap flap;
    Gem2  gov;
    Flop newFlop;
    Flap newFlap;

    function setUp(address _vat) public {
        vat = IVat(_vat);

        gov  = new Gem2();
        flop = new Flop(address(vat), address(gov));
        flap = new Flap(address(vat), address(gov));
        
        vow = new Vow(address(vat), address(flap), address(flop));
        flap.rely(address(vow));
        flop.rely(address(vow));
        flap.file("lid", rad(1000 ether));

        vow.file("bump", rad(100 ether));
        vow.file("sump", rad(100 ether));
        vow.file("dump", 200 ether);

        vat.hope(address(flop));

        newFlap = new Flap(address(vat), address(gov));
        newFlop = new Flop(address(vat), address(gov));

        failed = false;
    }

    function try_flog(uint era) internal returns (bool ok) {
        string memory sig = "flog(uint256)";
        (ok,) = address(vow).call(abi.encodeWithSignature(sig, era));
    }
    function try_dent(uint id, uint lot, uint bid) internal returns (bool ok) {
        string memory sig = "dent(uint256,uint256,uint256)";
        (ok,) = address(flop).call(abi.encodeWithSignature(sig, id, lot, bid));
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
    function can_flap() public returns (bool) {
        string memory sig = "flap()";
        bytes memory data = abi.encodeWithSignature(sig);

        bytes memory can_call = abi.encodeWithSignature("try_call(address,bytes)", vow, data);
        (bool ok, bytes memory success) = address(this).call(can_call);

        ok = abi.decode(success, (bool));
        if (ok) return true;
    }
    function can_flop() public returns (bool) {
        string memory sig = "flop()";
        bytes memory data = abi.encodeWithSignature(sig);

        bytes memory can_call = abi.encodeWithSignature("try_call(address,bytes)", vow, data);
        (bool ok, bytes memory success) = address(this).call(can_call);

        ok = abi.decode(success, (bool));
        if (ok) return true;
    }

    uint constant ONE = 10 ** 27;
    function rad(uint wad) internal pure returns (uint) {
        return wad * ONE;
    }

    function suck(address who, uint wad) internal {
        vow.fess(rad(wad));
        vat.init('');
        vat.suck(address(vow), who, rad(wad));
    }
    function flog(uint wad) internal {
        suck(address(0), wad);  // suck dai into the zero address
        vow.flog(now);
    }
    function heal(uint wad) internal {
        vow.heal(rad(wad));
    }

    function test_change_flap_flop() public {
        newFlap.rely(address(vow));
        newFlop.rely(address(vow));

        assertEq(vat.can(address(vow), address(flap)), 1);
        assertEq(vat.can(address(vow), address(newFlap)), 0);

        vow.file('flapper', address(newFlap));
        vow.file('flopper', address(newFlop));

        assertEq(address(vow.flapper()), address(newFlap));
        assertEq(address(vow.flopper()), address(newFlop));

        assertEq(vat.can(address(vow), address(flap)), 0);
        assertEq(vat.can(address(vow), address(newFlap)), 1);
    }
}
