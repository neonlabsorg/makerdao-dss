// SPDX-License-Identifier: AGPL-3.0-or-later

// clip.t.sol -- tests for clip.sol

pragma solidity ^0.6.12;

import "./test.sol";

interface IVat {
    function dai(address u) external returns (uint256); // [rad]
    function gem(bytes32 ilk, address usr) external view returns (uint); // [wad]
    function urns(bytes32 ilk, address usr) external view returns (uint256, uint256);
    function ilks(bytes32 ilk) external returns (uint256, uint256, uint256, uint256, uint256);

    function slip(bytes32 ilk, address usr, int256 wad) external;
    function hope(address usr) external;
    function init(bytes32 ilk) external;
    function suck(address u, address v, uint rad) external;
    function file(bytes32 what, uint data) external;
    function file(bytes32 ilk, bytes32 what, uint data) external;
    function rely(address usr) external;
    function frob(bytes32 i, address u, address v, address w, int dink, int dart) external;
    function fold(bytes32 i, address u, int rate) external;
}

interface ISpotter {
    function file(bytes32 ilk, bytes32 what, address pip_) external;
    function file(bytes32 what, uint data) external;
    function file(bytes32 ilk, bytes32 what, uint data) external;
    function poke(bytes32 ilk) external;
}

interface IVow {
    function rely(address usr) external;
}

interface IToken {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function approve(address guy) external returns (bool);
    function mint(uint wad) external;
    function transfer(address dst, uint wad) external returns (bool);
    function setOwner(address owner_) external;
    function balanceOf(address user) external returns (uint256);
}

interface IGemJoin {
    function exit(address usr, uint wad) external;
}

interface IDaiJoin {
    function join(address usr, uint wad) external;
}

interface IExchange {
    function sellGold(uint256 goldAmt) external;
}

interface IDog {
    function bark_with_timestamp(bytes32 ilk, address urn, address kpr, uint256 timestamp) external returns (uint256 id);
    function file(bytes32 what, address data) external;
    function file(bytes32 what, uint256 data) external;
    function file(bytes32 ilk, bytes32 what, uint256 data) external;
    function file(bytes32 ilk, bytes32 what, address clip) external;
    function rely(address usr) external;
    function chop(bytes32 ilk) external view returns (uint256);
    function ilks(bytes32 ilk) external returns (address, uint256, uint256, uint256);
    function Dirt() external returns (uint256);
}

interface IValue {
    function poke(bytes32 wut) external;
}

interface IClipper {
    function take(uint256 id, uint256 amt, uint256 max, address who, bytes calldata data) external;
    function redo(uint256 id, address kpr) external;
    function kick(uint256 tab, uint256 lot, address usr, address kpr) external returns (uint256);
    function vat() external returns (address);
    function dog() external returns (address);
    function file(bytes32 what, uint256 data) external;
    function file(bytes32 what, address data) external;
    function yank(uint256 id) external;
    function kicks() external returns (uint256);
    function sales(uint256 id) external returns (uint256, uint256, uint256, address, uint96, uint256);
    function upchost() external;
    function rely(address usr) external;
    function getStatus(uint256 id) external view returns (bool, uint256, uint256, uint256);
    function chost() external returns (uint256);
    function chip() external returns (uint64);
    function tip() external returns (uint192);
    function stopped() external returns (uint256);
}

interface IGuy {
    function hope(address usr) external;
    function take(uint256 id, uint256 amt, uint256 max, address who, bytes calldata data) external;
}

interface IStairstepExponentialDecrease {
    function file(bytes32 what, uint256 data) external;
}

contract ClipperTest8 is DSTest {
    IVat     vat;
    IDog     dog;
    ISpotter spot;
    IVow     vow;
    IValue pip;
    IToken gold;
    IGemJoin goldJoin;
    IToken dai;
    IDaiJoin daiJoin;
    IClipper clip;
    IStairstepExponentialDecrease calc;

    address me;
    IExchange exchange;

    address ali;
    address bob;

    uint256 WAD = 10 ** 18;
    uint256 RAY = 10 ** 27;
    uint256 RAD = 10 ** 45;

    bytes32 constant ilk = "gold";
    uint256 constant goldPrice = 5 ether;

    uint256 constant startTime = 604411200; // Used to avoid issues with `now`

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function _ink(bytes32 ilk_, address urn_) internal view returns (uint256) {
        (uint256 ink_,) = vat.urns(ilk_, urn_);
        return ink_;
    }
    function _art(bytes32 ilk_, address urn_) internal view returns (uint256) {
        (,uint256 art_) = vat.urns(ilk_, urn_);
        return art_;
    }

    uint256 pos;
    uint256 tab;
    uint256 lot;
    address usr;
    uint96  tic;
    uint256 top;
    uint256 ink;
    uint256 art;
    uint256 rate;

    modifier takeSetup(uint256 timestamp) {
        calc.file("cut",  RAY - ray(0.01 ether));  // 1% decrease
        calc.file("step", 1);                      // Decrease every 1 second

        clip.file("buf",  ray(1.25 ether));   // 25% Initial price buffer
        clip.file("calc", address(calc));     // File price contract
        clip.file("cusp", ray(0.3 ether));    // 70% drop before reset
        clip.file("tail", 3600);              // 1 hour before reset

        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 40 ether);
        assertEq(art, 100 ether);

        assertEq(clip.kicks(), 0);
        dog.bark_with_timestamp(ilk, me, address(this), timestamp);
        assertEq(clip.kicks(), 1);

        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 0);
        assertEq(art, 0);

        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, rad(110 ether));
        assertEq(lot, 40 ether);
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(5 ether)); // $4 plus 25%

        assertEq(vat.gem(ilk, ali), 0);
        assertEq(vat.dai(ali), rad(1000 ether));
        assertEq(vat.gem(ilk, bob), 0);
        assertEq(vat.dai(bob), rad(1000 ether));

        _;
    }

    function ray(uint256 wad) internal pure returns (uint256) {
        return wad * 10 ** 9;
    }
    function rad(uint256 wad) internal pure returns (uint256) {
        return wad * 10 ** 27;
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function setUp1(address _vat, address _spot, address _vow, address _gold, address _goldJoin, address _dai, address _daiJoin, address _exchange) public {
        me = address(this);

        vat = IVat(_vat);
        spot = ISpotter(_spot);
        vat.rely(address(spot));

        vow = IVow(_vow);        
        gold = IToken(_gold);
        goldJoin = IGemJoin(_goldJoin);
        vat.rely(address(goldJoin));

        dai = IToken(_dai);
        daiJoin = IDaiJoin(_daiJoin);
        vat.suck(address(0), address(daiJoin), rad(1000 ether));
        exchange = IExchange(_exchange);

        dai.mint(1000 ether);
        dai.transfer(address(exchange), 1000 ether);
        dai.setOwner(address(daiJoin));
        gold.mint(1000 ether);
        gold.transfer(address(goldJoin), 1000 ether);

        failed = false;
    }

    function setUp2(address _dog, address _pip, address _clip, address _ali, address _bob, address _calc) public {
        dog = IDog(_dog);
        dog.file("vow", address(vow));
        vat.rely(address(dog));
        vow.rely(address(dog));

        vat.init(ilk);

        vat.slip(ilk, me, 1000 ether);

        pip = IValue(_pip);
        pip.poke(bytes32(goldPrice)); // Spot = $2.5

        spot.file(ilk, "pip", address(pip));
        spot.file(ilk, "mat", ray(2 ether)); // 200% liquidation ratio for easier test calcs
        spot.poke(ilk);

        vat.file(ilk, "dust", rad(20 ether)); // $20 dust
        vat.file(ilk, "line", rad(10000 ether));
        vat.file("Line",      rad(10000 ether));

        dog.file(ilk, "chop", 1.1 ether); // 10% chop
        dog.file(ilk, "hole", rad(1000 ether));
        dog.file("Hole", rad(1000 ether));

        // dust and chop filed previously so clip.chost will be set correctly
        clip = IClipper(_clip);
        clip.upchost();
        clip.rely(address(dog));

        dog.file(ilk, "clip", address(clip));
        dog.rely(address(clip));
        vat.rely(address(clip));

        assertEq(vat.gem(ilk, me), 1000 ether);
        assertEq(vat.dai(me), 0);
        vat.frob(ilk, me, me, me, 40 ether, 100 ether);
        assertEq(vat.gem(ilk, me), 960 ether);
        assertEq(vat.dai(me), rad(100 ether));

        pip.poke(bytes32(uint256(4 ether))); // Spot = $2
        spot.poke(ilk);          // Now unsafe

        ali = _ali;
        bob = _bob;

        vat.hope(address(clip));
        IGuy(ali).hope(address(clip));
        IGuy(bob).hope(address(clip));

        vat.suck(address(0), address(this), rad(1000 ether));
        vat.suck(address(0), ali,  rad(1000 ether));
        vat.suck(address(0), bob,  rad(1000 ether));
        
        calc = IStairstepExponentialDecrease(_calc);

        failed = false;
    }

    function try_bark(bytes32 ilk_, address urn_, uint256 timestamp) internal returns (bool ok) {
        string memory sig = "bark_with_timestamp(bytes32,address,address,uint256)";
        (ok,) = address(dog).call(abi.encodeWithSignature(sig, ilk_, urn_, address(this), timestamp));
    }

    function test_bark_not_leaving_dust_rate(uint256 timestamp) public {
        vat.fold(ilk, address(vow), int256(ray(0.02 ether)));
        (, rate,,,) = vat.ilks(ilk);
        assertEq(rate, ray(1.02 ether));

        dog.file(ilk, "hole", 100 * RAD);   // Makes room = 100 RAD
        dog.file(ilk, "chop",   1 ether);   // 0% chop for precise calculations
        vat.file(ilk, "dust",  20 * RAD);   // 20 DAI minimum Vault debt
        clip.upchost();

        assertEq(clip.kicks(), 0);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 40 ether);
        assertEq(art, 100 ether);  // Full debt is 102 DAI since rate = 1.02 * RAY

        // (art - dart) * rate ~= 2 RAD < dust = 20 RAD
        //   => remnant would be dusty, so a full liquidation occurs.
        assertTrue(try_bark(ilk, me, timestamp));

        assertEq(clip.kicks(), 1);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, mul(100 ether, rate));  // No chop
        assertEq(lot, 40 ether);
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(4 ether));
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 0);
        assertEq(art, 0);
    }

    function test_bark_only_leaving_dust_over_hole_rate(uint256 timestamp) public {
        vat.fold(ilk, address(vow), int256(ray(0.02 ether)));
        (, rate,,,) = vat.ilks(ilk);
        assertEq(rate, ray(1.02 ether));

        dog.file(ilk, "hole", 816 * RAD / 10);  // Makes room = 81.6 RAD => dart = 80
        dog.file(ilk, "chop",   1 ether);       // 0% chop for precise calculations
        vat.file(ilk, "dust", 204 * RAD / 10);  // 20.4 DAI dust
        clip.upchost();

        assertEq(clip.kicks(), 0);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 40 ether);
        assertEq(art, 100 ether);

        // (art - dart) * rate = 20.4 RAD == dust
        //   => marginal threshold at which partial liquidation is acceptable
        assertTrue(try_bark(ilk, me, timestamp));

        assertEq(clip.kicks(), 1);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 816 * RAD / 10);  // Equal to ilk.hole
        assertEq(lot, 32 ether);
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(4 ether));
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 8 ether);
        assertEq(art, 20 ether);
        (,,,, uint256 dust) = vat.ilks(ilk);
        assertEq(art * rate, dust);
    }

    function test_bark_not_leaving_dust(uint256 timestamp) public {
        dog.file(ilk, "hole", rad(80 ether)); // Makes room = 80 WAD
        dog.file(ilk, "chop", 1 ether); // 0% chop (for precise calculations)

        assertEq(clip.kicks(), 0);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 40 ether);
        assertEq(art, 100 ether);

        assertTrue(try_bark(ilk, me, timestamp)); // art - dart = 100 - 80 = dust (= 20)

        assertEq(clip.kicks(), 1);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, rad(80 ether)); // No chop
        assertEq(lot, 32 ether);
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(4 ether));
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 8 ether);
        assertEq(art, 20 ether);
    }

    function test_bark_not_leaving_dust_over_hole(uint256 timestamp) public {
        dog.file(ilk, "hole", rad(80 ether) + ray(1 ether)); // Makes room = 80 WAD + 1 wei
        dog.file(ilk, "chop", 1 ether); // 0% chop (for precise calculations)

        assertEq(clip.kicks(), 0);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 40 ether);
        assertEq(art, 100 ether);

        assertTrue(try_bark(ilk, me, timestamp)); // art - dart = 100 - (80 + 1 wei) < dust (= 20) then the whole debt is taken

        assertEq(clip.kicks(), 1);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, rad(100 ether)); // No chop
        assertEq(lot, 40 ether);
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(4 ether));
        assertEq(vat.gem(ilk, me), 960 ether);
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 0 ether);
        assertEq(art, 0 ether);
    }
    
    function test_partial_liquidation_hole_limit(uint256 timestamp) public {
        dog.file(ilk, "hole", rad(75 ether));

        assertEq(_ink(ilk, me), 40 ether);
        assertEq(_art(ilk, me), 100 ether);

        assertEq(dog.Dirt(), 0);
        (,uint256 chop_,, uint256 dirt_) = dog.ilks(ilk);
        assertEq(dirt_, 0);

        dog.bark_with_timestamp(ilk, me, address(this), timestamp);

        (, uint256 tab_, uint256 lot_,,,) = clip.sales(1);

        (, uint256 rate_,,,) = vat.ilks(ilk);

        assertEq(lot_, 40 ether * (tab_ * WAD / rate_ / chop_) / 100 ether);
        assertEq(tab_, rad(75 ether) - ray(0.2 ether)); // 0.2 RAY rounding error

        assertEq(_ink(ilk, me), 40 ether - lot_);
        assertEq(_art(ilk, me), 100 ether - tab_ * WAD / rate_ / chop_);

        assertEq(dog.Dirt(), tab_);
        (,,, dirt_) = dog.ilks(ilk);
        assertEq(dirt_, tab_);
    }
    
    function test_partial_liquidation_Hole_limit(uint256 timestamp) public {
        dog.file("Hole", rad(75 ether));

        assertEq(_ink(ilk, me), 40 ether);
        assertEq(_art(ilk, me), 100 ether);

        assertEq(dog.Dirt(), 0);
        (,uint256 chop_,, uint256 dirt_) = dog.ilks(ilk);
        assertEq(dirt_, 0);

        dog.bark_with_timestamp(ilk, me, address(this), timestamp);

        (, uint256 tab_, uint256 lot_,,,) = clip.sales(1);

        (, uint256 rate_,,,) = vat.ilks(ilk);

        assertEq(lot_, 40 ether * (tab_ * WAD / rate_ / chop_) / 100 ether);
        assertEq(tab_, rad(75 ether) - ray(0.2 ether)); // 0.2 RAY rounding error

        assertEq(_ink(ilk, me), 40 ether - lot_);
        assertEq(_art(ilk, me), 100 ether - tab_ * WAD / rate_ / chop_);

        assertEq(dog.Dirt(), tab_);
        (,,, dirt_) = dog.ilks(ilk);
        assertEq(dirt_, tab_);
    }

    function try_take(uint256 id, uint256 amt, uint256 max, address who, bytes memory data) internal returns (bool ok) {
        string memory sig = "take(uint256,uint256,uint256,address,bytes)";
        (ok,) = address(clip).call(abi.encodeWithSignature(sig, id, amt, max, who, data));
    }

    function test_take_zero_usr(uint256 timestamp) public takeSetup(timestamp) {
        // Auction id 2 is unpopulated.
        (,,, address usr_,,) = clip.sales(2);
        assertEq(usr_, address(0));
        assertTrue(!try_take(2, 25 ether, ray(5 ether), ali, ""));
    }
    
    function test_take_over_tab(uint256 timestamp) public takeSetup(timestamp) {
        // Bid so owe (= 25 * 5 = 125 RAD) > tab (= 110 RAD)
        // Readjusts slice to be tab/top = 25
        IGuy(ali).take({
            id:  1,
            amt: 25 ether,
            max: ray(5 ether),
            who: ali,
            data: ""
        });

        assertEq(vat.gem(ilk, ali), 22 ether);  // Didn't take whole lot
        assertEq(vat.dai(ali), rad(890 ether)); // Didn't pay more than tab (110)
        assertEq(vat.gem(ilk, me),  978 ether); // 960 + (40 - 22) returned to usr

        // Assert auction ends
        (uint256 pos_, uint256 tab_, uint256 lot_, address usr_, uint256 tic_, uint256 top_) = clip.sales(1);
        assertEq(pos_, 0);
        assertEq(tab_, 0);
        assertEq(lot_, 0);
        assertEq(usr_, address(0));
        assertEq(uint256(tic_), 0);
        assertEq(top_, 0);

        assertEq(dog.Dirt(), 0);
        (,,, uint256 dirt_) = dog.ilks(ilk);
        assertEq(dirt_, 0);
    }
}
