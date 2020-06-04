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
        bytes32 origin,
        bytes32 destination,
        uint256 departureDateTime,
        uint256 arrivalDateTime,
        uint256 punctuality,
        uint256 premium,
        uint256[2] premiumMultipliers
    );

    event ApplicationResolved
    (
        address payable holder,
        uint256 premium,
        uint256 payout,
        bytes32 tripId
    );


    /**
    * @dev Default fallback function, just deposits funds to the vault
    */
    function() external payable {
        address(vault).transfer(msg.value);
    }

    constructor (address payable underwriterAddress, address _adai, address _aaveProvider, address _dai, uint16 _referralCode) public {
        vault = new Vault(msg.sender, _adai, _aaveProvider, _dai, _referralCode);
        vault.addWhitelistAdmin(msg.sender);
        underwriter = IUnderwriter(underwriterAddress);
    }

    function applyForPolicy(
        bytes32 trainNumber,
        bytes32 origin,
        bytes32 destination,
        uint256 departureDateTime,
        uint256 arrivalDateTime,
        uint256 punctuality
    ) external payable whenNotPaused {
        uint256 premium = msg.value;
        address payable holder = msg.sender;
        require(underwriter.validPremium(premium), "TrainDelay: invalid premium");

        bytes32 tripId = keccak256(
            abi.encodePacked(trainNumber, departureDateTime)
        );
        Trip storage trip = trips[tripId];
        if (trip.trainNumber == "") {
            //first policy for this trip
            trip.trainNumber = trainNumber;
        }

        uint256[2] memory premiumMultipliers = underwriter.getOrCreateRisk(trainNumber, punctuality);
        trip.cumulatedWeightedPayout = trip.cumulatedWeightedPayout.add(premium.mul(premiumMultipliers[1]).div(underwriter.getPrecision()));
        require(trip.cumulatedWeightedPayout <= underwriter.maxCumulatedPayout(), "TrainDelay: trip risk limit");

        Application memory application = Application(holder, premium,
            premium.mul(premiumMultipliers[0]).div(underwriter.getPrecision()),
            premium.mul(premiumMultipliers[1]).div(underwriter.getPrecision()));
        trip.applications.push(application);

        address(vault).transfer(premium);
        emit ApplicationCreated(holder, tripId, trainNumber, origin, destination, departureDateTime, arrivalDateTime, punctuality, premium, premiumMultipliers);
    }

    function claimTripDelegated(bytes32 tripId, bytes32 cause) external onlySigner {
        for (uint8 i = 0; i < trips[tripId].applications.length; i++) {
            Application memory application = trips[tripId].applications[i];
            if (cause == 0) {
                emit ApplicationResolved(application.holder, application.premium, 0, tripId);
            }
            else if (cause == '120') {
                withdrawVault(application.payout120, application.holder);
                emit ApplicationResolved(application.holder, application.premium, application.payout120, tripId);
            } else if (cause == 'cancelled') {
                withdrawVault(application.payoutCancelled, application.holder);
                emit ApplicationResolved(application.holder, application.premium, application.payoutCancelled, tripId);
            }
            else {
                require(false, 'TrainDelay: cause not supported');
            }
        }
        resolveTrip(tripId);
    }

    function resolveTrip(bytes32 tripId) internal onlySigner {
        delete trips[tripId];
    }

    function withdrawVault(uint256 amount, address payable intermediary) public onlySigner {
        require(intermediary != address(0));
        vault.withdrawETH(intermediary, amount);
    }


    function replaceUnderwriter(address payable newUnderwriter) public onlySigner {
        underwriter = IUnderwriter(newUnderwriter);
    }

}

interface IUnderwriter {

    function getRisk(bytes32 trainNumber, uint256 punctuality) external view returns (uint256[2] memory);

    function getOrCreateRisk(bytes32 trainNumber, uint256 punctuality) external returns (uint256[2] memory);

    function validPremium(uint256 premium) external view returns (bool);

    function maxCumulatedPayout() external view returns (uint256);

    function getPrecision() external view returns (uint256);

}