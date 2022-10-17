// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICEther {

    function mint() external payable;

    function redeemUnderlying(uint redeemAmount) external returns (uint);
}
