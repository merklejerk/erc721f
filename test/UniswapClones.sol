// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Ecosystem.sol";

contract UniswapClonedFixture is Test {
    IWETH9 internal weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV3Factory internal uniswapV3Factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    INonfungiblePositionManager internal nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    function _etch() internal {
        vm.etch(address(weth), bytes(vm.readFileBinary('test/runtimes/weth9.bin')));
    
        vm.etch(address(uniswapV3Factory), type(UniswapV3Initializer).runtimeCode);
        IStateInitializer(address(uniswapV3Factory)).init();
        vm.etch(address(uniswapV3Factory), bytes(vm.readFileBinary('test/runtimes/uniswap3-factory.bin')));

        
        vm.etch(address(nonfungiblePositionManager), type(NonFungiblePositionManagerInitializer).runtimeCode);
        IStateInitializer(address(nonfungiblePositionManager)).init();
        vm.etch(address(nonfungiblePositionManager), bytes(vm.readFileBinary('test/runtimes/uniswap3-nfpm.bin')));
    }
}

interface IStateInitializer {
    function init() external;
}

contract UniswapV3Initializer is IStateInitializer {
    uint256[4] __padding;
    mapping(uint24 => int24) feeAmountTickSpacing;

    function init() external {
        feeAmountTickSpacing[500] = 10;
        feeAmountTickSpacing[3000] = 60;
        feeAmountTickSpacing[10000] = 200;
    }
}

contract NonFungiblePositionManagerInitializer is IStateInitializer {
    uint256[3] __padding;
    uint176 _nextId;
    uint80 _nextPoolId;

    function init() external {
        _nextId = 1;
        _nextPoolId = 1;
    }
}