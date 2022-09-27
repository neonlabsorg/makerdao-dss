// SPDX-License-Identifier: AGPL-3.0-or-later

// abaci.t.sol -- tests for abaci.sol

pragma solidity ^0.6.12;

import "./test.sol";
import "../abaci.sol";

contract ClipperAbaciTest is DSTest {
    uint256 RAY = 10 ** 27;

    function setUp() public {
        failed = false;
    }

    function assertEqWithinTolerance(
        uint256 x,
        uint256 y,
        uint256 tolerance) internal {
            uint256 diff;
            if (x >= y) {
                diff = x - y;
            } else {
                diff = y - x;
            }
            assertTrue(diff <= tolerance);
    }

    function test_continuous_exp_decrease() public {
        ExponentialDecrease calc = new ExponentialDecrease();
        uint256 tHalf = 900;
        uint256 cut = 0.999230132966E27;  // ~15 half life, cut ~= e^(ln(1/2)/900)
        calc.file("cut", cut);

        uint256 top = 4000 * RAY;
        uint256 expectedPrice = top;
        uint256 tolerance = RAY / 1000;  // 0.001, i.e 0.1%
        for (uint256 i = 0; i < 5; i++) {  // will cover initial value + four half-lives
            assertEqWithinTolerance(calc.price(top, i*tHalf), expectedPrice, tolerance);
            // each loop iteration advances one half-life, so expectedPrice decreases by a factor of 2
            expectedPrice /= 2;
        }
    }
}
