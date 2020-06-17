pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/access/roles/WhitelistedRole.sol";
import "./ReInsuranceVault.sol";
import "./ERC20.sol";

contract Vault is WhitelistedRole {

    ReInsuranceVault public reInsuranceVault;
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
        reInsuranceVault = new ReInsuranceVault(_operator, _adai, _aaveProvider, _dai, _referralCode);
        reInsuranceVault.addWhitelistAdmin(_operator);
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

    function shareProfit() public payable onlyWhitelistAdmin {
        uint256 _profit = msg.value;
        //TODO
        //SWAP ETH
        //depositReinsurance() with resulting amount
    }

    function depositReinsurance(uint _amount) public onlyWhitelistAdmin {
        token.approve(address(reInsuranceVault), _amount);
        reInsuranceVault.deposit(_amount);
    }

    function withdrawReinsurance(uint _amount) public onlyWhitelistAdmin {
        reInsuranceVault.withdraw(_amount);
    }

    function balance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

}