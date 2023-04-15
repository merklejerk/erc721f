// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC721Events {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

interface IERC721 is IERC721Events {
    function name() external view returns (string memory name);
    function symbol() external view returns (string memory symbol);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function isApprovedForAll(address owner, address spender) external view returns (bool);
    function getApproved(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function setApprovalForAll(address spender, bool isApproved) external;
    function approve(address spender, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory receiveData) external;
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) external returns (bytes4);
}

interface IERC20Events {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

interface IERC20 is IERC20Events {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

