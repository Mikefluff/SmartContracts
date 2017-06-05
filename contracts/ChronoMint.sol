pragma solidity ^0.4.8;

import "./Managed.sol";
import "./AssetsManagerInterface.sol";
import "./ERC20Interface.sol";
import "./ERC20ManagerInterface.sol";
import "./FeeInterface.sol";
import "./ChronoBankAssetProxyInterface.sol";

contract Emitter {

    function newLOC(bytes32 locName);
    function removeLOC(bytes32 locName);
    function updateLOC(bytes32 newLocName, bytes32 oldLocName);
    function reissue(uint value, bytes32 locName);
    function hashUpdate(bytes32 oldHash, bytes32 newHash);
    function emitError(bytes32 _message);
}

contract ChronoMint is Managed {

    mapping (bytes32 => LOC) offeringCompanies;
    bytes32[] public offeringCompaniesNames;

    enum Status {maintenance, active, suspended, bankrupt}

    struct LOC {
        bytes32 name;
        bytes32 website;
        uint issued;
        uint issueLimit;
        bytes32 publishedHash;
        uint expDate;
        Status status;
        uint securityPercentage;
        bytes32 currency;
        uint createDate;
    }

    function init(address _contractsManager) returns(bool) {
        if(contractsManager != 0x0)
            return false;
        if(!ContractsManagerInterface(_contractsManager).addContract(this,ContractsManagerInterface.ContractType.LOCManager,'LOCs Manager',0x0,0x0))
            return false;
        contractsManager = _contractsManager;
        return true;
    }

    // Should use interface of the emitter, but address of events history.
    Emitter public eventsHistory;

    /**
     * Emits Error event with specified error message.
     *
     * Should only be used if no state changes happened.
     *
     * @param _message error message.
     */
    function _error(bytes32 _message) internal {
        eventsHistory.emitError(_message);
    }
    /**
     * Sets EventsHstory contract address.
     *
     * Can be set only once, and only by contract owner.
     *
     * @param _eventsHistory EventsHistory contract address.
     *
     * @return success.
     */
    function setupEventsHistory(address _eventsHistory) returns(bool) {
        if (address(eventsHistory) != 0) {
            return false;
        }
        eventsHistory = Emitter(_eventsHistory);
        return true;
    }

    modifier locExists(bytes32 _locName) {
        if (offeringCompanies[_locName].name != bytes32(0)) {
            _;
        }
    }

    modifier locDoesNotExist(bytes32 _locName) {
        if (_locName != 0x0 && offeringCompanies[_locName].name == bytes32(0)) {
            _;
        }
    }

    function sendAsset(bytes32 _symbol, address _to, uint _value) onlyAuthorized returns (bool) {
        return AssetsManagerInterface(ContractsManagerInterface(contractsManager).getContractAddressByType(ContractsManagerInterface.ContractType.AssetsManager)).sendAsset(_symbol, _to, _value);
    }

    function reissueAsset(uint _value, bytes32 _locName) multisig returns (bool) {
        uint issued = offeringCompanies[_locName].issued;
        if(_value <= offeringCompanies[_locName].issueLimit - issued) {
            if(AssetsManagerInterface(ContractsManagerInterface(contractsManager).getContractAddressByType(ContractsManagerInterface.ContractType.AssetsManager)).reissueAsset(offeringCompanies[_locName].currency, _value)) {
                offeringCompanies[_locName].issued = issued + _value;
                eventsHistory.reissue(_value,_locName);
                return true;
            }
        }
        return false;
    }

    function revokeAsset(uint _value, bytes32 _locName) multisig returns (bool) {
        uint issued = offeringCompanies[_locName].issued;
        if(_value <= issued) {
            if(AssetsManagerInterface(ContractsManagerInterface(contractsManager).getContractAddressByType(ContractsManagerInterface.ContractType.AssetsManager)).revokeAsset(offeringCompanies[_locName].currency, _value)) {
                offeringCompanies[_locName].issued = issued - _value;
                eventsHistory.reissue(_value, _locName);
                return true;
            }
        }
        return false;
    }

    function removeLOC(bytes32 _name) locExists(_name) multisig returns (bool) {
        for (uint i = 0; i < offeringCompaniesNames.length; i++) {
            if (offeringCompaniesNames[i] == _name) {
                offeringCompaniesNames[i] = offeringCompaniesNames[offeringCompaniesNames.length - 1];
                offeringCompaniesNames.length -= 1;
                break;
            }
        }
        delete offeringCompanies[_name];
        eventsHistory.removeLOC(_name);
        return true;
    }

    function addLOC(bytes32 _name, bytes32 _website, uint _issueLimit, bytes32 _publishedHash, uint _expDate, Status _status, bytes32 _currency) onlyAuthorized() locDoesNotExist(_name) returns (bool) {
        offeringCompanies[_name] = LOC({
            name: _name,
            website: _website,
            issued: 0,
            issueLimit:_issueLimit,
            publishedHash: _publishedHash,
            expDate:_expDate,
            status: _status,
            securityPercentage: 0,
            currency: _currency,
            createDate: now
        });
        offeringCompaniesNames.push(_name);
        eventsHistory.newLOC(_name);
        return true;
    }

    function setLOC(bytes32 _name, bytes32 _newName, bytes32 _website, uint _issueLimit, bytes32 _publishedHash, uint _expDate, Status _status) onlyAuthorized() locExists(_name) returns(bool) {
        LOC loc = offeringCompanies[_name];
        bool changed = false;
        if(!(_newName == _name)) {
            uint _id;
            for (uint i = 0; i < offeringCompaniesNames.length; i++) {
                if (offeringCompaniesNames[i] == loc.name) {
                    _id = i;
                    break;
                }
            }
            offeringCompaniesNames[_id] = _newName;
            loc.name = _newName;
            offeringCompanies[_newName] = loc;
            delete offeringCompanies[_name];
        }
        if(!(_website == loc.website)) {
            loc.website = _website;
            changed = true;
        }
        if(!(_issueLimit == loc.issueLimit)) {
            loc.issueLimit = _issueLimit;
            changed = true;
        }
        if(!(_publishedHash == loc.publishedHash)) {
            eventsHistory.hashUpdate(loc.publishedHash,_publishedHash);
            loc.publishedHash = _publishedHash;
            changed = true;
        }
        if(!(_expDate == loc.expDate)) {
            loc.expDate = _expDate;
            changed = true;
        }
        if(!(_status == loc.status)) {
            loc.status = _status;
            changed = true;
        }
        if(changed) {
            offeringCompanies[_name] = loc;
            eventsHistory.updateLOC(_newName, _name);
        }
        return changed;
    }

    function getLOCByName(bytes32 _locName) constant returns(bytes32 name,
    bytes32 website,
    uint issued,
    uint issueLimit,
    bytes32 publishedHash,
    uint expDate,
    Status status,
    uint securityPercentage,
    bytes32 currency,
    uint createDate) {
        LOC loc = offeringCompanies[_locName];
        return(loc.name, loc.website, loc.issued, loc.issueLimit, loc.publishedHash, loc.expDate, loc.status, loc.securityPercentage, loc.currency, loc.createDate);
    }

    function getLOCById(uint _id) constant returns(bytes32 name,
    bytes32 website,
    uint issued,
    uint issueLimit,
    bytes32 publishedHash,
    uint expDate,
    Status status,
    uint securityPercentage,
    bytes32 currency,
    uint createDate) {
        LOC loc = offeringCompanies[offeringCompaniesNames[_id]];
        return(loc.name, loc.website, loc.issued, loc.issueLimit, loc.publishedHash, loc.expDate, loc.status, loc.securityPercentage, loc.currency, loc.createDate);
    }

    function getLOCNames() constant returns(bytes32[]) {
        return offeringCompaniesNames;
    }

    function getLOCCount() constant returns(uint) {
        return offeringCompaniesNames.length;
    }

    function()
    {
        throw;
    }
}
