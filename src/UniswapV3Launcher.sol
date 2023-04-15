// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "solmate/utils/FixedPointMathLib.sol";
import "./ERC721F.sol";
import "./Ecosystem.sol";

contract UniswapV3Launcher {
    int24 constant MIN_TICK = -887272;
    int24 constant MAX_TICK = -MIN_TICK;

    INonfungiblePositionManager public immutable nfpMgr;
    IWETH9 public immutable weth;
    IUniswapV3Factory public immutable factory;

    constructor(INonfungiblePositionManager nfpMgr_) {
        nfpMgr = nfpMgr_;
        weth = nfpMgr_.WETH9();
        factory = nfpMgr_.factory();
    }

    function launch(ERC721F erc721, address owner, uint24 fee, uint256 maxSupply)
        external
        payable
        returns (IUniswapV3Pool pool, uint256 tokenId)
    {
        ERC20N erc20 = erc721.erc20();
        uint256 q = erc721.q();
        uint256 erc20Amount = maxSupply * q;
        pool = factory.createPool(
            address(erc20),
            address(weth),
            fee
        );
        erc721.mintErc20s(address(this), erc20Amount);
        erc20.approve(address(nfpMgr), erc20Amount);
        INonfungiblePositionManager.MintParams memory mintParams;
        (mintParams.token0 , mintParams.token1) = address(erc20) < address(weth)
            ? (address(erc20), address(weth))
            : (address(weth), address(erc20));
        (mintParams.amount0Desired , mintParams.amount1Desired) = address(erc20) < address(weth)
            ? (erc20Amount, msg.value)
            : (msg.value, erc20Amount);
        mintParams.fee = fee;
        {
            int24 tickSpacing = nfpMgr.factory().feeAmountTickSpacing(fee);
            mintParams.tickLower = (MIN_TICK / tickSpacing) * tickSpacing;
            mintParams.tickUpper = (MAX_TICK / tickSpacing) * tickSpacing;
        }
        mintParams.amount0Min = 0;
        mintParams.amount1Min = 0;
        mintParams.recipient = owner;
        mintParams.deadline = block.timestamp;
        pool.initialize(uint160(
            (FixedPointMathLib.sqrt(mintParams.amount1Desired) << 96) /
            FixedPointMathLib.sqrt(mintParams.amount0Desired)));
        (tokenId,,,) = nfpMgr.mint{value: msg.value}(mintParams);
        erc721.abdicate();
        // TODO: refund unused ERC20.
    }
}
