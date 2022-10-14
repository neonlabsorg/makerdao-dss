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

contract Gem1 {
    mapping (address => uint256) public balanceOf;
    function mint(address usr, uint rad) public {
        balanceOf[usr] += rad;
    }
}

contract VowTest1 is DSTest {
    IVat  vat;
    Vow  vow;
    Flop flop;
    Flap flap;
    Gem1  gov;

    function setUp(address _vat) public {
        vat = IVat(_vat);

        gov  = new Gem1();
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

    function test_no_reflop() public {
        flog(100 ether);
        assertTrue( can_flop() );
        vow.flop();
        assertTrue(!can_flop() );
    }

    function test_no_flop_pending_joy() public {
        flog(200 ether);

        vat.mint(address(vow), 100 ether);
        assertTrue(!can_flop() );

        heal(100 ether);
        assertTrue( can_flop() );
    }

    function test_flap() public {
        vat.mint(address(vow), 100 ether);
        assertTrue( can_flap() );
    }

    function test_no_flap_pending_sin() public {
        vow.file("bump", uint256(0 ether));
        flog(100 ether);

        vat.mint(address(vow), 50 ether);
        assertTrue(!can_flap() );
    }

    function test_no_flap_nonzero_woe() public {
        vow.file("bump", uint256(0 ether));
        flog(100 ether);
        vat.mint(address(vow), 50 ether);
        assertTrue(!can_flap() );
    }

    function test_no_flap_pending_flop() public {
        flog(100 ether);
        vow.flop();

        vat.mint(address(vow), 100 ether);

        assertTrue(!can_flap() );
    }

    function test_no_flap_pending_heal() public {
        flog(100 ether);
        uint id = vow.flop();

        vat.mint(address(this), 100 ether);
        flop.dent(id, 0 ether, rad(100 ether));

        assertTrue(!can_flap() );
    }

    function test_no_surplus_after_good_flop() public {
        flog(100 ether);
        uint id = vow.flop();
        vat.mint(address(this), 100 ether);

        flop.dent(id, 0 ether, rad(100 ether));  // flop succeeds..

        assertTrue(!can_flap() );
    }

    function test_multiple_flop_dents() public {
        flog(100 ether);
        uint id = vow.flop();

        vat.mint(address(this), 100 ether);
        assertTrue(try_dent(id, 2 ether,  rad(100 ether)));

        vat.mint(address(this), 100 ether);
        assertTrue(try_dent(id, 1 ether,  rad(100 ether)));
    }
}
