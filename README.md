# karpatkey Token

## Details

- Name: `karpatkey Token`
- Symbol: `KPK`
- Decimals: `18`
- Initial Total Supply: `1_000_000`

## Purpose

Following the tradition of our sister projects CowDAO and SafeDAO and their spinoffs in [GIP-13]() and [GIP-29](https://forum.gnosis.io/t/gip-29-spin-off-safedao-and-launch-safe-token/3476), karpatkey will launch their DAO spinoff from the GnosisDAO.
If the Gnosis Improvement Proposal GIP-9x: karpatkey spinoff and KPK launch is approved, the GnosisDAO will deploy KPK as an ERC20 token.

## Utility

KPK is created to align the parties contributing to delivering karpatkey's vision. KPK will be a governance token used to define treasury parameters, budgets, OTC deals, buybacks and M&A deals.
The initial full supply will be 1 million KPK and non-transferable for the foreseeable future to replicate a private organisation.

## Specifications

### Ownership

The karpatkey token contract is ownable and the initial token supply will be minted to the specified owner (the karpatkey DAO). Ownership can be transferred and revoked at any point.

### Transferability

The karpatkey token is initially not transferrable. The only exception to this is the owner of the token contract, and token holders that might be granted specific transferring permission by the token contract's owner.

#### Paused state and transfer allowance

The token contract is initially deployed in paused state, which makes the token non-transferrable by default except for the token contract's owner. During the time the token contract is in paused state, the token contract's owner is able to grant transfer approval to specified holder addresses via calling the `approveTransfer` method which modifies that holder's `transferAllowance`. A token holder with a `transferAllowance` set to `amount` is able to transfer up to `amount` tokens via the `transfer` method, or by having an approved spender transfer tokens on behalf of the holder via the `transferFrom` method.

To make the token fully fledged transferable the token contract's owner has to call the `unpause` method of the token contract. Once the token contract is in unpaused state the `transferAllowance` and the `approveTransfer` method are rendered obsolete.

When unpaused the token contract's owner can at any time call the `pause` method to pause transfers once again.

#### Transfer by owner

The token contract's owner is at any point able to transfer tokens from any given address to any other address via the `transferByOwner` method.

### Supply

The initial total supply of 1 million karpatkey tokens is minted to the token contract's owner at deployment. Tokens can be minted or burned by the token contract's owner via the `mint` and `burn` methods, respectively.

### ERC20 token recovery

To recover ERC20 tokens that have been sent to the token contract it is possible to use the `rescueToken` method to transfer tokens to another address.

### Upgradeability

### On-chain governance
