pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/access/roles/SignerRole.sol";
import "./Vault.sol";

contract TrainDelay is SignerRole {

    Vault public vault;

    /**
    * @dev Default fallback function, just deposits funds the vault
    */
    function() external payable {
        ((address) (vault)).call.value(msg.value)("");
    }

    constructor () public {
        vault = new Vault();
    }


    function withdrawVault(uint256 _amount, address payable _intermediary) public onlySigner {
        require(_intermediary != address(0));
        vault.withdraw(_intermediary, _amount);
    }

}