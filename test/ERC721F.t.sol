// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./TestUtils.sol";
import "../src/ERC721F.sol";

contract ERC721FTest is TestUtils {
    uint256 constant q = 100;
    ERC721F erc721;
    ERC20N erc20;

    constructor() {
        erc721 = new TestERC721F(address(this), q);
        erc20 = erc721.erc20();
    }

    function setUp() external {
        // erc721 = new TokyoCards(address(this));
        // erc20 = erc721.erc20();
        // (pool, positionTokenId) = launcher.launch{value: 1 ether}(erc721, address(this), fee, maxSupply);
    }

    function test_canMint() external {
        address alice = _randomAddress();
        erc721.mint(alice, 2);
        erc721.abdicate(address(0));
        assertEq(erc721.ownerOf(1), alice);
        assertEq(erc721.ownerOf(2), alice);
        assertEq(erc20.balanceOf(alice), q * 2);
        assertEq(erc721.totalSupply(), 2);
        assertEq(erc20.totalSupply(), q * 2);
    }

    function test_canTransferERC721() external {
        address alice = _randomAddress();
        address bob = _randomAddress();
        erc721.mint(alice, 2);
        erc721.abdicate(address(0));
        vm.prank(alice);
        erc721.transferFrom(alice, bob, 1);
        assertEq(erc721.ownerOf(1), bob);
        assertEq(erc721.ownerOf(2), alice);
        assertEq(erc20.balanceOf(alice), q);
        assertEq(erc20.balanceOf(bob), q);
    }

    function test_canTransferERC20() external {
        address alice = _randomAddress();
        address bob = _randomAddress();
        erc721.mint(alice, 2);
        erc721.abdicate(address(0));
        vm.prank(alice);
        erc20.transferFrom(alice, bob, q);
        assertEq(erc721.ownerOf(2), bob);
        assertEq(erc721.ownerOf(1), alice);
        assertEq(erc20.balanceOf(alice), q);
        assertEq(erc20.balanceOf(bob), q);
        assertEq(erc721.totalSupply(), 2);
    }

    function test_canPartialTransferERC20() external {
        address alice = _randomAddress();
        address bob = _randomAddress();
        erc721.mint(alice, 2);
        erc721.abdicate(address(0));
        vm.prank(alice);
        erc20.transferFrom(alice, bob, 1);
        assertEq(erc721.ownerOf(2), address(erc721));
        assertEq(erc721.ownerOf(1), alice);
        assertEq(erc20.balanceOf(alice), q + q - 1);
        assertEq(erc20.balanceOf(bob), 1);
        vm.prank(alice);
        erc20.transferFrom(alice, bob, q - 1);
        assertEq(erc721.ownerOf(2), bob);
        assertEq(erc721.ownerOf(1), alice);
        assertEq(erc20.balanceOf(alice), q);
        assertEq(erc20.balanceOf(bob), q);
        assertEq(erc721.totalSupply(), 2);
    }

    function test_canMintOnTransferERC20() external {
        address alice = _randomAddress();
        address bob = _randomAddress();
        erc721.mintErc20s(alice, q * 2);
        erc721.abdicate(address(0));
        assertEq(erc721.totalSupply(), 0);
        assertEq(erc20.totalSupply(), q * 2);
        vm.prank(alice);
        erc20.transferFrom(alice, bob, q);
        vm.expectRevert(ERC721F.NotATokenError.selector);
        erc721.ownerOf(2);
        assertEq(erc721.ownerOf(1), bob);
        assertEq(erc20.balanceOf(alice), q);
        assertEq(erc20.balanceOf(bob), q);
        vm.prank(alice);
        erc20.transferFrom(alice, bob, q / 2);
        vm.expectRevert(ERC721F.NotATokenError.selector);
        erc721.ownerOf(2);
        assertEq(erc20.balanceOf(alice), q / 2);
        assertEq(erc20.balanceOf(bob), q + q / 2);
        vm.prank(alice);
        erc20.transferFrom(alice, bob, q / 2);
        assertEq(erc721.ownerOf(1), bob);
        assertEq(erc721.ownerOf(2), bob);
        assertEq(erc20.balanceOf(alice), 0);
        assertEq(erc20.balanceOf(bob), q * 2);
        assertEq(erc721.totalSupply(), 2);
        assertEq(erc20.totalSupply(), q * 2);
    }
}

contract TestERC721F is ERC721F {
    uint256 public lastTokenId;

    constructor(address minter, uint256 q) ERC721F(minter, 'Demo', 'DEMO', q) {}
    
    function tokenURI(uint256) external pure returns (string memory) {
        return "";
    }

    function _mint() internal override returns (uint256 tokenId) {
        return ++lastTokenId;
    }
}