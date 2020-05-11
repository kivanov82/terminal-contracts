pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/access/roles/WhitelistedRole.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./aave/ILendingPool.sol";
import "./aave/IAToken.sol";
import "./ERC20.sol";
import "./aave/ILendingPoolAddressesProvider.sol";

contract ReInsuranceProvider is WhitelistedRole {

    using SafeMath for uint256;

    ILendingPoolAddressesProvider public aaveAddressesProvider;

    address public ADAI_ADDRESS;
    address public AAVE_LENDING_POOL;
    address public AAVE_LENDING_POOL_CORE;
    address public DAI_ADDRESS;
    uint16 referralCode;

    mapping(address => uint256) private userReserves;

    address operator;

    constructor (address _operator, address _adai, address _aaveProvider, address _dai, uint16 _referralCode) public {
        operator = _operator;
        aaveAddressesProvider = ILendingPoolAddressesProvider(_aaveProvider);
        ADAI_ADDRESS = _adai;
        AAVE_LENDING_POOL = aaveAddressesProvider.getLendingPool();
        //AAVE_LENDING_POOL_CORE = aaveAddressesProvider.getLendingPoolCore();
        DAI_ADDRESS = _dai;
        referralCode = _referralCode;
    }

    function deposit(address _user, uint _amount) public onlyWhitelistAdmin {
        require(msg.sender == _user);
        // temporary move token into here
        require(ERC20(DAI_ADDRESS).transferFrom(_user, address(this), _amount));

        ERC20(DAI_ADDRESS).approve(AAVE_LENDING_POOL_CORE, uint(- 1));
        ILendingPool(AAVE_LENDING_POOL).deposit(DAI_ADDRESS, _amount, referralCode);
        if (IAToken(ADAI_ADDRESS).getInterestRedirectionAddress(operator) == address(0)) {
            //first deposit ever
            //start redirecting interest
            IAToken(ADAI_ADDRESS).redirectInterestStream(operator);
        }

        userReserves[_user] = userReserves[_user].add(_amount);
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

        userReserves[_user] = userReserves[_user].sub(_amount, "ReInsuranceProvider: withdraw amount exceeds deposited");
    }

    function reserveOf(address account) public view returns (uint256) {
        return userReserves[account];
    }

    function getLendingAPY() external view returns (uint256) {
        (,,,,uint256 liquidityRate,,,,,,,,) = ILendingPool(AAVE_LENDING_POOL).getReserveData(DAI_ADDRESS);
        return liquidityRate;
    }

    function getLifetimeProfit() external view returns (uint256) {
        //TODO not really accurate data
        return ERC20(ADAI_ADDRESS).balanceOf(operator);
    }
}