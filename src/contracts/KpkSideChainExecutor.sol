// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CCIPReceiver} from '@chainlink/src/v0.8/ccip/applications/CCIPReceiver.sol';
import {Client} from '@chainlink/src/v0.8/ccip/libraries/Client.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract KpkSidechainExecutor is CCIPReceiver, Ownable {
  // Mapping for whitelisted addresses
  mapping(address => bool) public whitelistedAddresses;

  address public immutable AUTHORIZED_SOURCE_ROUTER;
  uint64 public immutable AUTHORIZED_SOURCE_CHAIN_SELECTOR;
  address public immutable AUTHORIZED_SENDER;

  event MessageRelayed(address indexed targetAddress, bytes data, bool success);
  event AddressWhitelisted(address indexed account, bool isWhitelisted);

  // Custom errors
  error InvalidSourceChain();
  error InvalidSender();
  error TargetCallFailed();
  error CallerNotAuthorized();

  constructor(
    address _router,
    address _authorizedSourceRouter,
    uint64 _authorizedSourceChainSelector,
    address _authorizedSender
  ) CCIPReceiver(_router) Ownable(msg.sender) {
    AUTHORIZED_SOURCE_ROUTER = _authorizedSourceRouter;
    AUTHORIZED_SOURCE_CHAIN_SELECTOR = _authorizedSourceChainSelector;
    AUTHORIZED_SENDER = _authorizedSender;
  }

  /**
   * @dev Sets an address as whitelisted or not
   * @param _account Address to update whitelist status
   * @param _isWhitelisted Whether the address should be whitelisted
   */
  function setWhitelistedAddress(address _account, bool _isWhitelisted) external onlyOwner {
    whitelistedAddresses[_account] = _isWhitelisted;
    emit AddressWhitelisted(_account, _isWhitelisted);
  }

  /**
   * @dev Relays a message to a target address
   * @param targetAddress The address to which the message will be relayed
   * @param message The CCIP message containing execution data
   */
  function relayMessage(address targetAddress, Client.Any2EVMMessage memory message) external {
    // Ensure only the contract itself or whitelisted addresses can call this
    if (msg.sender != address(this) && !whitelistedAddresses[msg.sender]) {
      revert CallerNotAuthorized();
    }

    // Validate through the _ccipReceive function
    _validateMessage(message);

    // Forward the message data to the specified target address
    (bool success,) = targetAddress.call(message.data);

    emit MessageRelayed(targetAddress, message.data, success);

    // Ensure the call was successful
    if (!success) {
      revert TargetCallFailed();
    }
  }

  /**
   * @dev Called by the CCIP router to process incoming messages
   * @param message The CCIP message containing execution data
   */
  function _ccipReceive(
    Client.Any2EVMMessage memory message
  ) internal view override {
    // Validate the message and do nothing else
    _validateMessage(message);
  }

  /**
   * @dev Validates the incoming message source chain and sender
   * @param message The CCIP message to validate
   */
  function _validateMessage(
    Client.Any2EVMMessage memory message
  ) internal view {
    // Validate the source chain and sender
    if (message.sourceChainSelector != AUTHORIZED_SOURCE_CHAIN_SELECTOR) {
      revert InvalidSourceChain();
    }

    if (abi.decode(message.sender, (address)) != AUTHORIZED_SENDER) {
      revert InvalidSender();
    }
  }
}
