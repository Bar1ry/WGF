// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract IEO is Pausable, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public myToken;
    uint256 public rate = 133940;
    uint256 public sales = 0 ether;
    uint256 public total = 375000000 ether;
    address public vc;

    struct Lock {
        address user;
        uint256 unlockTime;
        uint256 amount;
        bool status;
    }
    mapping(address => Lock[]) private locks;

    event Buy(address indexed _from, uint256 _ether, uint256 _amount);
    event Released(address indexed receiver, uint256 amount);

    struct Holder {
        address addr;
        uint256 amount;
    }
    mapping(address => Holder) public holders;

    constructor(address _token, address _vc) {
        vc = _vc;
        myToken = IERC20(_token);
    }

    function buy() public payable whenNotPaused {
        require(sales < total, "Sold out");
        require(msg.value >= 0.2 ether, "Insufficient amount of >= 0.2ETH");

        uint256 tokenAmount = msg.value.mul(rate);
        sales += tokenAmount;

        require(
            myToken.balanceOf(address(this)) >= tokenAmount,
            "Token Insufficient allowance"
        );

        payable(vc).transfer(msg.value);

        uint256 getAmount = tokenAmount.mul(30).div(100);

        myToken.transfer(_msgSender(), getAmount);

        holders[_msgSender()].amount += getAmount;

        emit Buy(_msgSender(), msg.value, getAmount);

        uint256 unlock1 = tokenAmount.mul(30).div(100);
        uint256 unlock2 = tokenAmount.mul(40).div(100);

        locks[_msgSender()].push(
            Lock(_msgSender(), block.timestamp + 180 days, unlock1, false)
        );
        locks[_msgSender()].push(
            Lock(_msgSender(), block.timestamp + 540 days, unlock2, false)
        );
    }

    function getLocks(address _user) public view returns (Lock[] memory) {
        return locks[_user];
    }

    function release() public whenNotPaused returns (uint256) {
        Lock[] storage userLocks = locks[_msgSender()];
        for (uint256 i = 0; i < userLocks.length; i++) {
            if (
                block.timestamp >= userLocks[i].unlockTime &&
                !userLocks[i].status
            ) {
                userLocks[i].status = true;
                myToken.transfer(_msgSender(), userLocks[i].amount);
                emit Released(_msgSender(), userLocks[i].amount);
                return userLocks[i].amount;
            }
        }
        return 0;
    }

    function totalBuy() public view returns (uint256) {
        return holders[_msgSender()].amount;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    receive() external payable {}
}
