pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/access/roles/WhitelistedRole.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./aave/ILendingPool.sol";
import "./aave/IAToken.sol";
import "./ERC20.sol";
import "./aave/ILendingPoolAddressesProvider.sol";
import "./TokenConverter.sol";

contract ReInsuranceVault is WhitelistedRole {

    using SafeMath for uint256;

    ILendingPoolAddressesProvider public aaveAddressesProvider;
    TokenConverter public converter;

    address public ADAI_ADDRESS;
    address public AAVE_LENDING_POOL;
    address public AAVE_LENDING_POOL_CORE;
    address public DAI_ADDRESS;
    uint16 referralCode;

    address operator;

    constructor (address _operator, address _adai, address _aaveProvider, address _dai, uint16 _referralCode, address _converter) public {
        operator = _operator;
        converter = TokenConverter(_converter);
        aaveAddressesProvider = ILendingPoolAddressesProvider(_aaveProvider);
        ADAI_ADDRESS = _adai;
        AAVE_LENDING_POOL = aaveAddressesProvider.getLendingPool();
        AAVE_LENDING_POOL_CORE = aaveAddressesProvider.getLendingPoolCore();
        DAI_ADDRESS = _dai;
        referralCode = _referralCode;
    }

    /**
    * @dev Msg.sender deposits DAI into here, and the actual interest will be forwarded to 'operator'
    * Usually called by the Vault which holds DAI
    **/
    function deposit(uint _amount) public onlyWhitelistAdmin {
        address _user = msg.sender;
        // move token into here
        require(ERC20(DAI_ADDRESS).transferFrom(_user, address(this), _amount));
        depositAave(_amount);
    }

    function depositAave(uint _amount) public onlyWhitelistAdmin {
        ERC20(DAI_ADDRESS).approve(AAVE_LENDING_POOL_CORE, uint(- 1));
        ILendingPool(AAVE_LENDING_POOL).deposit(DAI_ADDRESS, _amount, referralCode);
        //TODO
        //Keep track of each the depositor's balance:
        //initial aToken + keep track of interest + terminal fee
        /*if (IAToken(ADAI_ADDRESS).getInterestRedirectionAddress(address(this)) == address(0)) {
            //first deposit
            //start redirecting interest to 'operator'
            IAToken(ADAI_ADDRESS).redirectInterestStream(operator);
        }*/
    }

    /**
    * @dev Msg.sender triggers the withdrawal from Aave, the DAI will be moved to the caller
    * Usually called by the Vault
    **/
    function withdraw(uint _amount) public onlyWhitelistAdmin {
        address _user = msg.sender;

        //if not used as a collateral
        require(IAToken(ADAI_ADDRESS).isTransferAllowed(address(this), _amount));
        IAToken(ADAI_ADDRESS).redeem(_amount);

        // return dai we have to user
        ERC20(DAI_ADDRESS).transfer(_user, _amount);
    }

    /**
    * @dev Operator withdraws his interest, receiving DAI back
    **/
    function withdrawInterest(uint _amount) public onlyWhitelistAdmin {
        //temporary move aDAI into here
        require(ERC20(ADAI_ADDRESS).transferFrom(msg.sender, address(this), _amount));
        withdraw(_amount);
    }

    function balance() external view returns (uint256) {
        return IAToken(ADAI_ADDRESS).balanceOf(address(this));
    }

    function getLendingAPY() external view returns (uint256) {
        (,,,,uint256 liquidityRate,,,,,,,,) = ILendingPool(AAVE_LENDING_POOL).getReserveData(DAI_ADDRESS);
        return liquidityRate;
    }

    /**
    * @dev Sums up (current) differences between cumulated aToken balance and historic deposit
    * And sums it up for every depositor
    **/
    function getLifetimeProfit() external view returns (uint256) {
        //TODO not really accurate data
        return ERC20(ADAI_ADDRESS).balanceOf(address(this));
    }
}