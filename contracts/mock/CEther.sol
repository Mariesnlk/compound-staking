// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/ICEther.sol";

contract CEther is ICEther {
    function mint() external payable override {}

    /// @notice Sender redeems cTokens in exchange for a specified amount of underlying asset
    /// @dev Accrues interest whether or not the operation succeeds, unless reverted
    /// @param redeemAmount The amount of underlying to redeem
    /// @return uint 0=success, otherwise a failure=1
    function redeemUnderlying(uint256 redeemAmount)
        external
        override
        returns (uint256)
    {
        (bool success, ) = msg.sender.call{value: redeemAmount}("");

        return success ? 0 : 1;
    }

}
