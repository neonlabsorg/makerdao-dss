// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.5.12;

import "./test.sol";

import {Vat}     from "../vat.sol";
import {Cat}     from "../cat.sol";
import {Flipper} from "../flip.sol";

contract Guy {
    Flipper flip;
    constructor(Flipper flip_) public {
        flip = flip_;
    }
    function hope(address usr) public {
        Vat(address(flip.vat())).hope(usr);
    }
    function tend(uint id, uint lot, uint bid) public {
        flip.tend(id, lot, bid);
    }
    function dent(uint id, uint lot, uint bid) public {
        flip.dent(id, lot, bid);
    }
    function deal(uint id) public {
        flip.deal(id);
    }
    function try_tend(uint id, uint lot, uint bid)
        public returns (bool ok)
    {
        string memory sig = "tend(uint256,uint256,uint256)";
        (ok,) = address(flip).call(abi.encodeWithSignature(sig, id, lot, bid));
    }
    function try_dent(uint id, uint lot, uint bid)
        public returns (bool ok)
    {
        string memory sig = "dent(uint256,uint256,uint256)";
        (ok,) = address(flip).call(abi.encodeWithSignature(sig, id, lot, bid));
    }
    function try_deal(uint id)
        public returns (bool ok)
    {
        string memory sig = "deal(uint256)";
        (ok,) = address(flip).call(abi.encodeWithSignature(sig, id));
    }
    function try_tick(uint id)
        public returns (bool ok)
    {
        string memory sig = "tick(uint256)";
        (ok,) = address(flip).call(abi.encodeWithSignature(sig, id));
    }
    function try_yank(uint id)
        public returns (bool ok)
    {
        string memory sig = "yank(uint256)";
        (ok,) = address(flip).call(abi.encodeWithSignature(sig, id));
    }
}

contract Gal {}

contract Cat_ is Cat {
    uint256 constant public RAD = 10 ** 45;
    uint256 constant public MLN = 10 **  6;

    constructor(address vat_) Cat(vat_) public {
        litter = 5 * MLN * RAD;
    }
}

contract Vat_ is Vat {
    function mint(address usr, uint wad) public {
        dai[usr] += wad;
    }
    function dai_balance(address usr) public view returns (uint) {
        return dai[usr];
    }
    bytes32 ilk;
    function set_ilk(bytes32 ilk_) public {
        ilk = ilk_;
    }
    function gem_balance(address usr) public view returns (uint) {
        return gem[ilk][usr];
    }
}

contract FlipTest3 is DSTest {
    Vat_    vat;
    Cat_    cat;
    Flipper flip;

    address ali;
    address bob;
    address gal;
    address usr = address(0xacab);

    uint256 constant public RAD = 10 ** 45;
    uint256 constant public MLN = 10 **  6;

    function setUp() public {
        vat = new Vat_();
        cat = new Cat_(address(vat));

        vat.init("gems");
        vat.set_ilk("gems");

        flip = new Flipper(address(vat), address(cat), "gems");
        cat.rely(address(flip));

        ali = address(new Guy(flip));
        bob = address(new Guy(flip));
        gal = address(new Gal());

        Guy(ali).hope(address(flip));
        Guy(bob).hope(address(flip));
        vat.hope(address(flip));

        vat.slip("gems", address(this), 1000 ether);
        vat.mint(ali, 200 ether);
        vat.mint(bob, 200 ether);

        failed = false;
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }

    function test_yank_tend() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: rad(50 ether)
                            , usr: usr
                            , gal: gal
                            , bid: 0
                            });

        Guy(ali).tend(id, 100 ether, 1 ether);

        // bid taken from bidder
        assertEq(vat.dai_balance(ali), 199 ether);
        assertEq(vat.dai_balance(gal),   1 ether);

        // we have some amount of litter in the box
        assertEq(cat.litter(), 5 * MLN * RAD);

        vat.mint(address(this), 1 ether);
        flip.yank(id);

        // bid is refunded to bidder from caller
        assertEq(vat.dai_balance(ali),            200 ether);
        assertEq(vat.dai_balance(address(this)),    0 ether);

        // gems go to caller
        assertEq(vat.gem_balance(address(this)), 1000 ether);

        // cat.scoop(tab) is called decrementing the litter accumulator
        assertEq(cat.litter(), (5 * MLN * RAD) - rad(50 ether));
    }

}
