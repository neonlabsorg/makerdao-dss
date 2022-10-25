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
    function bark_with_timestamp(IDog dog, bytes32 ilk, address urn, address usr, uint256 timestamp) external;
}

interface IStairstepExponentialDecrease {
    function file(bytes32 what, uint256 data) external;
}

contract ClipperTest4 is DSTest {
    IVat     vat;
    IDog     dog;
    ISpotter spot;
    IVow     vow;
    IValue pip;
    IValue pip2;
    IToken gold;
    IGemJoin goldJoin;
    IToken dai;
    IDaiJoin daiJoin;

    IClipper clip;
    IClipper clip2;

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

    function setUp2(address _dog, address _pip, address _pip2, address _clip, address _clip2, address _ali, address _bob, address _calc) public {
        dog = IDog(_dog);
        dog.file("vow", address(vow));
        vat.rely(address(dog));
        vow.rely(address(dog));

        vat.init(ilk);

        vat.slip(ilk, me, 1000 ether);

        pip = IValue(_pip);
        pip2 = IValue(_pip2);
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
        clip2 = IClipper(_clip2);
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

    function test_Clipper_yank(uint256 timestamp) public takeSetup(timestamp) {
        uint256 preGemBalance = vat.gem(ilk, address(this));
        (,, uint256 origLot,,,) = clip.sales(1);

        uint startGas = gasleft();
        clip.yank(1);
        uint endGas = gasleft();
        emit log_named_uint("yank gas", startGas - endGas);

        // Assert that the auction was deleted.
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);

        // Assert that callback to clear dirt was successful.
        assertEq(dog.Dirt(), 0);
        (,,, uint256 dirt) = dog.ilks(ilk);
        assertEq(dirt, 0);

        // Assert transfer of gem.
        assertEq(vat.gem(ilk, address(this)), preGemBalance + origLot);
    }

    function test_gas_bark_kick(uint256 timestamp) public {
        // Assertions to make sure setup is as expected.
        assertEq(clip.kicks(), 0);
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);
        assertEq(vat.gem(ilk, me), 960 ether);
        assertEq(vat.dai(ali), rad(1000 ether));
        (ink, art) = vat.urns(ilk, me);
        assertEq(ink, 40 ether);
        assertEq(art, 100 ether);

        uint256 preGas = gasleft();
        IGuy(ali).bark_with_timestamp(dog, ilk, me, ali, timestamp);
        uint256 diffGas = preGas - gasleft();
        log_named_uint("bark with kick gas", diffGas);
    }

    function test_gas_partial_take(uint256 timestamp) public takeSetup(timestamp) {
        uint256 preGas = gasleft();
        // Bid so owe (= 11 * 5 = 55 RAD) < tab (= 110 RAD)
        IGuy(ali).take({
            id:  1,
            amt: 11 ether,     // Half of tab at $110
            max: ray(5 ether),
            who: ali,
            data: ""
        });
        uint256 diffGas = preGas - gasleft();
        log_named_uint("partial take gas", diffGas);

        assertEq(vat.gem(ilk, ali), 11 ether);  // Didn't take whole lot
        assertEq(vat.dai(ali), rad(945 ether)); // Paid half tab (55)
        assertEq(vat.gem(ilk, me), 960 ether);  // Collateral not returned (yet)

        // Assert auction DOES NOT end
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, rad(55 ether));  // 110 - 5 * 11
        assertEq(lot, 29 ether);       // 40 - 11
        assertEq(usr, me);
        assertEq(uint256(tic), now);
        assertEq(top, ray(5 ether));
    }

    function test_gas_full_take(uint256 timestamp) public takeSetup(timestamp) {
        uint256 preGas = gasleft();
        // Bid so owe (= 25 * 5 = 125 RAD) > tab (= 110 RAD)
        // Readjusts slice to be tab/top = 25
        IGuy(ali).take({
            id:  1,
            amt: 25 ether,
            max: ray(5 ether),
            who: ali,
            data: ""
        });
        uint256 diffGas = preGas - gasleft();
        log_named_uint("full take gas", diffGas);

        assertEq(vat.gem(ilk, ali), 22 ether);  // Didn't take whole lot
        assertEq(vat.dai(ali), rad(890 ether)); // Didn't pay more than tab (110)
        assertEq(vat.gem(ilk, me),  978 ether); // 960 + (40 - 22) returned to usr

        // Assert auction ends
        (pos, tab, lot, usr, tic, top) = clip.sales(1);
        assertEq(pos, 0);
        assertEq(tab, 0);
        assertEq(lot, 0);
        assertEq(usr, address(0));
        assertEq(uint256(tic), 0);
        assertEq(top, 0);
    }
}
