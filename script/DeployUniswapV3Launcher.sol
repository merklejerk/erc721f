// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import "../src/UniswapV3Launcher.sol";

contract DeployUniswapV3Launcher is Script {
    function run() public {
        vm.startBroadcast(vm.envUint('DEV_KEY'));
        UniswapV3Launcher launcher = new UniswapV3Launcher(
            INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88)
        );
        console2.log('launcher:', address(launcher));
    }
}
