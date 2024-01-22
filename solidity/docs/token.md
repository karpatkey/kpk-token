# Safe Token

## Details

* Name: `karpatkey Token`
* Symbol: `KPK`
* Decimals: `18`
* Total Supply: `1_000_000`

## Purpose

Following the tradition of our sister projects CowDAO and SafeDAO and their spinoffs in [GIP-13]() and [GIP-29](https://forum.gnosis.io/t/gip-29-spin-off-safedao-and-launch-safe-token/3476), karpatkey will launch their DAO spinoff from the GnosisDAO.
If the Gnosis Improvement Proposal GIP-9x: karpatkey spinoff and KPK launch is approved, the GnosisDAO will deploy KPK as an ERC20 token.

## Utility

KPK is created to align the parties contributing to delivering karpatkey's vision. KPK will be a governance token used to define treasury parameters, budgets, OTC deals, buybacks and M&A deals.
The full supply will be 1 million KPK and non-transferable for the foreseeable future to replicate a private organisation.


## Specifications

### Ownership

The karpatkey token is ownable and the initial token supply will be minted to the specified owner. Ownership can be transferred and revoked at any point.

### Transferability

The karpatkey token is initially not transferrable. The only exception to this is the owner of the token contract.

To make the token transferable the owner of the token has to call the `unpause` method of the token contract. Once the token contract is unpaused (and therefore the token is transferable) it is not possible to pause the token contract again (e.g. once transferable forever transferable).

### Supply

The total initial supply of 1 million karpatkey token is minted to the token owner. These tokens then can be further by the token owner (e.g. according to [GIP-2X]()). The token contract does not support any inflation or minting logic. It is also not possible to burn the token. Therefore the total supply is fixed at 1 million karpatkey tokens.

### ERC20 token recovery

To recover ERC20 tokens that have been sent to the token contract it is possible to use [`rescueToken` of the `TokenRescuer` contract](../contracts/TokenRescuer.sol) to transfer tokens to another address.
