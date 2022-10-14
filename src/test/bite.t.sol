// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.12;

import "./test.sol";
import "./token.sol";

interface IVat {
    function sin(address u) external returns (uint256); // [rad]
    function dai(address u) external returns (uint256); // [rad]
    function gem(bytes32 ilk, address usr) external view returns (uint); // [wad]
    function urns(bytes32 ilk, address usr) external view returns (uint256, uint256);
    function ilks(bytes32 ilk) external returns (uint256, uint256, uint256, uint256, uint256);

    function hope(address usr) external;
    function init(bytes32 ilk) external;
    function suck(address u, address v, uint rad) external;
    function can(address _vow, address _flap) external returns (uint);
    function mint(address usr, uint wad) external;
    function file(bytes32 what, uint data) external;
    function file(bytes32 ilk, bytes32 what, uint data) external;
    function rely(address usr) external;
    function frob(bytes32 i, address u, address v, address w, int dink, int dart) external;
    function fold(bytes32 i, address u, int rate) external;
}

interface IFlapper {
    function rely(address usr) external;
    function file(bytes32 what, uint data) external;
}

interface IFlopper {
    function rely(address usr) external;
}

interface ITestVow {
    function rely(address usr) external;
    function Awe() external view returns (uint);
    function Woe() external view returns (uint);
    function sin(uint256 time) external returns (uint256);
}

interface IJug {
    function init(bytes32 ilk) external;
    function file(bytes32 what, address data) external;
}

interface ICat {
    function file(bytes32 what, address data) external;
    function file(bytes32 what, uint256 data) external;
    function file(bytes32 ilk, bytes32 what, uint256 data) external;
    function file(bytes32 ilk, bytes32 what, address flip) external;
    function rely(address usr) external;
    function ilks(bytes32 ilk) external returns (address, uint256, uint256);
    function box() external returns (uint256);
    function litter() external returns (uint256);
    function bite(bytes32 ilk, address urn) external returns (uint256 id);
}

interface IGemJoin {
    function join(address usr, uint wad) external;
}

interface IFlipper {
    function rely(address usr) external;
    function bids(uint256 auction) external
        returns (uint256, uint256, address, uint48, uint48, address, address, uint256);
}

interface FlipLike {
    struct Bid {
        uint256 bid;
        uint256 lot;
        address guy;  // high bidder
        uint48  tic;  // expiry time
        uint48  end;
        address urn;
        address gal;
        uint256 tab;
    }
    function bids(uint) external view returns (
        uint256 bid,
        uint256 lot,
        address guy,
        uint48  tic,
        uint48  end,
        address usr,
        address gal,
        uint256 tab
    );
}

contract BiteTest is DSTest {
    IVat vat;
    ITestVow vow;
    ICat     cat;
    DSToken gold;
    IJug     jug;

    IGemJoin gemA;

    IFlipper flip;
    IFlapper flap;
    IFlopper flop;

    DSToken gov;

    address me;

    uint256 constant MLN = 10 ** 6;
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    uint256 constant RAD = 10 ** 45;

    function try_frob(bytes32 ilk, int ink, int art) public returns (bool ok) {
        string memory sig = "frob(bytes32,address,address,address,int256,int256)";
        address self = address(this);
        (ok,) = address(vat).call(abi.encodeWithSignature(sig, ilk, self, self, self, ink, art));
    }

    function ray(uint wad) internal pure returns (uint) {
        return wad * 10 ** 9;
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * 10 ** 27;
    }

    function gem(bytes32 ilk, address urn) internal view returns (uint) {
        return vat.gem(ilk, urn);
    }
    function ink(bytes32 ilk, address urn) internal view returns (uint) {
        (uint ink_, uint art_) = vat.urns(ilk, urn); art_;
        return ink_;
    }
    function art(bytes32 ilk, address urn) internal view returns (uint) {
        (uint ink_, uint art_) = vat.urns(ilk, urn); ink_;
        return art_;
    }

    function setUp1(address _vat, address _gov, address _flap, address _flop, address _vow) public {
        vat = IVat(_vat);

        gov = DSToken(_gov);
        gov.mint(100 ether);

        flap = IFlapper(_flap);
        flop = IFlopper(_flop);

        vow = ITestVow(_vow);
        flap.rely(address(vow));
        flop.rely(address(vow));
        flap.file("lid", rad(1000 ether));

        failed = false;
    }

    function setUp2(address _jug, address _cat, address _gold, address _gemA, address _flip) public {
        jug = IJug(_jug);
        jug.init("gold");
        jug.file("vow", address(vow));
        vat.rely(address(jug));

        cat = ICat(_cat);
        cat.file("vow", address(vow));
        cat.file("box", rad((10 ether) * MLN));
        vat.rely(address(cat));
        vow.rely(address(cat));

        gold = DSToken(_gold);
        gold.mint(1000 ether);

        vat.init("gold");
        gemA = IGemJoin(_gemA);
        vat.rely(address(gemA));
        gold.approve(address(gemA));
        gemA.join(address(this), 1000 ether);

        vat.file("gold", "spot", ray(1 ether));
        vat.file("gold", "line", rad(1000 ether));
        vat.file("Line",         rad(1000 ether));
        flip = IFlipper(_flip);
        flip.rely(address(cat));
        cat.rely(address(flip));
        cat.file("gold", "flip", address(flip));
        cat.file("gold", "chop", 1 ether);

        vat.rely(address(flip));
        vat.rely(address(flap));
        vat.rely(address(flop));

        vat.hope(address(flip));
        vat.hope(address(flop));
        gold.approve(address(vat));
        gov.approve(address(flap));

        me = address(this);

        failed = false;
    }

    function test_set_dunk_multiple_ilks() public {
        cat.file("gold",   "dunk", rad(111111 ether));
        (,, uint256 goldDunk) = cat.ilks("gold");
        assertEq(goldDunk, rad(111111 ether));
        cat.file("silver", "dunk", rad(222222 ether));
        (,, uint256 silverDunk) = cat.ilks("silver");
        assertEq(silverDunk, rad(222222 ether));
    }
    function test_cat_set_box() public {
        assertEq(cat.box(), rad((10 ether) * MLN));
        cat.file("box", rad((20 ether) * MLN));
        assertEq(cat.box(), rad((20 ether) * MLN));
    }
    function test_bite_under_dunk() public {
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold", me, me, me, 40 ether, 100 ether);
        // tag=4, mat=2
        vat.file("gold", 'spot', ray(2 ether));  // now unsafe

        cat.file("gold", "dunk", rad(111 ether));
        cat.file("gold", "chop", 1.1 ether);

        uint auction = cat.bite("gold", address(this));
        // the full CDP is liquidated
        assertEq(ink("gold", address(this)), 0);
        assertEq(art("gold", address(this)), 0);
        // all debt goes to the vow
        assertEq(vow.Awe(), rad(100 ether));
        // auction is for all collateral
        (, uint lot,,,,,, uint tab) = flip.bids(auction);
        assertEq(lot,        40 ether);
        assertEq(tab,   rad(110 ether));
    }
    function test_bite_over_dunk() public {
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold", me, me, me, 40 ether, 100 ether);
        // tag=4, mat=2
        vat.file("gold", 'spot', ray(2 ether));  // now unsafe

        cat.file("gold", "chop", 1.1 ether);
        cat.file("gold", "dunk", rad(82.5 ether));

        uint auction = cat.bite("gold", address(this));
        // the CDP is partially liquidated
        assertEq(ink("gold", address(this)), 10 ether);
        assertEq(art("gold", address(this)), 25 ether);
        // a fraction of the debt goes to the vow
        assertEq(vow.Awe(), rad(75 ether));
        // auction is for a fraction of the collateral
        (, uint lot,,,,,, uint tab) = FlipLike(address(flip)).bids(auction);
        assertEq(lot,       30 ether);
        assertEq(tab,   rad(82.5 ether));
    }

    // tests a partial lot liquidation that fill litterbox
//     function testSelfFail_fill_litterbox() public {
//         // spot = tag / (par . mat)
//         // tag=5, mat=2
//         vat.file("gold", 'spot', ray(2.5 ether));
//         vat.frob("gold", me, me, me, 100 ether, 150 ether);
// 
//         // tag=4, mat=2
//         vat.file("gold", 'spot', ray(1 ether));  // now unsafe
// 
//         assertEq(ink("gold", address(this)), 100 ether);
//         assertEq(art("gold", address(this)), 150 ether);
//         assertEq(vow.Woe(), 0 ether);
//         assertEq(gem("gold", address(this)), 900 ether);
// 
//         cat.file("box", rad(75 ether));
//         cat.file("gold", "dunk", rad(100 ether));
//         assertEq(cat.box(), rad(75 ether));
//         assertEq(cat.litter(), 0);
//         cat.bite("gold", address(this));
//         assertEq(cat.litter(), rad(75 ether));
//         assertEq(ink("gold", address(this)), 50 ether);
//         assertEq(art("gold", address(this)), 75 ether);
//         assertEq(vow.sin(now), rad(75 ether));
//         assertEq(gem("gold", address(this)), 900 ether);
// 
//         // this bite puts us over the litterbox
//         cat.bite("gold", address(this));
//         fail();
//     }

    // Tests for multiple bites where second bite has a dusty amount for room
//     function testSelfFail_dusty_litterbox() public {
//         // spot = tag / (par . mat)
//         // tag=5, mat=2
//         vat.file("gold", 'spot', ray(2.5 ether));
//         vat.frob("gold", me, me, me, 50 ether, 80 ether + 1);
// 
//         // tag=4, mat=2
//         vat.file("gold", 'spot', ray(1 ether));  // now unsafe
// 
//         assertEq(ink("gold", address(this)), 50 ether);
//         assertEq(art("gold", address(this)), 80 ether + 1);
//         assertEq(vow.Woe(), 0 ether);
//         assertEq(gem("gold", address(this)), 950 ether);
// 
//         cat.file("box",  rad(100 ether));
//         vat.file("gold", "dust", rad(20 ether));
//         cat.file("gold", "dunk", rad(100 ether));
// 
//         assertEq(cat.box(), rad(100 ether));
//         assertEq(cat.litter(), 0);
//         cat.bite("gold", address(this));
//         assertEq(cat.litter(), rad(80 ether + 1)); // room is now dusty
//         assertEq(ink("gold", address(this)), 0 ether);
//         assertEq(art("gold", address(this)), 0 ether);
//         assertEq(vow.sin(now), rad(80 ether + 1));
//         assertEq(gem("gold", address(this)), 950 ether);
// 
//         // spot = tag / (par . mat)
//         // tag=5, mat=2
//         vat.file("gold", 'spot', ray(2.5 ether));
//         vat.frob("gold", me, me, me, 100 ether, 150 ether);
// 
//         // tag=4, mat=2
//         vat.file("gold", 'spot', ray(1 ether));  // now unsafe
// 
//         assertEq(ink("gold", address(this)), 100 ether);
//         assertEq(art("gold", address(this)), 150 ether);
//         assertEq(vow.Woe(), 0 ether);
//         assertEq(gem("gold", address(this)), 850 ether);
// 
//         assertTrue(cat.box() - cat.litter() < rad(20 ether)); // room < dust
// 
//         // // this bite puts us over the litterbox
//         cat.bite("gold", address(this));
//         fail();
//     }

    function testSelfFail_null_auctions_dart_realistic_values() public {
        vat.file("gold", "dust", rad(100 ether));
        vat.file("gold", "spot", ray(2.5 ether));
        vat.file("gold", "line", rad(2000 ether));
        vat.file("Line",         rad(2000 ether));
        vat.fold("gold", address(vow), int256(ray(0.25 ether)));
        vat.frob("gold", me, me, me, 800 ether, 2000 ether);

        vat.file("gold", 'spot', ray(1 ether));  // now unsafe

        // slightly contrived value to leave tiny amount of room post-liquidation
        cat.file("box", rad(1130 ether) + 1);
        cat.file("gold", "dunk", rad(1130 ether));
        cat.file("gold", "chop", 1.13 ether);
        cat.bite("gold", me);
        assertEq(cat.litter(), rad(1130 ether));
        uint room = cat.box() - cat.litter();
        assertEq(room, 1);
        (, uint256 rate,,,) = vat.ilks("gold");
        (, uint256 chop,) = cat.ilks("gold");
        assertEq(room * (1 ether) / rate / chop, 0);

        // Biting any non-zero amount of debt would overflow the box,
        // so this should revert and not create a null auction.
        // In this case we're protected by the dustiness check on room.
        cat.bite("gold", me);
        fail();
    }

    function testSelfFail_null_auctions_dart_artificial_values() public {
        // artificially tiny dust value, e.g. due to misconfiguration
        vat.file("dust", "dust", 1);
        vat.file("gold", "spot", ray(2.5 ether));
        vat.frob("gold", me, me, me, 100 ether, 200 ether);

        vat.file("gold", 'spot', ray(1 ether));  // now unsafe

        // contrived value to leave tiny amount of room post-liquidation
        cat.file("box", rad(113 ether) + 2);
        cat.file("gold", "dunk", rad(113  ether));
        cat.file("gold", "chop", 1.13 ether);
        cat.bite("gold", me);
        assertEq(cat.litter(), rad(113 ether));
        uint room = cat.box() - cat.litter();
        assertEq(room, 2);
        (, uint256 rate,,,) = vat.ilks("gold");
        (, uint256 chop,) = cat.ilks("gold");
        assertEq(room * (1 ether) / rate / chop, 0);

        // Biting any non-zero amount of debt would overflow the box,
        // so this should revert and not create a null auction.
        // The dustiness check on room doesn't apply here, so additional
        // logic is needed to make this test pass.
        cat.bite("gold", me);
        fail();
    }

    function testSelfFail_null_auctions_dink_artificial_values() public {
        // we're going to make 1 wei of ink worth 250
        vat.file("gold", "spot", ray(250 ether) * 1 ether);
        cat.file("gold", "dunk", rad(50 ether));
        vat.frob("gold", me, me, me, 1, 100 ether);

        vat.file("gold", 'spot', 1);  // massive price crash, now unsafe

        // This should leave us with 0 dink value, and fail
        cat.bite("gold", me);
        fail();
    }

    function testSelfFail_null_auctions_dink_artificial_values_2() public {
        vat.file("gold", "spot", ray(2000 ether));
        vat.file("gold", "line", rad(20000 ether));
        vat.file("Line",         rad(20000 ether));
        vat.frob("gold", me, me, me, 10 ether, 15000 ether);

        cat.file("box", rad(1000000 ether));  // plenty of room

        // misconfigured dunk (e.g. precision factor incorrect in spell)
        cat.file("gold", "dunk", rad(100));

        vat.file("gold", 'spot', ray(1000 ether));  // now unsafe

        // This should leave us with 0 dink value, and fail
        cat.bite("gold", me);
        fail();
    }

    function testSelfFail_null_spot_value() public {
        // spot = tag / (par . mat)
        // tag=5, mat=2
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold", me, me, me, 100 ether, 150 ether);

        vat.file("gold", 'spot', ray(1 ether));  // now unsafe

        assertEq(ink("gold", address(this)), 100 ether);
        assertEq(art("gold", address(this)), 150 ether);
        assertEq(vow.Woe(), 0 ether);
        assertEq(gem("gold", address(this)), 900 ether);

        cat.file("gold", "dunk", rad(75 ether));
        assertEq(cat.litter(), 0);
        cat.bite("gold", address(this));
        assertEq(cat.litter(), rad(75 ether));
        assertEq(ink("gold", address(this)), 50 ether);
        assertEq(art("gold", address(this)), 75 ether);
        assertEq(vow.sin(now), rad(75 ether));
        assertEq(gem("gold", address(this)), 900 ether);

        vat.file("gold", 'spot', 0);

        // this should fail because spot is 0
        cat.bite("gold", address(this));
        fail();
    }

    function testSelfFail_vault_is_safe() public {
        // spot = tag / (par . mat)
        // tag=5, mat=2
        vat.file("gold", 'spot', ray(2.5 ether));
        vat.frob("gold", me, me, me, 100 ether, 150 ether);

        assertEq(ink("gold", address(this)), 100 ether);
        assertEq(art("gold", address(this)), 150 ether);
        assertEq(vow.Woe(), 0 ether);
        assertEq(gem("gold", address(this)), 900 ether);

        cat.file("gold", "dunk", rad(75 ether));
        assertEq(cat.litter(), 0);

        // this should fail because the vault is safe
        cat.bite("gold", address(this));
        fail();
    }
}

