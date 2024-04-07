// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Base} from '.././Base.sol';

contract UnitTestConstructor is Base {
  function testConstructor() public view {
    assertEq(_kpktoken.owner(), _owner);
    assertEq(_kpktoken.totalSupply(), 1_000_000 * 10 ** _kpktoken.decimals());
    assertEq(_kpktoken.balanceOf(_owner), 1_000_000 * 10 ** _kpktoken.decimals());
    assertEq(_kpktoken.name(), 'karpatkey Token');
    assertEq(_kpktoken.symbol(), 'KPK');
    assertEq(_kpktoken.decimals(), 18);
    assertEq(_kpktoken.paused(), true);
  }
}
