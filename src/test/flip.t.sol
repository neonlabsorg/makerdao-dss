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

contract FlipTest is DSTest {
    Vat_    vat;
    Cat_    cat;
    Flipper flip;

    address ali;
    address bob;
    address gal;
    address usr = address(0xacab);

    uint256 constant public RAY = 10 ** 27;
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
    function test_kick() public {
        flip.kick({ lot: 100 ether
                  , tab: 50 ether
                  , usr: usr
                  , gal: gal
                  , bid: 0
                  });
    }
    function testFail_tend_empty() public {
        // can't tend on non-existent
        flip.tend(42, 0, 0);
    }

    function test_dent() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , usr: usr
                            , gal: gal
                            , bid: 0
                            });
        Guy(ali).tend(id, 100 ether,  1 ether);
        Guy(bob).tend(id, 100 ether, 50 ether);

        Guy(ali).dent(id,  95 ether, 50 ether);
        // plop the gems
        assertEq(vat.gem_balance(address(0xacab)), 5 ether);
        assertEq(vat.dai_balance(ali),  150 ether);
        assertEq(vat.dai_balance(bob),  200 ether);
    }
    function test_tend_dent_same_bidder() public {
       uint id = flip.kick({ lot: 100 ether
                            , tab: 200 ether
                            , usr: usr
                            , gal: gal
                            , bid: 0
                            });

        assertEq(vat.dai_balance(ali), 200 ether);
        Guy(ali).tend(id, 100 ether, 190 ether);
        assertEq(vat.dai_balance(ali), 10 ether);
        Guy(ali).tend(id, 100 ether, 200 ether);
        assertEq(vat.dai_balance(ali), 0);
        Guy(ali).dent(id, 80 ether, 200 ether);
    }
    function test_beg() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , usr: usr
                            , gal: gal
                            , bid: 0
                            });
        assertTrue( Guy(ali).try_tend(id, 100 ether, 1.00 ether));
        assertTrue(!Guy(bob).try_tend(id, 100 ether, 1.01 ether));
        // high bidder is subject to beg
        assertTrue(!Guy(ali).try_tend(id, 100 ether, 1.01 ether));
        assertTrue( Guy(bob).try_tend(id, 100 ether, 1.07 ether));

        // can bid by less than beg at flip
        assertTrue( Guy(ali).try_tend(id, 100 ether, 49 ether));
        assertTrue( Guy(bob).try_tend(id, 100 ether, 50 ether));

        assertTrue(!Guy(ali).try_dent(id, 100 ether, 50 ether));
        assertTrue(!Guy(ali).try_dent(id,  99 ether, 50 ether));
        assertTrue( Guy(ali).try_dent(id,  95 ether, 50 ether));
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
    function test_yank_dent() public {
        uint id = flip.kick({ lot: 100 ether
                            , tab: 50 ether
                            , usr: usr
                            , gal: gal
                            , bid: 0
                            });

        // we have some amount of litter in the box
        assertEq(cat.litter(), 5 * MLN * RAD);

        Guy(ali).tend(id, 100 ether,  1 ether);
        Guy(bob).tend(id, 100 ether, 50 ether);
        Guy(ali).dent(id,  95 ether, 50 ether);

        // cannot yank in the dent phase
        assertTrue(!Guy(ali).try_yank(id));

        // we have same amount of litter in the box
        assertEq(cat.litter(), 5 * MLN * RAD);
    }
}
