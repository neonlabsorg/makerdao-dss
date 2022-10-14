// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.12;

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

interface IDog {
    function bark(bytes32 ilk, address urn, address kpr) external returns (uint256 id);
    function file(bytes32 what, address data) external;
    function file(bytes32 what, uint256 data) external;
    function file(bytes32 ilk, bytes32 what, uint256 data) external;
    function file(bytes32 ilk, bytes32 what, address clip) external;
    function rely(address usr) external;
    function chop(bytes32 ilk) external view returns (uint256);
    function ilks(bytes32 ilk) external returns (address, uint256, uint256, uint256);
    function Dirt() external returns (uint256);
}

contract GuyForClipper {
    IClipper clip;

    constructor(IClipper clip_) public {
        clip = clip_;
    }

    function hope(address usr) public {
        IVat(clip.vat()).hope(usr);
    }

    function take(
        uint256 id,
        uint256 amt,
        uint256 max,
        address who,
        bytes calldata data
    )
        external
    {
        clip.take({
            id: id,
            amt: amt,
            max: max,
            who: who,
            data: data
        });
    }

    function bark(IDog dog, bytes32 ilk, address urn, address usr) external {
        dog.bark(ilk, urn, usr);
    }
}

contract BadGuy is GuyForClipper {
    constructor(IClipper clip_) GuyForClipper(clip_) public {}

    function clipperCall(address sender, uint256 owe, uint256 slice, bytes calldata data)
        external {
        sender; owe; slice; data;
        clip.take({ // attempt reentrancy
            id: 1,
            amt: 25 ether,
            max: 5 ether * 10E27,
            who: address(this),
            data: ""
        });
    }
}

contract RedoGuy is GuyForClipper {
    constructor(IClipper clip_) GuyForClipper(clip_) public {}

    function clipperCall(
        address sender, uint256 owe, uint256 slice, bytes calldata data
    ) external {
        owe; slice; data;
        clip.redo(1, sender);
    }
}

contract KickGuy is GuyForClipper {
    constructor(IClipper clip_) GuyForClipper(clip_) public {}

    function clipperCall(
        address sender, uint256 owe, uint256 slice, bytes calldata data
    ) external {
        sender; owe; slice; data;
        clip.kick(1, 1, address(0), address(0));
    }
}

contract FileUintGuy is GuyForClipper {
    constructor(IClipper clip_) GuyForClipper(clip_) public {}

    function clipperCall(
        address sender, uint256 owe, uint256 slice, bytes calldata data
    ) external {
        sender; owe; slice; data;
        clip.file("stopped", 1);
    }
}

contract FileAddrGuy is GuyForClipper {
    constructor(IClipper clip_) GuyForClipper(clip_) public {}

    function clipperCall(
        address sender, uint256 owe, uint256 slice, bytes calldata data
    ) external {
        sender; owe; slice; data;
        clip.file("vow", address(123));
    }
}

contract YankGuy is GuyForClipper {
    constructor(IClipper clip_) GuyForClipper(clip_) public {}

    function clipperCall(
        address sender, uint256 owe, uint256 slice, bytes calldata data
    ) external {
        sender; owe; slice; data;
        clip.yank(1);
    }
}


