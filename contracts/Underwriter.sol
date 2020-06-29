pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/roles/SignerRole.sol";

contract Underwriter is SignerRole {

    using SafeMath for uint256;

    uint256 public constant PRECISION = 10 ** 8;
    uint256 public constant MIN_PREMIUM = 10 finney;    //0.01 ETH
    uint256 public constant MAX_PREMIUM = 150 finney;   //0.12 ETH
    // Maximum cumulated weighted premium per trip
    uint256 public constant MAX_CUMULATED_WEIGHTED_PAYOUT = 3 ether;

    uint256[2] public EMPTY_RISK = [0, 0];

    struct Risk {
        bytes32 trainNumber;
        uint256[2] premiumMultipliers;   //60+, 'cancelled' multiplier, 10 ** 8
    }

    mapping(bytes32 => Risk) public risks;

    event RiskCreated
    (
        address author,
        bytes32 trainNumber,
        uint256[2] premiumMultipliers
    );

    function getRisk(bytes32 trainNumber, uint256 punctuality) public view returns (uint256[2] memory) {
        Risk memory risk = risks[trainNumber];
        if (risk.trainNumber == '') {
            return calculateRisk(trainNumber, punctuality).premiumMultipliers;
        } else {
            return risk.premiumMultipliers;
        }
    }

    function getOrCreateRisk(bytes32 trainNumber, uint256 punctuality) external onlySigner returns (uint256[2] memory) {
        Risk memory existing = risks[trainNumber];
        if (existing.trainNumber == '') {
            Risk memory newRisk = calculateRisk(trainNumber, punctuality);
            risks[trainNumber] = newRisk;
            emit RiskCreated(msg.sender, trainNumber, newRisk.premiumMultipliers);
            return newRisk.premiumMultipliers;
        } else {
            return existing.premiumMultipliers;
        }
    }

    function calculateRisk(bytes32 trainNumber, uint256 punctuality) internal pure returns (Risk memory) {
        Risk memory risk;
        risk.trainNumber = trainNumber;
        risk.premiumMultipliers[0] = multiplierForPunctuality(punctuality);
        risk.premiumMultipliers[1] = PRECISION.mul(10);
        return risk;
    }

    function multiplierForPunctuality(uint256 punctuality) internal pure returns (uint256) {
        // assuming percentile 95%
        if (punctuality <= 60) {
            return PRECISION.mul(15);
        } else {
            return PRECISION.mul(7);
        }
    }

    function resetRisk(bytes32 trainNumber) external onlySigner {
        delete risks[trainNumber];
    }

    function validPremium(uint256 premium) public pure returns (bool) {
        return (premium >= MIN_PREMIUM && premium <= MAX_PREMIUM);
    }

    function maxCumulatedPayout() public pure returns (uint256){
        return MAX_CUMULATED_WEIGHTED_PAYOUT;
    }

    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

}