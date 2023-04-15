// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console2.sol";
import "forge-std/Script.sol";
import "../src/demo/DemoToken.sol";
import "../src/UniswapV3Launcher.sol";

contract DeployDemo is Script {
    function run(UniswapV3Launcher launcher, uint24 fee, uint256 maxSupply, uint256 eth) public {
        vm.startBroadcast(vm.envUint('DEV_KEY'));
        TokyoCards erc721 = new TokyoCards(address(launcher));
        console.log('nft:', address(erc721));
        (, uint256 positionTokenId) = launcher.launch{value: eth}(erc721, this.getBroadcaster(), fee, maxSupply);
        console.log('position token:', positionTokenId);
    }

    function getBroadcaster() external view returns (address) {
        return msg.sender;
    }
}
