pragma solidity ^0.4.8;

import './Owned.sol';
import './EventsHistoryAndStorageAdapter.sol';

contract RolesLibrary is EventsHistoryAndStorageAdapter, Owned {
    StorageInterface.Set roles;

    event RoleAdded(bytes32 indexed role, uint version);
    event RoleRemoved(bytes32 indexed role, uint version);

    function RolesLibrary(Storage _store, bytes32 _crate) EventsHistoryAndStorageAdapter(_store, _crate) {
        roles.init('roles');
    }

    function setupEventsHistory(address _eventsHistory) onlyContractOwner() returns(bool) {
        if (getEventsHistory() != 0x0) {
            return false;
        }
        _setEventsHistory(_eventsHistory);
        return true;
    }

    function count() constant returns(uint) {
        return store.count(roles);
    }

    function includes(bytes32 _role) constant returns(bool) {
        return store.includes(roles, _role);
    }

    function getRoles() constant returns(bytes32[]) {
        return store.get(roles);
    }

    function getRole(uint _index) constant returns(bytes32) {
        return store.get(roles, _index);
    }

    function addRole(bytes32 _role) onlyContractOwner() returns(bool) {
        store.add(roles, _role);
        _emitRoleAdded(_role);
        return true;
    }

    function removeRole(bytes32 _role) onlyContractOwner() returns(bool) {
        store.remove(roles, _role);
        _emitRoleRemoved(_role);
        return true;
    }

    function _emitRoleAdded(bytes32 _role) internal {
        RolesLibrary(getEventsHistory()).emitRoleAdded(_role);
    }

    function _emitRoleRemoved(bytes32 _role) internal {
        RolesLibrary(getEventsHistory()).emitRoleRemoved(_role);
    }

    function emitRoleAdded(bytes32 _role) {
        RoleAdded(_role, _getVersion());
    }

    function emitRoleRemoved(bytes32 _role) {
        RoleRemoved(_role, _getVersion());
    }
}
