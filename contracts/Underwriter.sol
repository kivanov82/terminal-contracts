pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/roles/SignerRole.sol";

contract Underwriter is SignerRole {

    using SafeMath for uint256;

    uint256 public constant PRECISION = 10 ** 8;
    uint256 public constant MAX_PAYOUT_MULTIPLIER = 15; //x15 at max
    uint256 public constant MIN_PREMIUM = 10 finney;    //0.01 ETH
    uint256 public constant MAX_PREMIUM = 150 finney;   //0.12 ETH
    // Maximum cumulated weighted premium per trip
    uint256 public constant MAX_CUMULATED_WEIGHTED_PAYOUT = 5 ether;

    uint256[2] public EMPTY_RISK = [0, 0];

    struct Risk {
        bytes32 trainNumber;
        uint256[2] premiumMultipliers;   //120+, 'cancelled' multiplier, 10 ** 8
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
        uint256[3] memory multipliers;
        //we know for 60
        if (punctuality == 60) {
            multipliers[0] = multiplierForPunctuality(punctuality);
            //double the previous one
            multipliers[1] = limitMultiplier(multipliers[0].mul(2));
        } else if (punctuality == 120) {
            multipliers[1] = multiplierForPunctuality(punctuality);
        } else {
            require(false, 'Underwriter: unknown offset');
        }
        //double the previous one
        multipliers[2] = limitMultiplier(multipliers[1].mul(2));

        risk.trainNumber = trainNumber;
        risk.premiumMultipliers = [multipliers[1], multipliers[2]];
        return risk;
    }

    function multiplierForPunctuality(uint256 punctuality) internal pure returns (uint256) {
        // assuming percentile 90%
        // x7
        uint256 calculated = PRECISION.mul(7);
        return limitMultiplier(calculated);
    }

    function limitMultiplier(uint256 multiplier) internal pure returns (uint256) {
        if (multiplier < PRECISION.mul(1)) {
            multiplier = PRECISION.mul(1);
        } else if (multiplier > MAX_PAYOUT_MULTIPLIER.mul(PRECISION)) {
            multiplier = MAX_PAYOUT_MULTIPLIER.mul(PRECISION);
        }
        return multiplier;
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