// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/IDOToken.sol";
import "./UniswapClones.sol";

contract IDOTokenTest is UniswapClonedFixture {
    constructor() {
        _etch();
    }

    function setUp() external {
        new TestableIDORunner{value: 1 ether}(nonfungiblePositionManager, 3000);
    }
    
    function test_works() external {

    }
}

contract TestableIDORunner is IDORunner {
    address public pool;
    uint256 public tokenId;

    constructor(INonfungiblePositionManager nfpMgr, uint24 fee)
        payable
        IDORunner(nfpMgr, fee)
    {}

    function _onLaunch(address pool_, uint256 tokenId_) internal override {
        pool = pool_;
        tokenId = tokenId_;
    }
}
