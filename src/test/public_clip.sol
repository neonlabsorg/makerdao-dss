// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.12;

import "../clip.sol";

contract PublicClip is Clipper {
    constructor(address vat, address spot, address dog, bytes32 ilk) public Clipper(vat, spot, dog, ilk) {}

    function add() public returns (uint256 id) {
        id = ++kicks;
        active.push(id);
        sales[id].pos = active.length - 1;
    }

    function remove(uint256 id) public {
        _remove(id);
    }
}
