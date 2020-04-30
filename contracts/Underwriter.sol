pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/roles/SignerRole.sol";

contract Underwriter is SignerRole {

    using SafeMath for uint256;

    uint256 public constant PRECISION = 10 ** 8;
    uint256 public constant MAX_PAYOUT_MULTIPLIER = 15;
    uint256 public constant MIN_PREMIUM = 10 finney;    //0.01 ETH
    uint256 public constant MAX_PREMIUM = 150 finney;   //0.12 ETH
    // Maximum cumulated weighted premium per trip
    uint256 public constant MAX_CUMULATED_WEIGHTED_PAYOUT = 5 ether;

    uint256[2] public EMPTY_RISK = [0, 0];

    struct Risk {
        bytes32 trainNumber;
        uint256 departureTime;
        uint256 arrivalTime;
        uint256[2] premiumMultipliers;   //120+, 'cancelled' multiplier, 10 ** 8
    }

    mapping(bytes32 => Risk) public risks;

    event RiskCreated
    (
        address author,
        bytes32 riskId,
        bytes32 trainNumber,
        uint256 departureTime,
        uint256 arrivalTime,
        uint256[2] premiumMultipliers
    );

    function getRisk(bytes32 trainNumber, uint256 departureTime, uint256 arrivalTime) public view returns (uint256[2] memory) {
        bytes32 riskId = getRiskId(trainNumber, departureTime, arrivalTime);
        Risk storage risk = risks[riskId];
        if (risk.trainNumber == '') {
            return EMPTY_RISK;
        } else {
            return risk.premiumMultipliers;
        }
    }

    function getOrCreateRisk(bytes32 trainNumber, uint256 departureTime, uint256 arrivalTime, uint256 punctuality, uint256 plannedOffset) external returns (uint256[2] memory) {
        uint256[2] memory existingMultipliers = getRisk(trainNumber, departureTime, arrivalTime);
        if (existingMultipliers[0] == 0) {
            return createRisk(trainNumber, departureTime, arrivalTime, punctuality, plannedOffset);
        } else {
            return existingMultipliers;
        }
    }

    function createRisk(bytes32 trainNumber, uint256 departureTime, uint256 arrivalTime, uint256 punctuality, uint256 plannedOffset) public returns (uint256[2] memory) {
        bytes32 riskId = getRiskId(trainNumber, departureTime, arrivalTime);
        Risk storage risk = risks[riskId];
        uint256[3] memory multipliers;
        //we know for 60
        if (plannedOffset == 60) {
            multipliers[0] = multiplierForPunctuality(punctuality);
            //double the previous one
            multipliers[1] = limitMultiplier(multipliers[0].mul(2));
        } else if (plannedOffset == 120) {
            multipliers[1] = multiplierForPunctuality(punctuality);
        } else {
            require(false, 'Underwriter: unknown offset');
        }
        //double the previous one
        multipliers[2] = limitMultiplier(multipliers[1].mul(2));

        risk.trainNumber = trainNumber;
        risk.departureTime = departureTime;
        risk.arrivalTime = arrivalTime;
        risk.premiumMultipliers = [multipliers[1], multipliers[2]];
        emit RiskCreated(msg.sender, riskId, trainNumber, departureTime, arrivalTime, risk.premiumMultipliers);
        return risk.premiumMultipliers;
    }

    function multiplierForPunctuality(uint256 punctuality) internal pure returns (uint256) {
        // punctuality:
        // 25% -> 25/10/2 = x1.25;
        // 100% -> 100/10/2 = x5
        uint256 calculated = PRECISION.mul(punctuality).div(10).div(2);
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

    function resetRisk(bytes32 trainNumber, uint256 departureTime, uint256 arrivalTime) external onlySigner {
        bytes32 riskId = getRiskId(trainNumber, departureTime, arrivalTime);
        delete risks[riskId];
    }

    function validPremium(uint256 premium) public pure returns (bool) {
        return (premium >= MIN_PREMIUM && premium <= MAX_PREMIUM);
    }

    function maxCumulatedPayout() public pure returns (uint256){
        return MAX_CUMULATED_WEIGHTED_PAYOUT;
    }

    function getRiskId(bytes32 trainNumber, uint256 departureTime, uint256 arrivalTime) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(trainNumber, departureTime, arrivalTime));
    }

    function getPrecision() external view returns (uint256) {
        return PRECISION;
    }

}