// SPDX-License-Identifier: AGPL-3.0-or-later

// end.t.sol -- global settlement tests

pragma solidity ^0.6.12;

import "./test.sol";

interface IVat {
    function frob(bytes32 i, address u, address v, address w, int dink, int dart) external;
    function flux(bytes32 ilk, address src, address dst, uint256 wad) external;
    function move(address src, address dst, uint256 rad) external;
    function hope(address usr) external;
    function dai(address u) external view returns (uint256); // [rad]
    function gem(bytes32 ilk, address usr) external view returns (uint); // [wad]
    function urns(bytes32 ilk, address usr) external view returns (uint256, uint256);
    function ilks(bytes32 ilk) external view returns (uint256, uint256, uint256, uint256, uint256);
    function init(bytes32 ilk) external;
    function file(bytes32 what, uint data) external;
    function file(bytes32 ilk, bytes32 what, uint data) external;
    function rely(address usr) external;
    function live() external returns (uint256); // Active Flag
    function fold(bytes32 i, address u, int rate) external;
    function sin(address u) external returns (uint256); // [rad]
    function vice() external returns (uint256); // Total Unbacked Dai  [rad]
    function debt() external returns (uint256); // Total Dai Issued    [rad]
}

interface IToken {
    function setOwner(address owner_) external;
    function mint(uint wad) external;
    function mint(address guy, uint wad) external;
    function approve(address guy) external returns (bool);
    function approve(address guy, uint wad) external returns (bool);
    function balanceOf(address user) external view returns (uint256);
}

interface IFlapper {
    function rely(address usr) external;
    function live() external returns (uint);
}

interface IFlopper {
    function rely(address usr) external;
    function live() external returns (uint);
}

interface IVow {
    function rely(address usr) external;
    function flopper() external returns (address);
    function flapper() external returns (address);
    function live() external returns (uint256); // Active Flag
}

interface IPot {
    function file(bytes32 what, uint256 data) external;
    function file(bytes32 what, address addr) external;
    function rely(address guy) external;
    function live() external returns (uint256); // Active Flag
    function drip() external returns (uint);
    function dsr() external returns (uint256); // The Dai Savings Rate          [ray]
}

interface ICat {
    function file(bytes32 what, address data) external;
    function file(bytes32 what, uint256 data) external;
    function file(bytes32 ilk, bytes32 what, uint256 data) external;
    function file(bytes32 ilk, bytes32 what, address flip) external;
    function rely(address usr) external;
    function live() external returns (uint256); // Active Flag
}

interface IDog {
    function bark(bytes32 ilk, address urn, address kpr) external returns (uint256 id);
    function file(bytes32 what, address data) external;
    function file(bytes32 what, uint256 data) external;
    function file(bytes32 ilk, bytes32 what, uint256 data) external;
    function file(bytes32 ilk, bytes32 what, address clip) external;
    function rely(address usr) external;
    function Dirt() external returns (uint256);
}

interface ISpotter {
    function file(bytes32 ilk, bytes32 what, address pip_) external;
    function file(bytes32 what, uint data) external;
    function file(bytes32 ilk, bytes32 what, uint data) external;
    function poke(bytes32 ilk) external;
    function rely(address guy) external;
}

interface ICure {
    function rely(address usr) external;
}

interface IEnd {
    function free(bytes32 ilk) external;
    function pack(uint256 wad) external;
    function cash(bytes32 ilk, uint256 wad) external;
    function file(bytes32 what, address data) external;
    function file(bytes32 what, uint256 data) external;
    function live() external returns (uint256); // Active Flag
    function cage() external;
    function cage(bytes32 ilk) external;
    function tag(bytes32 ilk) external returns (uint256); // Cage price              [ray]
    function snip(bytes32 ilk, uint256 id) external;
    function Art(bytes32 ilk) external returns (uint256); // Total debt per ilk      [wad]
}

interface IGemJoin {
    function exit(address usr, uint wad) external;
    function join(address usr, uint wad) external;
}

interface IValue {
    function poke(bytes32 wut) external;
}

interface IFlipper {
    function rely(address usr) external;
}

interface IClipper {
    function rely(address usr) external;
    function sales(uint256 id) external returns (uint256, uint256, uint256, address, uint96, uint256);
}

contract Usr {
    IVat public vat;
    IEnd public end;

    constructor(IVat vat_, IEnd end_) public {
        vat  = vat_;
        end  = end_;
    }
    function frob(bytes32 ilk, address u, address v, address w, int dink, int dart) public {
        vat.frob(ilk, u, v, w, dink, dart);
    }
    function flux(bytes32 ilk, address src, address dst, uint256 wad) public {
        vat.flux(ilk, src, dst, wad);
    }
    function move(address src, address dst, uint256 rad) public {
        vat.move(src, dst, rad);
    }
    function hope(address usr) public {
        vat.hope(usr);
    }
    function exit(IGemJoin gemA, address usr, uint wad) public {
        gemA.exit(usr, wad);
    }
    function free(bytes32 ilk) public {
        end.free(ilk);
    }
    function pack(uint256 rad) public {
        end.pack(rad);
    }
    function cash(bytes32 ilk, uint wad) public {
        end.cash(ilk, wad);
    }
}

contract EndTest is DSTest {
    IVat   vat;
    IEnd   end;
    IVow   vow;
    IPot   pot;
    ICat   cat;
    IDog   dog;

    ISpotter spot;

    ICure cure;
    
    IToken gov;
    IToken coin;
    
    IGemJoin gemA;
    IValue pip;
    
    struct Ilk {
        IValue pip;
        IToken gem;
        IGemJoin gemA;
        IFlipper flip;
        IClipper clip;
    }

    mapping (bytes32 => Ilk) ilks;

    IFlapper flap;
    IFlopper flop;
    IFlipper flip;
    IClipper clip;

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;
    uint constant MLN = 10 ** 6;

    function ray(uint wad) internal pure returns (uint) {
        return wad * 10 ** 9;
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * RAY;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / RAY;
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        (x >= y) ? z = y : z = x;
    }
    function dai(address urn) internal view returns (uint) {
        return vat.dai(urn) / RAY;
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
    function Art(bytes32 ilk) internal view returns (uint) {
        (uint Art_, uint rate_, uint spot_, uint line_, uint dust_) = vat.ilks(ilk);
        rate_; spot_; line_; dust_;
        return Art_;
    }
    function balanceOf(bytes32 ilk, address usr) internal view returns (uint) {
        return ilks[ilk].gem.balanceOf(usr);
    }

    function try_pot_file(bytes32 what, uint data) public returns(bool ok) {
        string memory sig = "file(bytes32, uint)";
        (ok,) = address(pot).call(abi.encodeWithSignature(sig, what, data));
    }

    function init_collateral(bytes32 name) internal returns (Ilk memory) {
        coin.mint(500_000 ether);

        spot.file(name, "pip", address(pip));
        spot.file(name, "mat", ray(2 ether));
        // initial collateral price of 6
        pip.poke(bytes32(6 * WAD));
        spot.poke(name);

        vat.init(name);
        vat.file(name, "line", rad(1_000_000 ether));

        coin.approve(address(gemA));
        coin.approve(address(vat));

        vat.rely(address(gemA));

        vat.hope(address(flip));
        flip.rely(address(end));
        flip.rely(address(cat));
        cat.rely(address(flip));
        cat.file(name, "flip", address(flip));
        cat.file(name, "chop", 1 ether);
        cat.file(name, "dunk", rad(25000 ether));
        cat.file("box", rad((10 ether) * MLN));

        vat.rely(address(clip));
        vat.hope(address(clip));
        clip.rely(address(end));
        clip.rely(address(dog));
        dog.rely(address(clip));
        dog.file(name, "clip", address(clip));
        dog.file(name, "chop", 1.1 ether);
        dog.file(name, "hole", rad(25000 ether));
        dog.file("Hole", rad((25000 ether)));

        ilks[name].pip = pip;
        ilks[name].gem = coin;
        ilks[name].gemA = gemA;
        ilks[name].flip = flip;
        ilks[name].clip = clip;

        return ilks[name];
    }

    function setUp1(address _vat, address _gov, address _flap, address _flop, address _vow, address _pot, address _cat, address _dog) public {
        vat = IVat(_vat);
        gov = IToken(_gov);
        flap = IFlapper(_flap);
        flop = IFlopper(_flop);
        gov.setOwner(address(flop));

        vow = IVow(_vow);

        pot = IPot(_pot);
        vat.rely(address(pot));
        pot.file("vow", address(vow));

        cat = ICat(_cat);
        cat.file("vow", address(vow));
        vat.rely(address(cat));
        vow.rely(address(cat));

        dog = IDog(_dog);
        dog.file("vow", address(vow));
        vat.rely(address(dog));
        vow.rely(address(dog));
    
        failed = false;
    }

    function setUp2(address _spot, address _cure, address _end, address _coin, address _pip, address _gemA, address _flip, address _clip) public {
        spot = ISpotter(_spot);
        vat.file("Line",         rad(1_000_000 ether));
        vat.rely(address(spot));

        cure = ICure(_cure);

        end = IEnd(_end);
        end.file("vat", address(vat));
        end.file("cat", address(cat));
        end.file("dog", address(dog));
        end.file("vow", address(vow));
        end.file("pot", address(pot));
        end.file("spot", address(spot));
        end.file("cure", address(cure));
        end.file("wait", 1 hours);
        vat.rely(address(end));
        vow.rely(address(end));
        spot.rely(address(end));
        pot.rely(address(end));
        cat.rely(address(end));
        dog.rely(address(end));
        cure.rely(address(end));
        flap.rely(address(vow));
        flop.rely(address(vow));
        
        coin = IToken(_coin);
        pip = IValue(_pip);
        gemA = IGemJoin(_gemA);
        flip = IFlipper(_flip);
        clip = IClipper(_clip);

        failed = false;
    }

    function test_cage_basic() public {
        assertEq(end.live(), 1);
        assertEq(vat.live(), 1);
        assertEq(cat.live(), 1);
        assertEq(vow.live(), 1);
        assertEq(pot.live(), 1);
        assertEq(IFlopper(vow.flopper()).live(), 1);
        assertEq(IFlapper(vow.flapper()).live(), 1);
        end.cage();
        assertEq(end.live(), 0);
        assertEq(vat.live(), 0);
        assertEq(cat.live(), 0);
        assertEq(vow.live(), 0);
        assertEq(pot.live(), 0);
        assertEq(IFlopper(vow.flopper()).live(), 0);
        assertEq(IFlapper(vow.flapper()).live(), 0);
    }

    function test_cage_pot_drip() public {
        assertEq(pot.live(), 1);
        pot.drip();
        end.cage();

        assertEq(pot.live(), 0);
        assertEq(pot.dsr(), 10 ** 27);
        assertTrue(!try_pot_file("dsr", 10 ** 27 + 1));
    }

    // -- Scenario where there is one collateralised CDP
    // -- undergoing auction at the time of cage
    function test_cage_snip() public {
        Ilk memory gold = init_collateral("gold");

        Usr ali = new Usr(vat, end);

        vat.fold("gold", address(vow), int256(ray(0.25 ether)));

        // Make a CDP:
        address urn1 = address(ali);
        gold.gemA.join(urn1, 10 ether);
        ali.frob("gold", urn1, urn1, urn1, 10 ether, 15 ether);
        (uint ink1, uint art1) = vat.urns("gold", urn1); // CDP before liquidation
        (, uint rate,,,) = vat.ilks("gold");

        assertEq(vat.gem("gold", urn1), 0);
        assertEq(rate, ray(1.25 ether));
        assertEq(ink1, 10 ether);
        assertEq(art1, 15 ether);

        vat.file("gold", "spot", ray(1 ether)); // Now unsafe

        uint256 id = dog.bark("gold", urn1, address(this));

        uint256 tab1;
        uint256 lot1;
        {
            uint256 pos1;
            address usr1;
            uint96  tic1;
            uint256 top1;
            (pos1, tab1, lot1, usr1, tic1, top1) = gold.clip.sales(id);
            assertEq(pos1, 0);
            assertEq(tab1, art1 * rate * 1.1 ether / WAD); // tab uses chop
            assertEq(lot1, ink1);
            assertEq(usr1, address(ali));
            assertEq(uint256(tic1), now);
            assertEq(uint256(top1), ray(6 ether));
        }

        assertEq(dog.Dirt(), tab1);

        {
            (uint ink2, uint art2) = vat.urns("gold", urn1); // CDP after liquidation
            assertEq(ink2, 0);
            assertEq(art2, 0);
        }

        // Collateral price is $5
        gold.pip.poke(bytes32(5 * WAD));
        spot.poke("gold");
        end.cage();
        end.cage("gold");
        assertEq(end.tag("gold"), ray(0.2 ether)); // par / price = collateral per DAI

        assertEq(vat.gem("gold", address(gold.clip)), lot1); // From grab in dog.bark()
        assertEq(vat.sin(address(vow)),        art1 * rate); // From grab in dog.bark()
        assertEq(vat.vice(),                   art1 * rate); // From grab in dog.bark()
        assertEq(vat.debt(),                   art1 * rate); // From frob
        assertEq(vat.dai(address(vow)),                  0); // vat.suck() hasn't been called

        end.snip("gold", id);

        {
            uint256 pos2;
            uint256 tab2;
            uint256 lot2;
            address usr2;
            uint96  tic2;
            uint256 top2;
            (pos2, tab2, lot2, usr2, tic2, top2) = gold.clip.sales(id);
            assertEq(pos2,          0);
            assertEq(tab2,          0);
            assertEq(lot2,          0);
            assertEq(usr2,  address(0));
            assertEq(uint256(tic2), 0);
            assertEq(uint256(top2), 0);
        }

        assertEq(dog.Dirt(),                            0); // From clip.yank()
        assertEq(vat.gem("gold", address(gold.clip)),   0); // From clip.yank()
        assertEq(vat.gem("gold", address(end)),         0); // From grab in end.snip()
        assertEq(vat.sin(address(vow)),       art1 * rate); // From grab in dog.bark()
        assertEq(vat.vice(),                  art1 * rate); // From grab in dog.bark()
        assertEq(vat.debt(),           tab1 + art1 * rate); // From frob and suck
        assertEq(vat.dai(address(vow)),              tab1); // From vat.suck()
        assertEq(end.Art("gold") * rate,             tab1); // Incrementing total Art in End

        (uint ink3, uint art3) = vat.urns("gold", urn1);    // CDP after snip
        assertEq(ink3, 10 ether);                           // All collateral returned to CDP
        assertEq(art3, tab1 / rate);                        // Tab amount of normalized debt transferred back into CDP
    }

    uint256 constant RAD = 10**45;
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, WAD) / y;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, RAY) / y;
    }
    function fix_calc_0(uint256 col, uint256 debt) internal pure returns (uint256) {
        return rdiv(mul(col, RAY), debt);
    }
    function fix_calc_1(uint256 col, uint256 debt) internal pure returns (uint256) {
        return wdiv(mul(col, RAY), (debt / 10**9));
    }
    function fix_calc_2(uint256 col, uint256 debt) internal pure returns (uint256) {
        return mul(col, RAY) / (debt / RAY);
    }
    function wAssertCloseEnough(uint256 x, uint256 y) internal {
        uint256 diff = x > y ? x - y : y - x;
        if (diff == 0) return;
        uint256 xErr = mul(diff, WAD) / x;
        uint256 yErr = mul(diff, WAD) / y;
        uint256 err  = xErr > yErr ? xErr : yErr;
        assertTrue(err < WAD / 100_000_000);  // Error no more than one part in a hundred million
    }
    uint256 constant MIN_DEBT   = 10**6 * RAD;  // Minimum debt for fuzz runs
    uint256 constant REDEEM_AMT = 1_000 * WAD;  // Amount of DAI to redeem for error checking
    function test_fuzz_fix_calcs_0_1(uint256 col_seed, uint192 debt_seed) public {
        uint256 col = col_seed % (115792 * WAD);  // somewhat biased, but not enough to matter
        if (col < 10**12) col += 10**12;  // At least 10^-6 WAD units of collateral; this makes the fixes almost always non-zero.
        uint256 debt = debt_seed;
        if (debt < MIN_DEBT) debt += MIN_DEBT;  // consider at least MIN_DEBT of debt

        uint256 fix0 = fix_calc_0(col, debt);
        uint256 fix1 = fix_calc_1(col, debt);

        // how much collateral can be obtained with a single DAI in each case
        uint256 col0 = rmul(REDEEM_AMT, fix0);
        uint256 col1 = rmul(REDEEM_AMT, fix1);

        // Assert on percentage error of returned collateral
        wAssertCloseEnough(col0, col1);
    }
    function test_fuzz_fix_calcs_0_2(uint256 col_seed, uint192 debt_seed) public {
        uint256 col = col_seed % (115792 * WAD);  // somewhat biased, but not enough to matter
        if (col < 10**12) col += 10**12;  // At least 10^-6 WAD units of collateral; this makes the fixes almost always non-zero.
        uint256 debt = debt_seed;
        if (debt < MIN_DEBT) debt += MIN_DEBT;  // consider at least MIN_DEBT of debt

        uint256 fix0 = fix_calc_0(col, debt);
        uint256 fix2 = fix_calc_2(col, debt);

        // how much collateral can be obtained with a single DAI in each case
        uint256 col0 = rmul(REDEEM_AMT, fix0);
        uint256 col2 = rmul(REDEEM_AMT, fix2);

        // Assert on percentage error of returned collateral
        wAssertCloseEnough(col0, col2);
    }
    function test_fuzz_fix_calcs_1_2(uint256 col_seed, uint192 debt_seed) public {
        uint256 col = col_seed % (10**14 * WAD);  // somewhat biased, but not enough to matter
        if (col < 10**12) col += 10**12;  // At least 10^-6 WAD units of collateral; this makes the fixes almost always non-zero.
        uint256 debt = debt_seed;
        if (debt < MIN_DEBT) debt += MIN_DEBT;  // consider at least MIN_DEBT of debt

        uint256 fix1 = fix_calc_1(col, debt);
        uint256 fix2 = fix_calc_2(col, debt);

        // how much collateral can be obtained with a single DAI in each case
        uint256 col1 = rmul(REDEEM_AMT, fix1);
        uint256 col2 = rmul(REDEEM_AMT, fix2);

        // Assert on percentage error of returned collateral
        wAssertCloseEnough(col1, col2);
    }
}
