// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./TestUtils.sol";
import "./UniswapClones.sol";
import "../src/demo/DemoToken.sol";
import "../src/UniswapV3Launcher.sol";

contract UniswapSaleTest is UniswapClonedFixture, TestUtils {
    uint24 constant fee = 3000;
    uint256 constant maxSupply = 256;
    UniswapV3Launcher launcher;
    TokyoCards erc721;
    ERC20N erc20;
    IUniswapV3Pool pool;
    uint256 positionTokenId;
    uint256 q;

    constructor() {
        _etch();
        launcher = new UniswapV3Launcher(nonfungiblePositionManager);
    }

    receive() external payable {}

    function setUp() external {
        erc721 = new TokyoCards(address(launcher));
        erc20 = erc721.erc20();
        q = erc20.q();
        (pool, positionTokenId) = launcher.launch{value: 1 ether}(erc721, address(this), fee, maxSupply);
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
        assertEq(erc721.balanceOf(address(pool)), sellAmount / q);
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