pragma solidity ^0.4.8;

import "./Managed.sol";
import "./TimeHolder.sol";

contract Vote is Managed {

    //defines the poll
    struct Poll {
    address owner;
    bytes32 title;
    bytes32 description;
    uint votelimit;
    uint optionsCount;
    uint deadline;
    bool status;
    uint ipfsHashesCount;
    bool active;
    mapping(address => uint) memberOption;
    mapping(uint => bytes32) ipfsHashes;
    mapping(uint => uint) options;
    mapping(uint => bytes32) optionsId;
    }

    //percent of Shares for max votelimit, where 5 is 0.05
    uint sharesPercent = 5;

    // Polls ids member took part
    mapping(address => uint[]) memberPolls;

    // event tracking new Polls
    event New_Poll(uint _pollId);

    // event tracking of all votes
    event NewVote(uint _choice, uint _pollId);

    // Something went wrong.
    event Error(bytes32 message);

    // declare an polls mapping called polls
    mapping(uint => Poll) public polls;
    // Polls counter for mapping
    uint public pollsCount;

    uint public activePollsCount;

    function Vote(Storage _store, bytes32 _crate) EventsHistoryAndStorageAdapter(_store, _crate) {

    }

    function init(address _contractsManager) returns(bool) {
        if(contractsManager != 0x0)
        return false;
        if(!ContractsManagerInterface(_contractsManager).addContract(this,ContractsManagerInterface.ContractType.Voting))
        return false;
        contractsManager = _contractsManager;
        return true;
    }

    //initiator function that stores the necessary poll information
    function NewPoll(bytes32[16] _options, bytes32 _title, bytes32 _description, uint _votelimit, uint _count, uint _deadline) returns (uint) {
        if(_votelimit > getVoteLimit()) {
            Error(bytes32("Vote limit exceeded"));
            throw;
        }
        uint id = pollsCount++;
        polls[id] = Poll(msg.sender,_title,_description,_votelimit,0,_deadline,true,0,false);
        for(uint i = 1; i < _count+1; i++) {
            polls[id].options[i] = 0;
            polls[id].optionsId[i] = _options[i-1];
            polls[id].optionsCount++;
        }
        New_Poll(id);
        return id;
    }

    function getVoteLimit() constant returns (uint) {
        address timeHolder = ContractsManagerInterface(contractsManager).getContractAddressByType(ContractsManagerInterface.ContractType.TimeHolder);
        return TimeHolder(timeHolder).totalSupply() / 10000 * sharesPercent;
    }

    function getPollTitles() constant returns (bytes32[] result) {
        result = new bytes32[](pollsCount);
        for(uint i = 0; i<pollsCount; i++)
        {
            result[i] = polls[i].title;
        }
        return (result);
    }

    function getActivePolls() constant returns (uint result) {
        Poll memory p;
        for(uint i = 0; i < pollsCount; i++) {
            p = polls[i];
            if(p.active)
                result++;
        }
        return result;
    }

    function checkPollIsActive(uint _pollId) constant returns (bool) {
        Poll memory p = polls[_pollId];
        if(p.active)
            return true;
        return false;
    }

    function getInactivePolls() constant returns (uint result) {
        Poll memory p;
        for(uint i = 0; i < pollsCount; i++) {
            p = polls[i];
            if(!p.active && p.status)
                result++;
        }
        return result;
    }

    function getMemberPolls() constant returns (uint[]) {
        return (memberPolls[msg.sender]);
    }

    function getMemberVotesForPoll(uint _id) constant returns (uint result) {
        Poll p = polls[_id];
        result = p.memberOption[msg.sender];
        return (result);
    }

    function getOptionsForPoll(uint _id) constant returns (bytes32[] result) {
        Poll p = polls[_id];
        result = new bytes32[](p.optionsCount);
        for(uint i = 0; i < p.optionsCount; i++)
        {
            result[i] = p.optionsId[i+1];
        }
        return result;
    }

    function getOptionsVotesForPoll(uint _id) constant returns (uint[] result) {
        Poll p = polls[_id];
        result = new uint[](p.optionsCount);
        for(uint i = 0; i < p.optionsCount; i++)
        {
            result[i] = p.options[i+1];
        }
        return result;
    }

    modifier onlyCreator(uint _id) {
        Poll p = polls[_id];
        if(p.owner == msg.sender)
        {
            _;
        }
    }

    function addIpfsHashToPoll(uint _id, bytes32 _hash) onlyCreator(_id) returns(bool) {
        Poll p = polls[_id];
        if(p.ipfsHashesCount < 5) {
            p.ipfsHashes[p.ipfsHashesCount++] = _hash;
            return true;
        }
        return false;
    }

    function getIpfsHashesFromPoll(uint _id) constant returns (bytes32[] result) {
        Poll p = polls[_id];
        result = new bytes32[](p.ipfsHashesCount);
        for(uint i = 0; i < p.ipfsHashesCount; i++)
        {
            result[i] = p.ipfsHashes[i];
        }
        return result;
    }

    //function for user vote. input is a string choice
    function vote(uint _pollId, uint _choice) returns (bool) {
        Poll p = polls[_pollId];
        address timeHolder = ContractsManagerInterface(contractsManager).getContractAddressByType(ContractsManagerInterface.ContractType.TimeHolder);
        if (_choice == 0 || p.status != true || p.active == false || TimeHolder(timeHolder).shares(msg.sender) == 0 || p.memberOption[msg.sender] != 0) {
            return false;
        }
        p.options[_choice] += TimeHolder(timeHolder).shares(msg.sender);
        p.memberOption[msg.sender] = _choice;
        memberPolls[msg.sender].push(_pollId);
        NewVote(_choice, _pollId);
        // if votelimit reached, end poll
        if (p.votelimit > 0 || p.deadline <= now) {
            if (p.options[_choice] >= p.votelimit) {
                endPoll(_pollId);
            }
        }
        return true;
    }

    function setVotesPercent(uint _percent) multisig returns(bool) {
        if(_percent > 0 && _percent < 100) {
            sharesPercent = _percent;
        }
    }

    function removePoll(uint _pollId) onlyAuthorized returns(bool) {
        Poll memory p = polls[_pollId];
        if(!p.active && p.status) {
            deletePoll(_pollId);
            return true;
        }
        return false;
    }

    function cleanInactivePolls() onlyAuthorized returns(bool) {
        Poll memory p;
        for(uint i = 0; i < pollsCount; i++) {
            p = polls[i];
            if(!p.active && p.status)
                deletePoll(i);
        }
        return true;
    }

    function deletePoll(uint _pollId) internal returns(bool) {
        if(_pollId >= pollsCount)
            return false;
        if(_pollId == pollsCount - 1)
            pollsCount--;
        else {
            polls[_pollId] = polls[pollsCount-1];
            pollsCount--;
        }
        return true;
    }

    //when time or vote limit is reached, set the poll status to false
    function endPoll(uint _pollId) internal returns (bool) {
        Poll p = polls[_pollId];
        p.status = false;
        p.active = false;
        activePollsCount--;
        return true;
    }

    function activatePoll(uint _pollId) multisig returns (bool) {
        if(activePollsCount <= 20) {
            Poll p = polls[_pollId];
            if(p.status) {
                p.active = true;
                activePollsCount++;
                return true;
            }
        }
        return false;
    }

    function adminEndPoll(uint _pollId) multisig returns (bool) {
        return endPoll(_pollId);
    }

    //TimeHolder interface implementation
    modifier onlyTimeHolder() {
        address timeHolder = ContractsManagerInterface(contractsManager).getContractAddressByType(ContractsManagerInterface.ContractType.TimeHolder);
        if (msg.sender == timeHolder) {
            _;
        }
    }

    function deposit(address _address, uint _amount, uint _total) onlyTimeHolder returns(bool) {
        for(uint i=0;i<memberPolls[_address].length;i++){
            Poll p = polls[memberPolls[_address][i]];
            if(p.status && p.active) {
                uint choice = p.memberOption[_address];
                p.options[choice] += _amount;
            }
            if (p.votelimit > 0 || p.deadline <= now) {
                if (p.options[choice] >= p.votelimit) {
                    p.status = false;
                    p.active = false;
                    activePollsCount--;
                }
            }
        }
        return true;
    }

    function withdrawn(address _address, uint _amount, uint _total) onlyTimeHolder returns(bool) {
        for(uint i=0;i<memberPolls[_address].length;i++){
            Poll p = polls[memberPolls[_address][i]];
            if(p.status && p.active) {
                uint choice = p.memberOption[_address];
                p.options[choice] -= _amount;
                if(_total == 0) {
                    if(i == memberPolls[_address].length - 1) {
                        memberPolls[_address].length--;
                    }
                    else {
                        memberPolls[_address][i] = memberPolls[_address][memberPolls[_address].length - 1];
                        memberPolls[_address].length--;
                    }
                    delete p.memberOption[_address];
                }
            }
        }
        return true;
    }

    function()
    {
        throw;
    }
}
