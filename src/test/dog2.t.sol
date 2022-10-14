// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.12;

import { DSTest } from "./test.sol";
import { Vat } from "../vat.sol";
import { Dog } from "../dog.sol";

contract VowMock {
    function fess (uint256 due) public {}
}

contract ClipperMock {
    bytes32 public ilk;
    function setIlk(bytes32 wat) external {
        ilk = wat;
    }
    function kick(uint256, uint256, address, address)
        external pure returns (uint256 id) {
        id = 42;
    }
}

contract DogTest2 is DSTest {
    bytes32 constant ilk = "gold";
    address constant usr = address(1337);
    uint256 constant THOUSAND = 1E3;
    uint256 constant WAD = 1E18;
    uint256 constant RAY = 1E27;
    uint256 constant RAD = 1E45;
    Vat vat;
    VowMock vow;
    ClipperMock clip;
    Dog dog;

    function setUp() public {
        vat = new Vat();
        vat.init(ilk);
        vat.file(ilk, "spot", THOUSAND * RAY);
        vat.file(ilk, "dust", 100 * RAD);
        vow = new VowMock();
        clip = new ClipperMock();
        clip.setIlk(ilk);
        dog = new Dog(address(vat));
        vat.rely(address(dog));
        dog.file(ilk, "chop", 11 * WAD / 10);
        dog.file("vow", address(vow));
        dog.file(ilk, "clip", address(clip));
        dog.file("Hole", 10 * THOUSAND * RAD);
        dog.file(ilk, "hole", 10 * THOUSAND * RAD);

        failed = false;
    }

    function setUrn(uint256 ink, uint256 art) internal {
        vat.slip(ilk, usr, int256(ink));
        (, uint256 rate,,,) = vat.ilks(ilk);
        vat.suck(address(vow), address(vow), art * rate);
        vat.grab(ilk, usr, usr, address(vow), int256(ink), int256(art));
        (uint256 actualInk, uint256 actualArt) = vat.urns(ilk, usr);
        assertEq(ink, actualInk);
        assertEq(art, actualArt);
    }

    function try_bark(bytes32 ilk_, address usr_, address kpr_) internal returns (bool ok) {
        string memory sig = "bark(bytes32,address,address)";
        (ok,) = address(dog).call(abi.encodeWithSignature(sig, ilk_, usr_, kpr_));
    }

    function test_bark_do_not_create_dusty_auction_hole() public {
        uint256 dust = 300;
        vat.file(ilk, "dust", dust * RAD);
        uint256 hole = 3 * THOUSAND;
        dog.file(ilk, "hole", hole * RAD);

        // Test using a non-zero rate to ensure the code is handling stability fees correctly.
        vat.fold(ilk, address(vow), (5 * int256(RAY)) / 10);
        (, uint256 rate,,,) = vat.ilks(ilk);
        assertEq(rate, (15 * RAY) / 10);

        (, uint256 chop,,) = dog.ilks(ilk);
        setUrn(WAD, (hole - dust / 2) * RAD / rate * WAD / chop);
        dog.bark(ilk, usr, address(this));

        // Make sure any partial liquidation would be dusty (assuming non-dusty remnant)
        (,,, uint256 dirt) = dog.ilks(ilk);
        uint256 room = hole * RAD - dirt;
        uint256 dart = room * WAD / rate / chop;
        assertTrue(dart * rate < dust * RAD);

        // This will need to be partially liquidated
        setUrn(WAD, hole * WAD * WAD / chop);
        assertTrue(!try_bark(ilk, usr, address(this)));  // should revert, as the auction would be dusty
    }

    function test_bark_do_not_create_dusty_auction_Hole() public {
        uint256 dust = 300;
        vat.file(ilk, "dust", dust * RAD);
        uint256 Hole = 3 * THOUSAND;
        dog.file("Hole", Hole * RAD);

        // Test using a non-zero rate to ensure the code is handling stability fees correctly.
        vat.fold(ilk, address(vow), (5 * int256(RAY)) / 10);
        (, uint256 rate,,,) = vat.ilks(ilk);
        assertEq(rate, (15 * RAY) / 10);

        (, uint256 chop,,) = dog.ilks(ilk);
        setUrn(WAD, (Hole - dust / 2) * RAD / rate * WAD / chop);
        dog.bark(ilk, usr, address(this));

        // Make sure any partial liquidation would be dusty (assuming non-dusty remnant)
        uint256 room = Hole * RAD - dog.Dirt();
        uint256 dart = room * WAD / rate / chop;
        assertTrue(dart * rate < dust * RAD);

        // This will need to be partially liquidated
        setUrn(WAD, Hole * WAD * WAD / chop);
        assertTrue(!try_bark(ilk, usr, address(this)));  // should revert, as the auction would be dusty
    }
}
