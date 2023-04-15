⚠️ This project was written in haste with very little sleep during EthTokyo. Use at your own risk! ⚠️
```
        $$$$$$$$\ $$$$$$$\   $$$$$$\  $$$$$$$$\  $$$$$$\    $$\   $$$$$$$$\ 
        $$  _____|$$  __$$\ $$  __$$\ \____$$  |$$  __$$\ $$$$ |  $$  _____|
        $$ |      $$ |  $$ |$$ /  \__|    $$  / \__/  $$ |\_$$ |  $$ |      
        $$$$$\    $$$$$$$  |$$ |         $$  /   $$$$$$  |  $$ |  $$$$$\    
        $$  __|   $$  __$$< $$ |        $$  /   $$  ____/   $$ |  $$  __|   
        $$ |      $$ |  $$ |$$ |  $$\  $$  /    $$ |        $$ |  $$ |      
        $$$$$$$$\ $$ |  $$ |\$$$$$$  |$$  /     $$$$$$$$\ $$$$$$\ $$ |      
        \________|\__|  \__| \______/ \__/      \________|\______|\__|      
```

*Finally, truly fungible ERC721s!*

                                                                    
---

## Setup
```bash
# Install deps
> forge install
# Run tests
> forge test -vvv
```

## Overview

ERC721F tokens are actually composed of two contracts: An ERC721 and an ERC20 contract. State is shared and synced between them so balances can be manipulated using either! Transferring ERC20 tokens will result in ERC721 tokens in being moved around, and vice versa!

To hold a non-zero balance of the ERC721 token, you must have some (fixed) multiple of the ERC20 token. If your ERC20 balance dips below a multiple, one of your NFTs will be set aside to be awarded to the next user that reaches a new ERC20 balance multiple. On the flip side, transferring individual ERC721 tokens results in a multiple of ERC20 tokens being transferred as well.


## Initial Dex Offerings for NFTs
The system is designed to be compatible with AMM architectures at all stages of the collection lifecycle. During setup, ERC20 tokens can be minted to a pool without backing ERC721 tokens, so they can be lazy-minted when ERC20 tokens are transferred out of the AMM pool to buyers. This mechanism allows NFT collections to use the "Initial Dex Offering" strategy of distributing their mints. There are many benefits to this approach:
1. Instant liquidity, even before the first mint.
2. Automatic price scaling with demand.
3. Everyone, whale or minnow, can get in on the action!
4. Collection owner receives perpetual royalties in the form of AMM fees while they maintain their position.

Included in this repo is a utility contract for deploying new collections to a Uniswap V3 pool (so it's NFTs all the way down) to do all that!

## Contracts

| name | purpose |
|---|---|
| [ERC721F.sol](./src/ERC721F.sol) | The base ERC721(F) and ERC20(N) contracts that make this all possible. |
| [Ecosystem.sol](./src/Ecosystem.sol) | Uniswap/WETH interfaces |
| [Tokens.sol](./src/Tokens.sol) | Generic ERC721/IERC20 Token interfaces |
| [UniswapV3Launcher](./src/UniswapV3Launcher.sol) | A canonical contract for launching a new ERC721F collection on a Uniswap V3 pool. See [tests](./test) or [deploy scripts](./scripts) for example usage. |



