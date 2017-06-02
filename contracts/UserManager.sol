pragma solidity ^0.4.8;

import "./Managed.sol";

contract Emitter {
    function cbeUpdate(address key);
    function setRequired(uint required);
    function hashUpdate(bytes32 oldHash, bytes32 newHash);
    function emitError(bytes32 _message);
}

contract UserManager is Managed {
    StorageInterface.UInt req;
    StorageInterface.UInt ownersCount;
    StorageInterface.AddressesSet members;
    StorageInterface.AddressUIntMapping owners;
    StorageInterface.AddressBytes32Mapping hashes;

    function UserManager(Storage _store, bytes32 _crate) EventsHistoryAndStorageAdapter(_store, _crate) {
        req.init('req');
        ownersCount.init('ownersCount');
        members.init('members');
        owners.init('owners');
        hashes.init('hashes');
    }

    function init(address _contractsManager) returns (bool) {
        //UserStorage(userStorage).addMember(msg.sender, true);
        if(contractsManager != 0x0)
        return false;
        if(!ContractsManagerInterface(_contractsManager).addContract(this,ContractsManagerInterface.ContractType.UserManager))
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
    function setupEventsHistory(address _eventsHistory) onlyAuthorized returns(bool) {
        if (address(eventsHistory) != 0) {
            return false;
        }
        eventsHistory = Emitter(_eventsHistory);
        return true;
    }

    function addCBE(address _key, bytes32 _hash) multisig {
        if (!getCBE(_key)) { // Make sure that the key being submitted isn't already CBE
            if (addMember(_key, true) || setCBE(_key, true)) {
                setMemberHash(_key, _hash);
                eventsHistory.cbeUpdate(_key);
            }
        } else {
            _error("This address is already CBE");
        }
    }

    function revokeCBE(address _key) multisig {
        if (getCBE(_key)) { // Make sure that the key being revoked is exist and is CBE
            setCBE(_key, false);
            eventsHistory.cbeUpdate(_key);
        }
        else {
            _error("This address in not CBE");
        }
    }

    function createMemberIfNotExist(address key) internal returns (bool) {
        return addMember(key, false);
    }

    function setMemberHash(address key, bytes32 _hash) onlyAuthorized returns (bool) {
        return setMemberHashInt(key, _hash);
    }

    function setMemberHashInt(address key, bytes32 _hash) internal returns (bool) {
        createMemberIfNotExist(key);
        bytes32 oldHash = getMemberHash(key);
        if(!(_hash == oldHash)) {
            eventsHistory.hashUpdate(oldHash, _hash);
            setHashes(key, _hash);
            return true;
        }
        _error("Same hash set");
        return false;
    }

    function setOwnHash(bytes32 _hash) returns (bool) {
        return setMemberHashInt(msg.sender, _hash);
    }

    function setRequired(uint _required) multisig returns (bool) {
            store.set(req,_required);
            eventsHistory.setRequired(_required);
            return true;

        //_error("Required to high");
        //return false;
    }

    function addMember(address key, bool isCBE) returns(bool){

    }

    function setCBE(address key, bool isCBE) returns(bool) {

    }

    function setHashes(address key, bytes32 hash) {

    }

    function setExchange(address _member, address _exchange) returns (bool) {

    }

    function setAsset(address _member, address _asset) returns (bool) {

    }

    function getMemberHash(address key) constant returns (bytes32) {
        return store.get(hashes,key);
    }

    function getCBE(address key) constant returns (bool) {
        return store.get(owners,key) != 0;
    }

    function getMemberId(address sender) constant returns (uint) {
        return store.getIndex(members,sender);
    }

    function required() constant returns (uint) {
        return store.get(req);
    }

    function adminCount() constant returns (uint) {
        return store.get(ownersCount);
    }

    function userCount() constant returns (uint) {
        return store.count(members);
    }

   // function getCBEMembers() constant returns (address[] addresses, bytes32[] hashes) {
   //     addresses = new address[](adminCount());
   //     hashes = new bytes32[](adminCount());
   //     uint j = 0;
   //     address memberAddr;
   //     bytes32 hash;
   //     bool isCBE;
   //     for (uint i = 1; i < userCount(); i++) {
   //         (memberAddr,hash,isCBE) = UserStorage(userStorage).members(i);
   //         if (isCBE) {
   //             addresses[j] = memberAddr;
   //             hashes[j] = hash;
   //             j++;
   //         }
   //     }
   //     return (addresses, hashes);
   // }

    function()
    {
        throw;
    }
}
