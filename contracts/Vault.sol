pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/access/roles/WhitelistedRole.sol";
import "./ReInsuranceProvider.sol";
import "./ERC20.sol";

contract Vault is WhitelistedRole {

    ReInsuranceProvider public reInsuranceProvider;
    ERC20 public token;

    event LogEthReceived(
        uint256 amount,
        address indexed account
    );

    event LogEthSent(
        uint256 amount,
        address indexed account
    );

    event LogTokenSent(
        uint256 amount,
        address indexed account
    );

    /**
    * @dev funding vault is allowed
    **/
    function() external payable {
        emit LogEthReceived(msg.value, msg.sender);
    }

    constructor (address _operator, address _adai, address _aaveProvider, address _dai, uint16 _referralCode) public {
        token = ERC20(_dai);
        reInsuranceProvider = new ReInsuranceProvider(_operator, _adai, _aaveProvider, _dai, _referralCode);
        reInsuranceProvider.addWhitelistAdmin(_operator);
    }

    function withdrawDAI(uint256 _payment) public onlyWhitelistAdmin {
        require(_payment > 0 && token.balanceOf(address(this)) >= _payment, "Insufficient funds in the fund");
        token.transfer(msg.sender, _payment);
        emit LogTokenSent(_payment, msg.sender);
    }

    function withdrawETH(address payable _operator, uint256 _payment) public onlyWhitelistAdmin {
        require(address(this).balance > 0, 'Vault is empty');
        _operator.transfer(_payment);
        emit LogEthSent(_payment, _operator);
    }

    function depositResinsurance(uint _amount) public onlyWhitelistAdmin {
        token.approve(address(reInsuranceProvider), _amount);
        reInsuranceProvider.deposit(address(this), _amount);
    }

    function withdrawResinsurance(uint _amount) public onlyWhitelistAdmin {
        reInsuranceProvider.withdraw(address(this), _amount);
    }

    function balance() external view returns (uint256 balance) {
        return token.balanceOf(address(this));
    }
}