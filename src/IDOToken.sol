// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721F.sol";
import "./Ecosystem.sol";

contract IDORunner {
    event Launch(address pool, uint256 tokenId);

    constructor(INonfungiblePositionManager mgr, uint24 fee) payable {
        TokyoCards cards = new TokyoCards(mgr);
        (address pool, uint256 tokenId) = cards.launch{value: msg.value}(msg.sender, fee, 1e6 ether);
        emit Launch(pool, tokenId);
        assembly { selfdestruct(origin()) }
    }

    function _onLaunch(address /* pool */, uint256 /* tokenId */) internal virtual {}
}

contract TokyoCards is ERC721F('TokyoCards', 'TKYC', 1e18) {
    address public immutable authority;
    INonfungiblePositionManager public immutable nfpMgr;
    uint256 internal _lastTokenId;

    int24 public constant MIN_TICK = -887272;
    int24 public constant MAX_TICK = -MIN_TICK;

    constructor(INonfungiblePositionManager nfpMgr_) {
        authority = msg.sender;
        nfpMgr = nfpMgr_;
    }

    function launch(address owner, uint24 fee, uint256 amount)
        external
        payable
        returns (address pool, uint256 tokenId)
    {
        require(msg.sender == authority, 'NOT_AUTHORITY');
        pool = nfpMgr.factory().createPool(
            address(erc20),
            address(nfpMgr.WETH9()),
            fee
        );
        erc20.mintTokensOnly(pool, amount);
        (tokenId,,,) = nfpMgr.mint{value: msg.value}(INonfungiblePositionManager.MintParams({
            token0: address(erc20),
            token1: address(nfpMgr.WETH9()),
            fee: fee,
            tickLower: MIN_TICK,
            tickUpper: MAX_TICK,
            amount0Desired: amount,
            amount1Desired: msg.value,
            amount0Min: 0,
            amount1Min: 0,
            recipient: owner,
            deadline: block.timestamp
        }));
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        // TODO
        return "";
    }

    function _mint() internal override returns (uint256 tokenId) {
        // TODO
        return ++_lastTokenId;
    }
}