# karpatkey Token

## Details

- Name: `karpatkey Token`
- Symbol: `KPK`
- Decimals: `18`
- Initial total supply: `1_000_000`

## Purpose

Following the tradition of our sister projects CowDAO and SafeDAO and their spinoffs in [GIP-13]() and [GIP-29](https://forum.gnosis.io/t/gip-29-spin-off-safedao-and-launch-safe-token/3476), respectively, karpatkey will launch their DAO spinoff from the GnosisDAO. If [GIP-92](https://forum.gnosis.io/t/gip-92-should-gnosis-dao-spin-off-karpatkey-dao-and-deploy-the-kpk-token/8115) is approved, the GnosisDAO will deploy KPK as an ERC20 token.

## Utility

KPK is created to align the parties contributing to delivering karpatkey's vision. KPK will be a governance token used to define treasury parameters, budgets, OTC deals, buybacks and M&A deals.
The initial total supply will be 1 million KPK and non-transferable for the foreseeable future to replicate a private organisation.

## Specifications

### Ownership

The karpatkey token contract is ownable and the initial token supply is minted to the specified owner (the karpatkey DAO). Ownership can be transferred and renounced at any point.

### Transferability

The karpatkey token is initially not transferrable. The only exception to this is the owner of the token contract, and token holders that might be granted specific transferring permission by the contract's owner.

#### Paused state

The contract is initially deployed in paused state, which makes the token non-transferrable by default except for the token contract's owner.

#### Transfer allowlisting

When the contract is in paused state the owner can allowlist addresses granting them unrestricted transferring permission by calling the `transferAllowlist` method.

The `transferAllowlisted` method indicates whether an address has been allowlisted or not.

An allowlisted address is able to transfer and burn tokens by calling the `transfer` and `burn` methods, respectively, or by having an approved spender (through the ERC20 `approve` method) call the `transferFrom` and `burnFrom` methods.

#### Transfer allowance

When the contract is in paused state the owner can grant permission to an address to transfer tokens to a specified recipient by calling the `approveTransfer` method.

The `transferAllowance` method returns the amount of tokens a token holder is allowed to transfer to a specified recipient.

#### Unpaused state

The contract is unpaused by its' owner calling the `unpause` method. Once unpaused it cannot be paused again.

Once unpaused the token is made fully fledged transferable, and the `transferAllowlist`, `transferAllowlisted`, `transferAllowance` and the `approveTransfer` methods are rendered obsolete.

### Supply

The initial total supply of 1 million karpatkey tokens is minted to the contract's owner at deployment. Tokens can be minted or burned by the contract's owner via the `mint` and `burn`, `burnFrom` methods, respectively.

#### Burning and paused state

When the contract is in paused state, token holders (other than the contract's owner) cannot burn tokens unless thay are allowlisted via `transferAllowlist` or are granted transfer allowance via `approveTransfer`with the recipient being the zero address.

Once the contract is unpaused, token holders can freely burn tokens via the `burn`and `burnFrom` methods.

### ERC20 token recovery

To recover ERC20 tokens that have been sent to the contract the owner can call the `rescueToken` method to transfer these tokens to another address.

### Upgradeability

The contract is upgradeable following the Transparent Proxy pattern.

### On-chain governance

The contract inherits Open Zeppelin's [ERC20VotesUpgradebale](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/extensions/ERC20VotesUpgradeable.sol) contract for the deployment of a Governor contract.
