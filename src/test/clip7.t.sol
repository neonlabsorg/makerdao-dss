// SPDX-License-Identifier: AGPL-3.0-or-later

// clip.t.sol -- tests for clip.sol

pragma solidity ^0.6.12;

import "./test.sol";
import "./guy.sol";

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

interface IValue {
    function poke(bytes32 wut) external;
}

interface IGuy {
    function hope(address usr) external;
    function take(uint256 id, uint256 amt, uint256 max, address who, bytes calldata data) external;
    function bark(IDog dog, bytes32 ilk, address urn, address usr) external;
}

interface IStairstepExponentialDecrease {
    function file(bytes32 what, uint256 data) external;
}

interface IPublicClip {
    function add() external returns (uint256);
    function count() external view returns (uint256);
    function active(uint256 id) external view returns (uint256);
    function remove(uint256 id) external;
    function sales(uint256 id) external returns (uint256, uint256, uint256, address, uint96, uint256);
}

contract ClipperTest7 is DSTest {
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
    IPublicClip pclip;
    
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

    modifier takeSetup {
        uint256 pos;
        uint256 tab;
        uint256 lot;
        address usr;
        uint96  tic;
        uint256 top;
        uint256 ink;
        uint256 art;

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
        dog.bark(ilk, me, address(this));
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

    function setUp2(address _dog, address _pip, address _clip, address _ali, address _bob, address _calc, address _pclip) public {
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

        pclip = IPublicClip(_pclip);

        failed = false;
    }

    function test_remove_id() public {
        uint256 pos;

        pclip.add();
        pclip.add();
        uint256 id = pclip.add();
        pclip.add();
        pclip.add();

        // [1,2,3,4,5]
        assertEq(pclip.count(), 5);   // 5 elements added
        assertEq(pclip.active(0), 1);
        assertEq(pclip.active(1), 2);
        assertEq(pclip.active(2), 3);
        assertEq(pclip.active(3), 4);
        assertEq(pclip.active(4), 5);

        pclip.remove(id);

        // [1,2,5,4]
        assertEq(pclip.count(), 4);
        assertEq(pclip.active(0), 1);
        assertEq(pclip.active(1), 2);
        assertEq(pclip.active(2), 5);  // Swapped last for middle
        (pos,,,,,) = pclip.sales(5);
        assertEq(pos, 2);
        assertEq(pclip.active(3), 4);

        pclip.remove(4);

        // [1,2,5]
        assertEq(pclip.count(), 3);

        (pos,,,,,) = pclip.sales(1);
        assertEq(pos, 0); // Sale 1 in slot 0
        assertEq(pclip.active(0), 1);

        (pos,,,,,) = pclip.sales(2);
        assertEq(pos, 1); // Sale 2 in slot 1
        assertEq(pclip.active(1), 2);

        (pos,,,,,) = pclip.sales(5);
        assertEq(pos, 2); // Sale 5 in slot 2
        assertEq(pclip.active(2), 5); // Final element removed

        (pos,,,,,) = pclip.sales(4);
        assertEq(pos, 0); // Sale 4 was deleted. Returns 0
    }

    function testSelfFail_id_out_of_range() public {
        pclip.add();
        pclip.add();

        pclip.active(9); // Fail because id is out of range

        fail();
    }
}
