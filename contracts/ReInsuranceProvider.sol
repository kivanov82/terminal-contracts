pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/access/roles/WhitelistedRole.sol";
import "./aave/ILendingPool.sol";
import "./aave/IAToken.sol";
import "./ERC20.sol";

contract ReInsuranceProvider is WhitelistedRole {

    address public ADAI_ADDRESS;
    address public AAVE_LENDING_POOL;
    address public AAVE_LENDING_POOL_CORE;
    address public DAI_ADDRESS;

    address operator;

    constructor (address _operator, address _adai, address _aavePool, address _aaveCore, address _dai) public {
        operator = _operator;
        ADAI_ADDRESS = _adai;
        AAVE_LENDING_POOL = _aavePool;
        AAVE_LENDING_POOL_CORE = _aaveCore;
        DAI_ADDRESS = _dai;
        IAToken(ADAI_ADDRESS).redirectInterestStream(_operator);
    }

    function deposit(address _user, uint _amount) public onlyWhitelistAdmin {
        require(msg.sender == _user);
        // temporary move token into here
        require(ERC20(DAI_ADDRESS).transferFrom(_user, address(this), _amount));

        ERC20(DAI_ADDRESS).approve(AAVE_LENDING_POOL_CORE, uint(- 1));
        ILendingPool(AAVE_LENDING_POOL).deposit(DAI_ADDRESS, _amount, 0);

        ERC20(ADAI_ADDRESS).transfer(_user, ERC20(ADAI_ADDRESS).balanceOf(address(this)));
    }

    function withdraw(address _user, uint _amount) public onlyWhitelistAdmin {
        require(msg.sender == _user);
        require(ERC20(ADAI_ADDRESS).transferFrom(_user, address(this), _amount));

        //not used as a collateral
        require(IAToken(ADAI_ADDRESS).isTransferAllowed(_user, _amount));
        IAToken(ADAI_ADDRESS).redeem(_amount);

        // return dai we have to user
        ERC20(DAI_ADDRESS).transfer(_user, _amount);
    }

    function getLendingAPY() external view returns (uint256) {
        (,,,,uint256 liquidityRate,,,,,,,,) = ILendingPool(AAVE_LENDING_POOL).getReserveData(DAI_ADDRESS);
        return liquidityRate;
    }

    function getLifetimeProfit() external view returns (uint256) {
        return ERC20(ADAI_ADDRESS).balanceOf(operator);
    }
}