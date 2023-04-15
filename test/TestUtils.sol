// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

abstract contract TestUtils is Test {
    function _randomBytes32() internal view returns (bytes32 r) {
        r = keccak256(abi.encode(
            gasleft(),
            address(this),
            tx.origin,
            msg.data
        ));
    }

    function _randomUint256() internal view returns (uint256 r) {
        r = uint256(_randomBytes32());
    }

    function _randomAddress() internal view returns (address payable r) {
        r = payable(address(uint160(_randomUint256())));
    }
}