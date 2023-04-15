// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "solmate/utils/FixedPointMathLib.sol";
import "solmate/utils/LibString.sol";
import "openzeppelin-contracts/contracts/utils/Base64.sol";
import "./ERC721F.sol";
import "./Ecosystem.sol";

contract IDORunner {
    event Launch(TokyoCards nft, IUniswapV3Pool pool, uint256 tokenId);

    constructor(INonfungiblePositionManager mgr, uint24 fee) payable {
        TokyoCards cards = new TokyoCards(mgr);
        (IUniswapV3Pool pool, uint256 tokenId) = cards.launch{value: msg.value}(msg.sender, fee);
        _onLaunch(cards, pool, tokenId);
    }

    function _onLaunch(TokyoCards cards, IUniswapV3Pool pool, uint256 tokenId) internal virtual {
        emit Launch(cards, pool, tokenId);
        assembly { selfdestruct(origin()) }
    }
}

contract TokyoCards is ERC721F('TokyoCards', 'TKYC', 1e6 ether, 1e6 ether / 256) {
    address public immutable authority;
    INonfungiblePositionManager public immutable nfpMgr;
    uint256 internal _lastTokenId;

    int24 public constant MIN_TICK = -887272;
    int24 public constant MAX_TICK = -MIN_TICK;

    constructor(INonfungiblePositionManager nfpMgr_) {
        authority = msg.sender;
        nfpMgr = nfpMgr_;
    }

    function launch(address owner, uint24 fee)
        external
        payable
        returns (IUniswapV3Pool pool, uint256 tokenId)
    {
        require(msg.sender == authority, 'NOT_AUTHORITY');
        IWETH9 weth = nfpMgr.WETH9();
        pool = nfpMgr.factory().createPool(
            address(erc20),
            address(weth),
            fee
        );
        uint256 erc20Amount = erc20.totalSupply();
        (address token0 , address token1) = address(erc20) < address(weth)
        ? (address(erc20), address(weth))
        : (address(weth), address(erc20));
        (uint256 amount0 , uint256 amount1) = address(erc20) < address(weth)
        ? (erc20Amount, msg.value)
        : (msg.value, erc20Amount);
        pool.initialize(uint160((FixedPointMathLib.sqrt(amount1) << 96) / FixedPointMathLib.sqrt(amount0)));
        int24 tickSpacing = nfpMgr.factory().feeAmountTickSpacing(fee);
        // TODO: refund unused ERC20.
        (tokenId,,,) = nfpMgr.mint{value: msg.value}(INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: fee,
            tickLower: (MIN_TICK / tickSpacing) * tickSpacing,
            tickUpper: (MAX_TICK / tickSpacing) * tickSpacing,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0,
            recipient: owner,
            deadline: block.timestamp
        }));
    }

    function tokenURI(uint256 tokenId) external pure returns (string memory) {
        string memory tokenIdString = LibString.toString(tokenId);
        return string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(abi.encodePacked(
                '{"image":"https://raw.githubusercontent.com/merklejerk/erc721f/main/assets/',
                tokenIdString,
                '.png","name":"EthTokyo ERC721F #',
                tokenIdString,
                '","description":"a very special fungible NFT token"}'
            ))
        ));
    }

    function _mint() internal override returns (uint256 tokenId) {
        return ++_lastTokenId;
    }
}