pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/access/roles/WhitelistedRole.sol";
import "./ReInsuranceProvider.sol";

contract Vault is WhitelistedRole {

    ReInsuranceProvider public reInsuranceProvider;

    event LogEthReceived(
        uint256 amount,
        address indexed account
    );

    event LogEthSent(
        uint256 amount,
        address indexed account
    );

    /**
    * @dev funding vault is allowed
    **/
    function() external payable {
        emit LogEthReceived(msg.value, msg.sender);
    }

    constructor (address _operator) public {
        reInsuranceProvider = new ReInsuranceProvider(_operator);
        reInsuranceProvider.addWhitelistAdmin(_operator);
    }

    function withdraw(address payable _operator, uint256 _payment) public onlyWhitelistAdmin {
        require(address(this).balance > 0, 'Vault is empty');
        _operator.transfer(_payment);
        emit LogEthSent(_payment, _operator);
    }

    function depositReserve(uint _amount) public onlyWhitelistAdmin {
        reInsuranceProvider.deposit(address(this), _amount);
    }

    function withdrawReserve(uint _amount) public onlyWhitelistAdmin {
        reInsuranceProvider.withdraw(address(this), _amount);
    }
}