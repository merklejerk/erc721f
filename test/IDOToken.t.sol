// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./TestUtils.sol";
import "../src/IDOToken.sol";
import "./UniswapClones.sol";

contract IDOTokenTest is UniswapClonedFixture, TestUtils {
    uint24 constant fee = 3000;
    TokyoCards erc721;
    ERC20N erc20;
    IUniswapV3Pool pool;
    uint256 positionTokenId;
    uint256 q;

    constructor() {
        _etch();
    }

    receive() external payable {}

    function setUp() external {
        TestableIDORunner runner =
            new TestableIDORunner{value: 1 ether}(nonfungiblePositionManager, fee);
        (erc721, pool, positionTokenId) = runner.get();
        erc20 = erc721.erc20();
        q = erc20.q();
    }

    function test_initialConditions() external {
        assertEq(erc721.balanceOf(address(pool)), 0);
        assertGt(erc20.balanceOf(address(pool)), erc20.q());
    }
    
    function test_canMint() external {
        address user = _randomAddress();
        uint256 buyAmount = erc20.totalSupply() / 2;
        vm.deal(user, 2e18);
        vm.startPrank(user);
        weth.deposit{value: 2e18}();
        weth.approve(address(swapRouter), type(uint256).max);
        swapRouter.exactOutputSingle(ISwapRouter.ExactOutputSingleParams({
            tokenIn: address(weth),
            tokenOut: address(erc20),
            fee: fee,
            recipient: user,
            amountOut: buyAmount,
            amountInMaximum: type(uint256).max,
            sqrtPriceLimitX96: 0
        }));
        assertEq(erc20.balanceOf(user), buyAmount);
        assertEq(erc721.balanceOf(user), buyAmount / q);
    }

    function test_canSell() external {
        address user = _randomAddress();
        uint256 buyAmount = erc20.totalSupply() / 2;
        vm.deal(user, 2e18);
        vm.startPrank(user);
        weth.deposit{value: 2e18}();
        weth.approve(address(swapRouter), type(uint256).max);
        swapRouter.exactOutputSingle(ISwapRouter.ExactOutputSingleParams({
            tokenIn: address(weth),
            tokenOut: address(erc20),
            fee: fee,
            recipient: user,
            amountOut: buyAmount,
            amountInMaximum: type(uint256).max,
            sqrtPriceLimitX96: 0
        }));
        uint256 sellAmount = buyAmount / 3;
        erc20.approve(address(swapRouter), sellAmount);
        swapRouter.exactInputSingle(ISwapRouter.ExactInputSingleParams({
            tokenIn: address(erc20),
            tokenOut: address(weth),
            fee: fee,
            recipient: user,
            amountIn: sellAmount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        }));
        assertEq(erc20.balanceOf(user), buyAmount - sellAmount);
        assertEq(erc721.balanceOf(user), (buyAmount - sellAmount) / q);
        assertEq(erc721.balanceOf(address(pool)), (buyAmount / q) - ((buyAmount - sellAmount) / q));
    }

    function test_canSellThenBuyBack() external {
        address user = _randomAddress();
        uint256 buyAmount = erc20.totalSupply() / 2;
        vm.deal(user, 2e18);
        vm.startPrank(user);
        weth.deposit{value: 2e18}();
        weth.approve(address(swapRouter), type(uint256).max);
        swapRouter.exactOutputSingle(ISwapRouter.ExactOutputSingleParams({
            tokenIn: address(weth),
            tokenOut: address(erc20),
            fee: fee,
            recipient: user,
            amountOut: buyAmount,
            amountInMaximum: type(uint256).max,
            sqrtPriceLimitX96: 0
        }));
        uint256 sellAmount = buyAmount / 3;
        erc20.approve(address(swapRouter), sellAmount);
        swapRouter.exactInputSingle(ISwapRouter.ExactInputSingleParams({
            tokenIn: address(erc20),
            tokenOut: address(weth),
            fee: fee,
            recipient: user,
            amountIn: sellAmount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        }));
        swapRouter.exactOutputSingle(ISwapRouter.ExactOutputSingleParams({
            tokenIn: address(weth),
            tokenOut: address(erc20),
            fee: fee,
            recipient: user,
            amountOut: sellAmount,
            amountInMaximum: type(uint256).max,
            sqrtPriceLimitX96: 0
        }));
        assertEq(erc20.balanceOf(user), buyAmount);
        assertEq(erc721.balanceOf(user), buyAmount / q);
        assertEq(erc721.balanceOf(address(pool)), 0);
    }
}

contract TestableIDORunner is IDORunner {
    TokyoCards nft;
    IUniswapV3Pool public pool;
    uint256 public tokenId;

    constructor(INonfungiblePositionManager nfpMgr, uint24 fee)
        payable
        IDORunner(nfpMgr, fee)
    {}

    function get() external view returns (TokyoCards nft_, IUniswapV3Pool pool_, uint256 tokenId_) {
        return (nft, pool, tokenId);
    }

    function _onLaunch(TokyoCards nft_, IUniswapV3Pool pool_, uint256 tokenId_) internal override {
        nft = nft_;
        pool = pool_;
        tokenId = tokenId_;
    }
}
