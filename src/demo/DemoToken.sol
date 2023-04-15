// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "solmate/utils/LibString.sol";
import "openzeppelin-contracts/contracts/utils/Base64.sol";
import "../ERC721F.sol";

contract TokyoCards is ERC721F {
    uint256 internal _lastTokenId;

    constructor(address minter_) ERC721F(minter_, 'TokyoCards', 'TKYC', 1e18) {}

    function tokenURI(uint256 tokenId) external pure returns (string memory) {
        string memory tokenIdString = LibString.toString(tokenId);
        return string(abi.encodePacked(
            'data:application/json;base64,',
            Base64.encode(abi.encodePacked(
                '{"image":"https://raw.githubusercontent.com/merklejerk/erc721f/main/assets/',
                tokenIdString,
                '.jpg","name":"EthTokyo ERC721F #',
                tokenIdString,
                '","description":"a very special fungible NFT token"}'
            ))
        ));
    }

    function _mint() internal override returns (uint256 tokenId) {
        return ++_lastTokenId;
    }
}