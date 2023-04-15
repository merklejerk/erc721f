// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721F.sol";

contract TokyoCards is ERC721F('TokyoCards', 'TKYC', 1e18) {
    uint256 internal _lastTokenId;

    constructor() payable {
        // TODO: deposit ETH and _mintTokensOnly() to pool on payment callback.
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