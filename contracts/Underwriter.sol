pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/roles/SignerRole.sol";

contract Underwriter is SignerRole {

    using SafeMath for uint256;

    uint256 public constant MIN_PREMIUM = 10 finney;
    uint256 public constant MAX_PREMIUM = 150 finney;
    // Maximum cumulated weighted premium per trip
    uint256 public constant MAX_CUMULATED_WEIGHTED_PAYOUT = 5 ether;

    // ['60+', '120+', 'cancelled']
    uint8[3] public WEIGHT_PATTERN = [10, 30, 100];

    struct Risk {
        bytes32 trainNumber;
        bytes32 departureTime;
        uint256 arrivalTime;
        uint256[2] premiumMultipliers;   //120+, 'cancelled' multiplier, 10 ** 3
    }

    mapping(bytes32 => Risk) public risks;

    event RiskCreated
    (
        bytes32 riskId,
        bytes32 trainNumber,
        uint256 departureTime,
        uint256 arrivalTime,
        uint256[2] premiumMultipliers
    );

    function getOrCreateRisk(bytes32 trainNumber, uint256 departureTime, uint256 arrivalTime, uint256 punctuality, uint256 plannedOffset) external onlySigner returns (uint256[2] memory) {
        bytes32 riskId = getRiskId(trainNumber, departureTime, arrivalTime);
        Risk storage risk = risks[riskId];
        if (risk.trainNumber == '') {
            return risk.premiumMultipliers;
        } else {
            return createRisk(trainNumber, departureTime, arrivalTime, punctuality, plannedOffset);
        }
    }

    function createRisk(bytes32 trainNumber, uint256 departureTime, uint256 arrivalTime, uint256 punctuality, uint256 plannedOffset) public onlySigner returns (uint256[2] memory) {
        bytes32 riskId = getRiskId(trainNumber, departureTime, arrivalTime);
        Risk storage risk = risks[riskId];
        uint8 weightFrom;
        if (plannedOffset == 60) {
            weightFrom = WEIGHT_PATTERN[0];
        }
        risk.trainNumber = trainNumber;
        risk.premiumMultipliers = [5, 10];
        emit RiskCreated(riskId, trainNumber, departureTime, arrivalTime, risk.premiumMultipliers);
        return risk.premiumMultipliers;
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

}