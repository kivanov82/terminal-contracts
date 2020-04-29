pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/ownership/Secondary.sol";

contract Vault is Secondary {

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

    function withdraw(address payable _operator, uint256 _payment) public onlyPrimary {
        require(address(this).balance > 0, 'Vault is empty');
        _operator.transfer(_payment);
        emit LogEthSent(_payment, _operator);
    }
}