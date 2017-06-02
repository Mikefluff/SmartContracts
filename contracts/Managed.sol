pragma solidity ^0.4.8;

import {PendingManagerInterface as Shareable} from "./PendingManagerInterface.sol";
import "./UserManagerInterface.sol";
import "./ContractsManagerInterface.sol";
import './EventsHistoryAndStorageAdapter.sol';

contract Managed is EventsHistoryAndStorageAdapter {

    address public contractsManager;

    modifier onlyAuthorized() {
        if (isAuthorized(msg.sender)) {
            _;
        }
    }

    modifier multisig() {
        address shareable = ContractsManagerInterface(contractsManager).getContractAddressByType(ContractsManagerInterface.ContractType.PendingManager);
        if (msg.sender != shareable) {
            bytes32 _r = sha3(msg.data);
            Shareable(shareable).addTx(_r, msg.data, this, msg.sender);
        }
        else {
            _;
        }
    }

    function isAuthorized(address key) returns (bool) {
        address userManager = ContractsManagerInterface(contractsManager).getContractAddressByType(ContractsManagerInterface.ContractType.UserManager);
        return UserManagerInterface(userManager).getCBE(key);
    }

}
