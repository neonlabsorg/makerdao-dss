// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity >=0.6.12;

import { DSTest } from "./test.sol";
import { Cure } from "../cure.sol";

contract SourceMock {
    uint256 public cure;

    constructor(uint256 cure_) public {
        cure = cure_;
    }

    function update(uint256 cure_) external {
        cure = cure_;
    }
}

contract CureTest is DSTest {
    Cure cure;

    function setUp() public {
        cure = new Cure();

        failed = false;
    }

    function testRelyDeny() public {
        assertEq(cure.wards(address(123)), 0);
        cure.rely(address(123));
        assertEq(cure.wards(address(123)), 1);
        cure.deny(address(123));
        assertEq(cure.wards(address(123)), 0);
    }

    function testSelfFailRely() public {
        cure.deny(address(this));
        cure.rely(address(123));
        fail();
    }

    function testSelfFailDeny() public {
        cure.deny(address(this));
        cure.deny(address(123));
        fail();
    }

    function testFile() public {
        assertEq(cure.wait(), 0);
        cure.file("wait", 10);
        assertEq(cure.wait(), 10);
    }

    function testSelfFailFile() public {
        cure.deny(address(this));
        cure.file("wait", 10);
        fail();
    }

    function testAddSourceDelSource() public {
        assertEq(cure.tCount(), 0);

        address addr1 = address(new SourceMock(0));
        cure.lift(addr1);
        assertEq(cure.tCount(), 1);

        address addr2 = address(new SourceMock(0));
        cure.lift(addr2);
        assertEq(cure.tCount(), 2);

        address addr3 = address(new SourceMock(0));
        cure.lift(addr3);
        assertEq(cure.tCount(), 3);

        assertEq(cure.srcs(0), addr1);
        assertEq(cure.pos(addr1), 1);
        assertEq(cure.srcs(1), addr2);
        assertEq(cure.pos(addr2), 2);
        assertEq(cure.srcs(2), addr3);
        assertEq(cure.pos(addr3), 3);

        cure.drop(addr3);
        assertEq(cure.tCount(), 2);
        assertEq(cure.srcs(0), addr1);
        assertEq(cure.pos(addr1), 1);
        assertEq(cure.srcs(1), addr2);
        assertEq(cure.pos(addr2), 2);

        cure.lift(addr3);
        assertEq(cure.tCount(), 3);
        assertEq(cure.srcs(0), addr1);
        assertEq(cure.pos(addr1), 1);
        assertEq(cure.srcs(1), addr2);
        assertEq(cure.pos(addr2), 2);
        assertEq(cure.srcs(2), addr3);
        assertEq(cure.pos(addr3), 3);

        cure.drop(addr1);
        assertEq(cure.tCount(), 2);
        assertEq(cure.srcs(0), addr3);
        assertEq(cure.pos(addr3), 1);
        assertEq(cure.srcs(1), addr2);
        assertEq(cure.pos(addr2), 2);

        cure.lift(addr1);
        assertEq(cure.tCount(), 3);
        assertEq(cure.srcs(0), addr3);
        assertEq(cure.pos(addr3), 1);
        assertEq(cure.srcs(1), addr2);
        assertEq(cure.pos(addr2), 2);
        assertEq(cure.srcs(2), addr1);
        assertEq(cure.pos(addr1), 3);

        address addr4 = address(new SourceMock(0));
        cure.lift(addr4);
        assertEq(cure.tCount(), 4);
        assertEq(cure.srcs(0), addr3);
        assertEq(cure.pos(addr3), 1);
        assertEq(cure.srcs(1), addr2);
        assertEq(cure.pos(addr2), 2);
        assertEq(cure.srcs(2), addr1);
        assertEq(cure.pos(addr1), 3);
        assertEq(cure.srcs(3), addr4);
        assertEq(cure.pos(addr4), 4);

        cure.drop(addr2);
        assertEq(cure.tCount(), 3);
        assertEq(cure.srcs(0), addr3);
        assertEq(cure.pos(addr3), 1);
        assertEq(cure.srcs(1), addr4);
        assertEq(cure.pos(addr4), 2);
        assertEq(cure.srcs(2), addr1);
        assertEq(cure.pos(addr1), 3);
    }

    function testSelfFailAddSourceAuth() public {
        cure.deny(address(this));
        address addr = address(new SourceMock(0));
        cure.lift(addr);
        fail();
    }

    function testSelfFailDelSourceAuth() public {
        address addr = address(new SourceMock(0));
        cure.lift(addr);
        cure.deny(address(this));
        cure.drop(addr);
        fail();
    }

    function testSelfFailDelSourceNonExisting() public {
        address addr1 = address(new SourceMock(0));
        cure.lift(addr1);
        address addr2 = address(new SourceMock(0));
        cure.drop(addr2);
        fail();
    }

    function testCage() public {
        assertEq(cure.live(), 1);
        cure.cage();
        assertEq(cure.live(), 0);
    }

    function testCure() public {
        address source1 = address(new SourceMock(15_000));
        address source2 = address(new SourceMock(30_000));
        address source3 = address(new SourceMock(50_000));
        cure.lift(source1);
        cure.lift(source2);
        cure.lift(source3);

        cure.cage();

        cure.load(source1);
        assertEq(cure.say(), 15_000);
        assertEq(cure.tell(), 15_000); // It doesn't fail as wait == 0
        cure.load(source2);
        assertEq(cure.say(), 45_000);
        assertEq(cure.tell(), 45_000);
        cure.load(source3);
        assertEq(cure.say(), 95_000);
        assertEq(cure.tell(), 95_000);
    }

    function testCureAllLoaded() public {
        address source1 = address(new SourceMock(15_000));
        address source2 = address(new SourceMock(30_000));
        address source3 = address(new SourceMock(50_000));
        cure.lift(source1);
        assertEq(cure.tCount(), 1);
        cure.lift(source2);
        assertEq(cure.tCount(), 2);
        cure.lift(source3);
        assertEq(cure.tCount(), 3);

        cure.file("wait", 10);

        cure.cage();

        cure.load(source1);
        assertEq(cure.lCount(), 1);
        assertEq(cure.say(), 15_000);
        cure.load(source2);
        assertEq(cure.lCount(), 2);
        assertEq(cure.say(), 45_000);
        cure.load(source3);
        assertEq(cure.lCount(), 3);
        assertEq(cure.say(), 95_000);
        assertEq(cure.tell(), 95_000);
    }

    function testLoadMultipleTimes() public {
        address source1 = address(new SourceMock(2_000));
        address source2 = address(new SourceMock(3_000));
        cure.lift(source1);
        cure.lift(source2);

        cure.cage();

        cure.load(source1);
        assertEq(cure.lCount(), 1);
        cure.load(source2);
        assertEq(cure.lCount(), 2);
        assertEq(cure.tell(), 5_000);

        SourceMock(source1).update(4_000);
        assertEq(cure.tell(), 5_000);

        cure.load(source1);
        assertEq(cure.lCount(), 2);
        assertEq(cure.tell(), 7_000);

        SourceMock(source2).update(6_000);
        assertEq(cure.tell(), 7_000);

        cure.load(source2);
        assertEq(cure.lCount(), 2);
        assertEq(cure.tell(), 10_000);
    }

    function testLoadNoChange() public {
        address source = address(new SourceMock(2_000));
        cure.lift(source);

        cure.cage();

        cure.load(source);
        assertEq(cure.tell(), 2_000);

        cure.load(source);
        assertEq(cure.tell(), 2_000);
    }

    function testSelfFailLoadNotCaged() public {
        address source = address(new SourceMock(2_000));
        cure.lift(source);

        cure.load(source);

        fail();
    }

    function testSelfFailLoadNotAdded() public {
        address source = address(new SourceMock(2_000));

        cure.cage();

        cure.load(source);
        
        fail();
    }

    function testSelfFailCagedRely() public {
        cure.cage();
        cure.rely(address(123));
        fail();
    }

    function testSelfFailCagedDeny() public {
        cure.cage();
        cure.deny(address(123));
        fail();
    }

    function testSelfFailCagedAddSource() public {
        cure.cage();
        address source = address(new SourceMock(0));
        cure.lift(source);
        fail();
    }

    function testSelfFailCagedDelSource() public {
        address source = address(new SourceMock(0));
        cure.lift(source);
        cure.cage();
        cure.drop(source);
        fail();
    }
}
