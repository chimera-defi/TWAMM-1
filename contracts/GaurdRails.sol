//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;
import "./GracefulShutdown.sol";

contract GaurdRails is GracefulShutdown {
  // Implement gaurd rails to prevent bad trades / triggering any mathmetical instability as a shortcut to prod
  // Ideally we do not need extensive gaurdrails
  constructor() {
    gaurdRailsActive = true;
  }

  function flipActivationState() external onlyOwner {
    gaurdRailsActive = false;
  }

  function _beforeLiquidityAdd(uint256 lpTokenAmt, uint256 total) internal pure {
    // We see issues if a user deposits say 1000 tokens to a pool w/ 1 token initial
    // Or vice versa. To keep it simple, lets just pin the gaurd rails to be within 100x of each other. 
    require(total*100 >= lpTokenAmt, "Amount too large. Will rug others");
    require(total <= 100*lpTokenAmt, "Amount too smol. self rug");
  }
}