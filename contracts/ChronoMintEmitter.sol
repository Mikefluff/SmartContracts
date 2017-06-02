pragma solidity ^0.4.8;

import "./EventsHistory.sol";

/**
 * @title ChronoMint Emitter.
 *
 * Contains all the original event emitting function definitions and events.
 * In case of new events needed later, additional emitters can be developed.
 * All the functions is meant to be called using delegatecall.
 */
library ChronoMintEmitter {
    // Period closed/started.
    event PeriodClosed(uint PeriodId, uint version);
    // Rewards asset registered to distribute accumulated balance.
    event AssetRegistration(address indexed assetAddress, uint balance, uint version);
    // Rewards from a period distributed for a shareholder.
    event CalculateReward(address indexed assetAddress, address indexed who, uint reward, uint version);
    // Reward withdrawn for a shareholder.
    event WithdrawReward(address indexed assetAddress, address indexed who, uint amount, uint version);
    //CBE list update
    event CBEUpdate(address indexed key, uint version);
    //Required signatures amount update
    event SetRequired(uint required, uint version);

    event HashUpdate(bytes32 oldHash, bytes32 newHash, uint version);

    event NewLOC(bytes32 indexed locName, uint version);
    event RemLOC(bytes32 indexed locName, uint version);
    event UpdLOCStatus(bytes32 indexed locName, uint _oldStatus, uint _newStatus, uint version);
    event UpdLOCValue(bytes32 indexed locName, uint version);
    event Reissue(uint value, bytes32 indexed locName, uint version);

    function periodClosed(uint periodId) {
        PeriodClosed(periodId, _getVersion());
    }

    function assetRegistration(address assetAddress, uint balance) {
        AssetRegistration(assetAddress, balance, _getVersion());
    }

    function calculateReward(address assetAddress, address who, uint reward) {
        CalculateReward(assetAddress, who, reward, _getVersion());
    }

    function withdrawReward(address assetAddress, address who, uint amount) {
        WithdrawReward(assetAddress, who, amount, _getVersion());
    }

    function cbeUpdate(address key) {
        CBEUpdate(key, _getVersion());
    }
    function setRequired(uint required) {
        SetRequired(required, _getVersion());
    }

    function hashUpdate(bytes32 oldHash, bytes32 newHash) {
        HashUpdate(oldHash, newHash, _getVersion());
    }

    function newLOC(bytes32 locName) {
        NewLOC(locName, _getVersion());
    }

    function remLOC(bytes32 locName) {
        RemLOC(locName, _getVersion());
    }

    function updLOCStatus(bytes32 locName, uint _oldStatus, uint _newStatus) {
        UpdLOCStatus(locName, _oldStatus, _newStatus, _getVersion());
    }

    function updLOCValue(bytes32 locName) {
        UpdLOCValue(locName, _getVersion());
    }

    function reissue(uint value, bytes32 locName) {
        Reissue(value, locName, _getVersion());
    }

    /**
     * Get version number of the caller.
     *
     * Assuming that the call is made by EventsHistory using delegate call,
     * context was not changed, so the caller is the address that called
     * EventsHistory.
     *
     * @return current context caller version number.
     */
    function _getVersion() constant internal returns(uint) {
        return EventsHistory(address(this)).versions(msg.sender);
    }
}
