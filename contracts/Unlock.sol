// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

////////////////////////////////////////////////////
//////////////////New Web3 Social///////////////////
//////////////W//G//F//S//O//C//I//A//L/////////////
/////////////// www.wgfsocial.com //////////////////
////////////////////////////////////////////////////
////////////////////////////////////////////////////

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Unlock is Pausable, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public myToken;

    address public receiver;
    uint256 public unlockedAmount;

    struct Lock {
        uint256 unlockTime;
        uint256 amount;
        bool status;
    }
    mapping(address => Lock[]) private locks;

    event Released(address indexed receiver, uint256 amount);

    constructor(address _token, address _receiver, Lock[] memory _locks) {
        receiver = _receiver;
        myToken = IERC20(_token);
        for (uint256 i = 0; i < _locks.length; i++) {
            locks[_receiver].push(_locks[i]);
        }
    }

    function release() public whenNotPaused returns (uint256) {
        Lock[] storage userLocks = locks[receiver];
        for (uint256 i = 0; i < userLocks.length; i++) {
            if (
                block.timestamp >= userLocks[i].unlockTime &&
                !userLocks[i].status
            ) {
                userLocks[i].status = true;
                unlockedAmount += userLocks[i].amount;
                myToken.transfer(receiver, userLocks[i].amount);
                emit Released(receiver, userLocks[i].amount);
                return userLocks[i].amount;
            }
        }
        return 0;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
