pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/roles/SignerRole.sol";
import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "./Vault.sol";

/**
 * @title TrainDelay
 * @dev Autonomous machinery to register active protections, underwrite them and perform the payout if the event occurs
 * Inspired by GIF framework https://github.com/etherisc/GIF/tree/master/core/gif-contracts
 *
 */
contract TrainDelay is SignerRole, Pausable {

    using SafeMath for uint256;

    Vault public vault;
    IUnderwriter public underwriter;

    struct Application {
        address payable holder;
        uint256 premium;
        uint256 payout120;
        uint256 payoutCancelled;
    }

    struct Trip {
        bytes32 trainNumber;
        Application[] applications;
        uint256 cumulatedWeightedPayout;
    }

    mapping(bytes32 => Trip) public trips;

    event ApplicationCreated
    (
        address payable holder,
        bytes32 tripId,
        bytes32 trainNumber,
        uint256 departureTime,
        uint256 arrivalTime,
        uint256 punctuality,
        uint256 plannedOffset,
        uint256[] premiumMultipliers
    );


    /**
    * @dev Default fallback function, just deposits funds to the vault
    */
    function() external payable {
        address(vault).transfer(msg.value);
    }

    constructor (address payable underwriterAddress) public {
        vault = new Vault();
        underwriter = IUnderwriter(underwriterAddress);
    }

    function applyForPolicy(
        bytes32 trainNumber,
        uint256 departureDate,
        uint256 departureTime,
        uint256 arrivalTime,
        uint256 punctuality,
        uint256 plannedOffset
    ) external payable whenNotPaused {
        uint256 premium = msg.value;
        require(underwriter.validPremium(premium), "TrainDelay: invalid premium");

        bytes32 tripId = keccak256(
            abi.encodePacked(trainNumber, departureDate)
        );
        Trip storage trip = trips[tripId];
        if (trip.trainNumber == "") {
            //first policy for this trip
            trip.trainNumber = trainNumber;
        }

        uint256[] memory premiumMultipliers;
        premiumMultipliers[0] = 5;
        premiumMultipliers[1] = 10;
        //uint256[2] memory premiumMultiplier = underwriter.getOrCreateRisk(trainNumber, departureTime, arrivalTime, punctuality, plannedOffset);
        trip.cumulatedWeightedPayout = trip.cumulatedWeightedPayout.add(premium.mul(premiumMultipliers[1]));
        require(trip.cumulatedWeightedPayout <= underwriter.maxCumulatedPayout(), "TrainDelay: risk limit");

        Application memory application = Application(msg.sender, premium, premium.mul(premiumMultipliers[0]), premium.mul(premiumMultipliers[1]));
        trip.applications.push(application);

        address(vault).transfer(premium);
        emit ApplicationCreated(msg.sender, tripId, trainNumber, departureTime, arrivalTime, punctuality, plannedOffset, premiumMultipliers);

    }

    function claimDelegated(bytes32 tripId, address payable holder) external onlySigner {

    }

    function resolveTrip(bytes32 tripId) public onlySigner {
        delete trips[tripId];
    }

    function withdrawVault(uint256 amount, address payable intermediary) public onlySigner {
        require(intermediary != address(0));
        vault.withdraw(intermediary, amount);
    }


    function replaceUnderwriter(address payable newUnderwriter) public onlySigner {
        underwriter = IUnderwriter(newUnderwriter);
    }

}

interface IUnderwriter {

    function getOrCreateRisk(bytes32 trainNumber, uint256 departureTime, uint256 arrivalTime, uint256 punctuality, uint256 plannedOffset) external returns (uint256[2] memory);

    function validPremium(uint256 premium) external view returns (bool);

    function maxCumulatedPayout() external view returns (uint256);

}