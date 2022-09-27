// SPDX-License-Identifier: AGPL-3.0-or-later

// jug.t.sol -- tests for jug.sol

pragma solidity ^0.6.12;

import "./test.sol";

import {Jug} from "../jug.sol";
import {Vat} from "../vat.sol";

interface VatLike {
    function ilks(bytes32) external view returns (
        uint256 Art,
        uint256 rate,
        uint256 spot,
        uint256 line,
        uint256 dust
    );
}

contract Rpow is Jug {
    constructor(address vat_) public Jug(vat_){}

    function pRpow(uint x, uint n, uint b) public pure returns(uint) {
        return _rpow(x, n, b);
    }
}

contract JugTest is DSTest {
    Jug jug;
    Vat  vat;

    function rad(uint wad_) internal pure returns (uint) {
        return wad_ * 10 ** 27;
    }
    function wad(uint rad_) internal pure returns (uint) {
        return rad_ / 10 ** 27;
    }
    function rho(bytes32 ilk) internal view returns (uint) {
        (uint duty, uint rho_) = jug.ilks(ilk); duty;
        return rho_;
    }
    function Art(bytes32 ilk) internal view returns (uint ArtV) {
        (ArtV,,,,) = VatLike(address(vat)).ilks(ilk);
    }
    function rate(bytes32 ilk) internal view returns (uint rateV) {
        (, rateV,,,) = VatLike(address(vat)).ilks(ilk);
    }
    function line(bytes32 ilk) internal view returns (uint lineV) {
        (,,, lineV,) = VatLike(address(vat)).ilks(ilk);
    }

    address ali = address(bytes20("ali"));

    function setUp() public {
        vat  = new Vat();
        jug = new Jug(address(vat));
        vat.rely(address(jug));
        vat.init("i");

        draw("i", 100 ether);

        failed = false;
    }
    function draw(bytes32 ilk, uint dai) internal {
        vat.file("Line", vat.Line() + rad(dai));
        vat.file(ilk, "line", line(ilk) + rad(dai));
        vat.file(ilk, "spot", 10 ** 27 * 10000 ether);
        address self = address(this);
        vat.slip(ilk, self,  10 ** 27 * 1 ether);
        vat.frob(ilk, self, self, self, int(1 ether), int(dai));
    }

    function test_drip_file() public {
        jug.init("i");
        jug.file("i", "duty", 10 ** 27);
        jug.drip("i");
        jug.file("i", "duty", 1000000564701133626865910626);  // 5% / day
    }
    function test_drip_0d() public {
        jug.init("i");
        jug.file("i", "duty", 1000000564701133626865910626);  // 5% / day
        assertEq(vat.dai(ali), rad(0 ether));
        jug.drip("i");
        assertEq(vat.dai(ali), rad(0 ether));
    }

    function test_rpow() public {
        Rpow r = new Rpow(address(vat));
        uint result = r.pRpow(uint(1000234891009084238901289093), uint(3724), uint(1e27));
        // python calc = 2.397991232255757e27 = 2397991232255757e12
        // expect 10 decimal precision
        assertEq(result / uint(1e17), uint(2397991232255757e12) / 1e17);
    }
}
