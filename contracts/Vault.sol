pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/access/roles/WhitelistedRole.sol";
import "./ReInsuranceVault.sol";
import "./ERC20.sol";
import "./TokenConverter.sol";

contract Vault is WhitelistedRole {

    ReInsuranceVault public reInsuranceVault;
    TokenConverter public converter;
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
    * Might be a free will or from a token converter
    **/
    function() external payable {
        emit LogEthReceived(msg.value, msg.sender);
    }

    constructor (address _operator, address _adai, address _aaveProvider, address _dai, uint16 _referralCode, address _converter) public {
        token = ERC20(_dai);
        converter = TokenConverter(_converter);
        reInsuranceVault = new ReInsuranceVault(_operator, _adai, _aaveProvider, _dai, _referralCode, _converter);
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
        uint256 _tokenAmount = converter.swapMyEth.value(_amount)(address(reInsuranceVault));
        reInsuranceVault.depositAave(_tokenAmount);
    }

    function withdrawReinsurance(uint _amount) public onlyWhitelistAdmin {
        //aDai -> DAI and move here
        reInsuranceVault.withdraw(_amount);
        //allow converter to use our DAI
        token.approve(address(converter), _amount);
        //convert DAI -> ETH and move it here
        converter.swapMyErc(_amount, address(this));
    }

    function balance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

}