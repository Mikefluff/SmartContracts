pragma solidity ^0.4.8;

import "./UserManagerInterface.sol";
import {ContractsManagerInterface as ContractsManager} from "./ContractsManagerInterface.sol";

contract PendingManager {
    // TYPES

    address contractsManager;

    bytes32[] public txHashes;
    mapping (bytes32 => Transaction) public txs;

    struct Transaction {
    address to;
    bytes32 hash;
    bytes data;
    uint yetNeeded;
    uint ownersDone;
    uint timestamp;
    }

    // EVENTS

    event Confirmation(address owner, bytes32 hash);
    event Revoke(address owner, bytes32 hash);
    event Done(bytes32 hash, bytes data, uint timestamp);
    event Error(bytes32 message);

    event Test(uint test);

    /// MODIFIERS

    // multi-sig function modifier: the operation must have an intrinsic hash in order
    // that later attempts can be realised as the same underlying operation and
    // thus count as confirmations
    modifier onlyManyOwners(bytes32 _operation, address _sender) {
        if (confirmAndCheck(_operation, _sender)) {
            _;
        }
    }

    // METHODS

    function init(address _contractsManager) returns(bool) {
        if(contractsManager != 0x0)
            return false;
        if(!ContractsManager(_contractsManager).addContract(this,ContractsManager.ContractType.PendingManager))
            return false;
        contractsManager = _contractsManager;
        return true;
    }

    function pendingsCount() constant returns (uint) {
        return txHashes.length;
    }

    function pendingYetNeeded(bytes32 _hash) constant returns (uint) {
        return txs[_hash].yetNeeded;
    }

    function getTxsData(bytes32 _hash) constant returns (bytes) {
        return txs[_hash].data;
    }

    function addTx(bytes32 _r, bytes data, address to, address sender) {
        if (txs[_r].hash != 0x0) {
            Error("duplicate");
            return;
        }
        if (isOwner(sender)) {
            txHashes.push(_r);
            address userManager = ContractsManager(contractsManager).getContractAddressByType(ContractsManager.ContractType.UserManager);
            txs[_r] = Transaction({
            hash: _r,
            data: data,
            to: to,
            yetNeeded: UserManagerInterface(userManager).required(),
            ownersDone: 0,
            timestamp: now});

            conf(_r, sender);
        }
    }

    function confirm(bytes32 _h) returns (bool) {
        return conf(_h, msg.sender);
    }

    function conf(bytes32 _h, address sender) onlyManyOwners(_h, sender) returns (bool) {
        if (txs[_h].to != 0) {
            if (!txs[_h].to.call(txs[_h].data)) {
                throw;
            }
            deleteTx(_h);
            return true;
        }
    }

    // revokes a prior confirmation of the given operation
    function revoke(bytes32 _operation) external {
        if (isOwner(msg.sender)) {
            address userManager = ContractsManager(contractsManager).getContractAddressByType(ContractsManager.ContractType.UserManager);
            uint ownerIndexBit = 2 ** UserManagerInterface(userManager).getMemberId(msg.sender);
            var pending = txs[_operation];
            if (pending.ownersDone & ownerIndexBit > 0) {
                pending.yetNeeded++;
                pending.ownersDone -= ownerIndexBit;
                Revoke(msg.sender, _operation);
                if (pending.yetNeeded == UserManagerInterface(userManager).required()) {
                    deleteTx(_operation);
                }
            }

        }
    }

    function isOwner(address _addr) constant returns (bool) {
        address userManager = ContractsManager(contractsManager).getContractAddressByType(ContractsManager.ContractType.UserManager);
        return UserManagerInterface(userManager).getCBE(_addr);
    }

    function hasConfirmed(bytes32 _operation, address _owner) constant returns (bool) {
        var pending = txs[_operation];
        if (isOwner(_owner)) {
            // determine the bit to set for this owner
            address userManager = ContractsManager(contractsManager).getContractAddressByType(ContractsManager.ContractType.UserManager);
            uint ownerIndexBit = 2 ** UserManagerInterface(userManager).getMemberId(_owner);
            return !(pending.ownersDone & ownerIndexBit == 0);
        }
    }


    // INTERNAL METHODS

    function confirmAndCheck(bytes32 _operation, address sender) internal returns (bool) {
        if (isOwner(sender)) {
            Transaction pending = txs[_operation];
            // determine the bit to set for this owner
            address userManager = ContractsManager(contractsManager).getContractAddressByType(ContractsManager.ContractType.UserManager);
            uint ownerIndexBit = 2 ** UserManagerInterface(userManager).getMemberId(sender);
            // make sure we (the message sender) haven't confirmed this operation previously
            if (pending.ownersDone & ownerIndexBit == 0) {
                // ok - check if count is enough to go ahead
                if (pending.yetNeeded <= 1) {
                    // enough confirmations: reset and run interior
                    Done(_operation, pending.data, now);
                    return true;
                } else {
                    // not enough: record that this owner in particular confirmed
                    pending.yetNeeded--;
                    pending.ownersDone |= ownerIndexBit;
                    Confirmation(msg.sender, _operation);
                    return false;
                }
            }
        }
    }

    function deleteTx(bytes32 _h) internal {
        for (uint i = 0; i < txHashes.length; i++) {
            if (txHashes[i] == _h) {
                txHashes[i] = txHashes[txHashes.length - 1];
                txHashes.length -= 1;
                break;
            }
        }
        delete txs[_h];
    }

    function()
    {
        throw;
    }
}
