pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./KyberNetworkProxyInterface.sol";
import "../ERC20.sol";

contract KyberConverter is Ownable {
    using SafeMath for uint256;
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    KyberNetworkProxyInterface public kyberNetworkProxyContract;
    address public walletId;

    ERC20 public stableToken;

    // Events
    event Swap(address indexed sender, address recepient, ERC20 srcToken, ERC20 destToken);

    /**
     * @dev Payable fallback to receive ETH while converting
     **/
    function() external payable {
    }

    constructor (KyberNetworkProxyInterface _kyberNetworkProxyContract, address _walletId, address _stableAddress) public {
        kyberNetworkProxyContract = _kyberNetworkProxyContract;
        walletId = _walletId;
        stableToken = ERC20(_stableAddress);
    }

    function setStableToken(address _stableAddress) public onlyOwner {
        stableToken = ERC20(_stableAddress);
    }

    function getStableToken() public view returns (address) {
        return address(stableToken);
    }

    /**
     * @dev Gets the conversion rate for the destToken given the srcQty.
     * @param srcToken source token contract address
     * @param destToken destination token contract address
     * @param srcQty amount of source tokens
     */
    function getExpectedRate(
        ERC20 srcToken,
        ERC20 destToken,
        uint srcQty
    ) public
    view
    returns (uint, uint)
    {
        return kyberNetworkProxyContract.getExpectedRate(srcToken, destToken, srcQty);

    }

    /**
     * @dev Swap the sender's ERC to ETH and move to the destination.
     * Note: requires 'approve' on stableToken first!
     * @param srcQty amount of source tokens
     * @param destAddress destination address
     */
    function swapMyErc(uint srcQty, address destAddress) public returns (uint256){
        uint minConversionRate;

        // Check that the token transferFrom has succeeded
        require(stableToken.transferFrom(msg.sender, address(this), srcQty));

        // Set the spender's token allowance to tokenQty
        require(stableToken.approve(address(kyberNetworkProxyContract), srcQty));

        // Get the minimum conversion rate
        (minConversionRate,) = getExpectedRate(stableToken, ETH_TOKEN_ADDRESS, srcQty);
        uint maxDestAmount = srcQty.mul(minConversionRate).mul(105).div(100);
        // +5% max

        // Swap the ERC20 token and send to 'this' contract address
        bytes memory hint;
        uint256 amount = kyberNetworkProxyContract.tradeWithHint(
            stableToken,
            srcQty,
            ETH_TOKEN_ADDRESS,
            destAddress,
            maxDestAmount,
            minConversionRate,
            walletId,
            hint
        );

        // Return the change of src token
        uint256 change = stableToken.balanceOf(address(this));
        if (change > 0) {
            require(
                stableToken.transfer(msg.sender, change),
                "Could not transfer change to sender"
            );
        }
        // Log the event
        emit Swap(msg.sender, destAddress, stableToken, ETH_TOKEN_ADDRESS);
        return amount;
    }

    /**
     * @dev Swap the sender's ETH to ERC and move to the destination.
     * @param destAddress destination address
     */
    function swapMyEth(address destAddress) public payable returns (uint256) {
        uint minConversionRate;
        uint srcQty = msg.value;

        // Get the minimum conversion rate
        (minConversionRate,) = getExpectedRate(ETH_TOKEN_ADDRESS, stableToken, srcQty);
        uint maxDestAmount = srcQty.mul(minConversionRate).mul(105).div(100);
        // +5% max

        // Swap the ERC20 token and send to destAddress
        bytes memory hint;
        uint256 amount = kyberNetworkProxyContract.tradeWithHint.value(srcQty)(
            ETH_TOKEN_ADDRESS,
            srcQty,
            stableToken,
            destAddress,
            maxDestAmount,
            minConversionRate,
            walletId,
            hint
        );
        // Return the change of ETH if any
        uint256 change = address(this).balance;
        if (change > 0) {
            address(msg.sender).transfer(change);
        }
        // Log the event
        emit Swap(msg.sender, destAddress, ETH_TOKEN_ADDRESS, stableToken);

        return amount;
    }

}