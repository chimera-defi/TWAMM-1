//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/LongTermOrders.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract GracefulShutdown is Ownable {

    ///@notice mapping of LPs for shutdown
    mapping(address => uint256) lpMap;
    mapping(uint256 => address) lpIdtoAddressMap;
    mapping(address => uint256) lpAdddressToIdMap;
    ///@notice incrementing counter for lp ids
    uint256 lpId;

    ///@notice information bool. Do not trade if it is true
    bool public isShutdown;

    constructor() {}

    ///@notice remove liquidity to the AMM without lp token transfer or gaurds
    /// This does not burn the lp token or emit events and should not be used without gaurds
    ///@param lpTokenAmount number of lp tokens to burn
    function _removeLiquidityUngaurded(uint256 lpTokenAmount, address user) virtual internal {}

    function _cancelAllLongTermSwaps() virtual internal {}

    function addLP(uint256 lpTokenAmount) internal {
        if (lpAdddressToIdMap[msg.sender] == 0 && lpIdtoAddressMap[0] != msg.sender) {
            lpAdddressToIdMap[msg.sender] = lpId;
            lpIdtoAddressMap[lpId] = msg.sender;
            lpId++;
        }
        lpMap[msg.sender] += lpTokenAmount;
    }

    function refundLPs() internal {
        for (uint i; i<lpId; i++) {
            address user = lpIdtoAddressMap[i];
            uint256 amt = lpMap[user];
            if (amt > 0) {
                lpMap[user] -= amt;
                _removeLiquidityUngaurded(amt, user);
            }
        }
    }

    ///@notice Allow the pool owner to gracefully shutdown the pool experiment
    /// cancel all virtual orders
    /// needs to be wrapped in owner only util
    function _shutdown(address tokenA, address tokenB) public onlyOwner {
        isShutdown = true;
        _cancelAllLongTermSwaps();
        // longTermOrders.cancelAllLongTermSwaps(reserveMap);
        refundLPs();

        ERC20(tokenA).transfer(msg.sender, ERC20(tokenA).balanceOf(address(this)));
        ERC20(tokenB).transfer(msg.sender,  ERC20(tokenB).balanceOf(address(this)));
    }
}