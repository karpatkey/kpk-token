// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CCIPReceiver} from '@chainlink/src/v0.8/ccip/applications/CCIPReceiver.sol';
import {Client} from '@chainlink/src/v0.8/ccip/libraries/Client.sol';

contract SafeCCIPReceiver is CCIPReceiver {
  address public immutable SAFE_ADDRESS;
  address public immutable AUTHORIZED_SOURCE_ROUTER;
  uint64 public immutable AUTHORIZED_SOURCE_CHAIN_SELECTOR;
  address public immutable AUTHORIZED_SENDER;

  constructor(
    address _router,
    address _safeAddress,
    address _authorizedSourceRouter,
    uint64 _authorizedSourceChainSelector,
    address _authorizedSender
  ) CCIPReceiver(_router) {
    SAFE_ADDRESS = _safeAddress;
    AUTHORIZED_SOURCE_ROUTER = _authorizedSourceRouter;
    AUTHORIZED_SOURCE_CHAIN_SELECTOR = _authorizedSourceChainSelector;
    AUTHORIZED_SENDER = _authorizedSender;
  }

  function _ccipReceive(
    Client.Any2EVMMessage memory message
  ) internal override {
    // Validate the source chain and sender
    require(message.sourceChainSelector == AUTHORIZED_SOURCE_CHAIN_SELECTOR, 'Invalid source chain');
    require(abi.decode(message.sender, (address)) == AUTHORIZED_SENDER, 'Invalid sender');

    // The message.data contains your execTransaction call data
    // Forward it to the Safe
    (bool success,) = SAFE_ADDRESS.call(message.data);
    require(success, 'Safe call failed');
  }
}
