pragma solidity ^0.4.8;

import "./Managed.sol";
import "./AssetsManagerInterface.sol";
import "./ERC20Interface.sol";
import "./ERC20ManagerInterface.sol";
import "./FeeInterface.sol";
import "./ChronoBankAssetProxyInterface.sol";

contract Emitter {

    function newLOC(bytes32 locName);
    function remLOC(bytes32 locName);
    function updLOCStatus(bytes32 locName, uint _oldStatus, uint _newStatus);
    function updLOCValue(bytes32 locName);
    function reissue(uint value, bytes32 locName);
    function hashUpdate(bytes32 oldHash, bytes32 newHash);
    function emitError(bytes32 _message);
}

contract LOCManager is Managed {

    StorageInterface.Set offeringCompaniesNames;
    StorageInterface.Bytes32Bytes32Mapping website;
    StorageInterface.Bytes32Bytes32Mapping publishedHash;
    StorageInterface.Bytes32Bytes32Mapping currency;
    StorageInterface.Bytes32UIntMapping issued;
    StorageInterface.Bytes32UIntMapping issueLimit;
    StorageInterface.Bytes32UIntMapping expDate;
    StorageInterface.Bytes32UIntMapping status;
    StorageInterface.Bytes32UIntMapping createDate;

    enum Status {maintenance, active, suspended, bankrupt}

    function LOCManager(Storage _store, bytes32 _crate) EventsHistoryAndStorageAdapter(_store, _crate) {
        offeringCompaniesNames.init('offeringCompaniesNames');
        website.init('website');
        publishedHash.init('publishedHash');
        currency.init('currency');
        issued.init('issued');
        issueLimit.init('issueLimit');
        expDate.init('expDate');
        status.init('status');
        createDate.init('createDate');
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
        if (store.includes(offeringCompaniesNames, _locName)) {
            _;
        }
    }

    modifier locDoesNotExist(bytes32 _locName) {
        if (!store.includes(offeringCompaniesNames, _locName)) {
            _;
        }
    }

    function sendAsset(bytes32 _symbol, address _to, uint _value) onlyAuthorized returns (bool) {
        return AssetsManagerInterface(ContractsManagerInterface(contractsManager).getContractAddressByType(ContractsManagerInterface.ContractType.AssetsManager)).sendAsset(_symbol, _to, _value);
    }

    function reissueAsset(uint _value, bytes32 _locName) multisig returns (bool) {
        uint _issued = store.get(issued,_locName);
        if(_value <= store.get(issueLimit,_locName) - _issued) {
            if(AssetsManagerInterface(ContractsManagerInterface(contractsManager).getContractAddressByType(ContractsManagerInterface.ContractType.AssetsManager)).reissueAsset(store.get(currency,_locName), _value)) {
                store.set(issued,_locName,_issued + _value);
                eventsHistory.reissue(_value,_locName);
                return true;
            }
        }
        return false;
    }

    function revokeAsset(uint _value, bytes32 _locName) multisig returns (bool) {
        uint _issued = store.get(issued,_locName);
        if(_value <= _issued) {
            if(AssetsManagerInterface(ContractsManagerInterface(contractsManager).getContractAddressByType(ContractsManagerInterface.ContractType.AssetsManager)).revokeAsset(store.get(currency,_locName), _value)) {
                store.set(issued,_locName,_issued - _value);
                eventsHistory.reissue(_value, _locName);
                return true;
            }
        }
        return false;
    }

    function removeLOC(bytes32 _name) locExists(_name) multisig returns (bool) {

        return true;
    }

    function addLOC(bytes32 _name, bytes32 _website, uint _issueLimit, bytes32 _publishedHash, uint _expDate, bytes32 _currency) onlyAuthorized() locDoesNotExist(_name) returns(uint) {
        store.add(offeringCompaniesNames,_name);
        store.set(website,_name,_website);
        store.set(issueLimit,_name,_issueLimit);
        store.set(publishedHash,_name,_publishedHash);
        store.set(expDate,_name,_expDate);
        store.set(currency,_name,_currency);
        store.set(createDate,_name,now);
        eventsHistory.newLOC(_name);
        return store.count(offeringCompaniesNames);
    }

    function setLOC(bytes32 _name, bytes32 _newname, bytes32 _website, uint _issueLimit, bytes32 _publishedHash, uint _expDate) onlyAuthorized() locExists(_name) returns(bool) {
        if(_name == 0 || _newname == 0)
            return false;
        bool changed;
        if(!(_newname == _name)) {
            store.set(offeringCompaniesNames,_name,_newname);
            _name = _newname;
        }
        if(!(_website == store.get(website,_name))) {
            store.set(website,_name,_website);
        }
        if(!(_issueLimit == store.get(issueLimit,_name))) {
            store.set(issueLimit,_name,_issueLimit);
        }
        if(!(_publishedHash == store.get(publishedHash,_name))) {
            eventsHistory.hashUpdate(store.get(publishedHash,_name),_publishedHash);

            store.set(publishedHash,_name,_publishedHash);
        }
        if(!(_expDate == store.get(expDate,_name))) {
            store.set(expDate,_name,_expDate);
        }
        eventsHistory.updLOCValue(_name);
        return true;
    }

    function setStatus(bytes32 _name, Status _status) locExists(_name) multisig {
        if(!(store.get(status,_name) == uint(_status))) {
            eventsHistory.updLOCStatus(_name, store.get(status,_name), uint(_status));
            store.set(status,_name,uint(_status));
        } else {

        }
    }

    function getLOCByName(bytes32 _name) constant returns(bytes32 _website,
    uint _issued,
    uint _issueLimit,
    bytes32 _publishedHash,
    uint _expDate,
    uint _status,
    uint _securityPercentage,
    bytes32 _currency,
    uint _createDate) {
        _website = store.get(website,_name);
        _issued = store.get(issued,_name);
        _issueLimit = store.get(issueLimit,_name);
        _publishedHash = store.get(publishedHash,_name);
        _expDate = store.get(expDate,_name);
        _status = store.get(status,_name);
        _currency = store.get(currency,_name);
        _createDate = store.get(createDate,_name);
        return (_website, _issued, _issueLimit, _publishedHash, _expDate, _status, 10, _currency, _createDate);
    }

    function getLOCById(uint _id) constant returns(bytes32 website,
    uint issued,
    uint issueLimit,
    bytes32 publishedHash,
    uint expDate,
    uint status,
    uint securityPercentage,
    bytes32 currency,
    uint creatrDate) {
        bytes32 _name = store.get(offeringCompaniesNames,_id);
        return getLOCByName(_name);
    }

   // function getLOCNames() constant returns(bytes32[]) {
   //     return offeringCompaniesNames;
   // }

    function getLOCCount() constant returns(uint) {
        return store.count(offeringCompaniesNames);
    }

    function()
    {
        throw;
    }
}
