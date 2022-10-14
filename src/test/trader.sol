// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.12;

interface IToken {
    function approve(address guy) external returns (bool);
}

interface IExchange {
    function sellGold(uint256 goldAmt) external;
}

interface IDaiJoin {
    function join(address usr, uint wad) external;
}

interface IClipper {
    function take(uint256 id, uint256 amt, uint256 max, address who, bytes calldata data) external;
}

interface IVat {
    function hope(address usr) external;
}

interface IGemJoin {
    function exit(address usr, uint wad) external;
}

contract Trader {
    IClipper clip;
    IVat vat;
    IToken gold;
    IGemJoin goldJoin;
    IToken dai;
    IDaiJoin daiJoin;
    IExchange exchange;

    constructor(
        IClipper clip_,
        IVat vat_,
        IToken gold_,
        IGemJoin goldJoin_,
        IToken dai_,
        IDaiJoin daiJoin_,
        IExchange exchange_
    ) public {
        clip = clip_;
        vat = vat_;
        gold = gold_;
        goldJoin = goldJoin_;
        dai = dai_;
        daiJoin = daiJoin_;
        exchange = exchange_;
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

    function clipperCall(address sender, uint256 owe, uint256 slice, bytes calldata data)
        external {
        data;
        goldJoin.exit(address(this), slice);
        gold.approve(address(exchange));
        exchange.sellGold(slice);
        dai.approve(address(daiJoin));
        vat.hope(address(clip));
        daiJoin.join(sender, owe / 1E27);
    }
}
