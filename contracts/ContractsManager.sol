pragma solidity ^0.4.11;

import "./Managed.sol";
import "./ExchangeInterface.sol";
import "./OwnedInterface.sol";

contract ContractsManager is Managed {

    StorageInterface.AddressesSet contractsAddresses;
    StorageInterface.UIntAddressMapping contractsTypes;

    enum ContractType {LOCManager, PendingManager, UserManager, ERC20Manager, ExchangeManager, TrackersManager, Voting, Rewards, AssetsManager, TimeHolder, CrowdsaleManager}

    event LogAddContract(
    address contractAddr,
    ContractType tp
    );

    struct ContractMetadata {
    address contractAddr;
    ContractType tp;
    }

    event LogContractAddressChange(address oldAddr, address newAddr);

    modifier contractExists(address _contract) {
        if (store.includes(contractsAddresses, _contract)) {
            _;
        }
    }

    modifier contractDoesNotExist(address _contract) {
        if (!store.includes(contractsAddresses, _contract)) {
            _;
        }
    }

    function ContractsManager(Storage _store, bytes32 _crate) EventsHistoryAndStorageAdapter(_store, _crate) {
        contractsAddresses.init('contracts');
        contractsTypes.init('contractTypes');
        contractsManager = this;
    }

    /// @dev Returns an array containing all contracts addresses.
    /// @return Array of token addresses.
    function getContractAddresses() constant returns (address[]) {
        return store.get(contractsAddresses);
    }

//    function forward(ContractType _type, bytes data) onlyAuthorized() returns (bool) {
//        if (!contractByType[uint(_type)].call(data)) {
//            throw;
//        }
//        return true;
//    }

    function getContractAddressByType(ContractType _type) constant returns (address contractAddress) {
        return store.get(contractsTypes,uint(_type));
    }

    /// @dev Allow owner to add new contract
    function addContract(
    address _contractAddr,
    ContractType _type)
    contractDoesNotExist(_contractAddr)
    returns(bool)
    {
        store.add(contractsAddresses,_contractAddr);
        store.set(contractsTypes,uint(_type),_contractAddr);
        LogAddContract(
        _contractAddr,
        _type
        );
        return true;
    }

    /// @dev Allows owner to modify an existing contract's address.
    /// @param _contractAddr Address of contract.
    /// @param _newAddr New address of contract.
    function setContractAddress(address _contractAddr, address _newAddr, ContractType _type)
    public
    onlyAuthorized()
    contractExists(_contractAddr)
    {
        store.set(contractsTypes,uint(_type),_newAddr);
        store.set(contractsAddresses,_contractAddr,_newAddr);
        LogContractAddressChange(_contractAddr, _newAddr);
    }

    function()
    {
        throw;
    }
}
