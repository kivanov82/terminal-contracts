pragma solidity ^0.5.8;

interface TokenConverter {

    function swapMyErc(uint srcQty, address payable destAddress) external returns (uint256);

    function swapMyEth(address destAddress) external payable returns (uint256);
}