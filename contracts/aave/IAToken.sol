pragma solidity ^0.5.8;

interface IAToken {
    function redeem(uint256 _amount) external;

    function redirectInterestStream(address _to) external;

    function isTransferAllowed(address _user, uint256 _amount) external view returns (bool);

}