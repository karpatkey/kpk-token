# kpk Token

## Details

- Name: `kpk Token`
- Symbol: `KPK`
- Native Chain: `Ethereum Mainnet`
- Standard: `ERC-20`
- Decimals: `18`
- Initial Total Supply: `1_000_000_000`

## Purpose & Utility

KPK is a utility token, designed for the purpose of facilitating and delivering alignment across the different stakeholders in kpk DAO, to push collectively towards the project’s mission. 

The primary utility of the token will be the governance of our DAO. More specifically, KPK will used to define treasury parameters and budgets, and to authorise large initaitives like OTC deals, buybacks and other strategic investments.

The initial total supply will be 1 billion KPK. The token will be non-transferable at launch, and will remain so for the foreseeable future, unless and until token transferability is enabled by the DAO.

## Specifications

### Ownership

The kpk token contract is ownable and the initial token supply is minted to the specified owner (the karpatkey DAO). Ownership can be transferred and renounced at any point.

### Transferability

The kpk token is initially not transferrable. The only exceptions to this are (i) the owner of the token contract and (ii) tokenholders that might be granted specific transferring permission by the contract's owner.

#### Paused state

The contract is initially deployed in paused state, which makes the token non-transferrable by default, except for in the case of the token contract's owner or permissioned users.

#### Transfer allowlisting

When the contract is in paused state the owner can allowlist addresses granting them unrestricted transferring permission by calling the `transferAllowlist` method.

The `transferAllowlisted` method indicates whether an address has been allowlisted or not.

An allowlisted address is able to transfer and burn tokens by calling the `transfer` and `burn` methods, respectively, or by having an approved spender (through the ERC20 `approve` method) call the `transferFrom` and `burnFrom` methods.

#### Transfer allowance

When the contract is in paused state the owner can grant permission to an address to transfer tokens to a specified recipient via the `increaseTransferAllowance` and `decreaseTransferAllowance` methods.

The `transferAllowance` method returns the amount of tokens a tokenholder is allowed to transfer to a specified recipient.

#### Unpaused state

The contract is unpaused by its owner calling the `unpause` method. Once unpaused it cannot be paused again.

Once unpaused the token is made fully transferable, and the `transferAllowlist`, `transferAllowlisted`, `transferAllowance`, `increaseTransferAllowance` and `decreaseTransferAllowance` methods are rendered obsolete.

### Supply

The initial total supply of 1 billion kpk tokens is minted to the contract's owner at deployment. Tokens can be minted or burned by the contract's owner via the `mint` and `burn`, `burnFrom` methods, respectively.

#### Burning and paused state

When the contract is in paused state, tokenholders (other than the contract's owner) cannot burn tokens unless thay are allowlisted via `transferAllowlist` or are granted transfer allowance via `approveTransfer` with the recipient being the zero address.

Once the contract is unpaused, tokenholders can freely burn tokens via the `burn` and `burnFrom` methods.

### ERC20 token recovery

To recover ERC20 tokens that have been sent to the contract the owner can call the `rescueToken` method to transfer these tokens to another address.

### Upgradeability

The contract is upgradeable following the [Transparent Proxy](https://blog.openzeppelin.com/the-transparent-proxy-pattern) pattern.

### On-chain governance

The contract inherits Open Zeppelin's [ERC20VotesUpgradebale](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/extensions/ERC20VotesUpgradeable.sol) contract for the deployment of a Governor contract. Once on-chain governance is enabled, users will need to delegate their voting power (including to themselves) in order to have their voting power tracked by the contract.