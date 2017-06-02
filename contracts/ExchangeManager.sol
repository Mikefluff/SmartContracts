pragma solidity ^0.4.11;

import "./Managed.sol";
import "./Exchange.sol";
//import "./KrakenPriceTicker.sol";
import {ERC20ManagerInterface as ERC20Manager} from "./ERC20ManagerInterface.sol";
import {ERC20Interface as Asset} from "./ERC20Interface.sol";
import {ContractsManagerInterface as ContractsManager} from "./ContractsManagerInterface.sol";

contract Emitter {
    function emitError(bytes32 _message);
}

contract ExchangeManager is Managed {

    address[] public exchanges;
    mapping(address => address[]) owners;

    //Exchanges APIs for rate tracking array
    //string[] public URLs;
    //mapping(bytes32 => bool) URLexsist;

    event exchangeRemoved(address user, address exchange);

    modifier onlyExchangeOwner(address _exchange) {
        if (isExchangeOwner(_exchange,msg.sender)) {
            _;
        }
    }

    function isExchangeOwner(address _exchange, address _owner) returns (bool) {
        for(uint i=0;i<owners[_exchange].length;i++) {
            if (owners[_exchange][i] == _owner)
            return true;
        }
        return false;
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

    function ExchangeManager(Storage _store, bytes32 _crate) EventsHistoryAndStorageAdapter(_store, _crate) {

    }

    function init(address _contractsManager) returns(bool) {
        if(contractsManager != 0x0)
        return false;
        if(!ContractsManagerInterface(_contractsManager).addContract(this,ContractsManagerInterface.ContractType.ExchangeManager))
        return false;
        contractsManager = _contractsManager;
        return true;
    }

    function forward(address _exchange, bytes data) onlyExchangeOwner(_exchange) returns (bool) {
        if (!Exchange(_exchange).call(data)) {
            throw;
        }
        return true;
    }

    function addExchange(address _exchange) returns(uint) {
        Exchange(_exchange).buyPrice();
        Exchange(_exchange).sellPrice();
        if(owners[_exchange].length == 0) {
            exchanges.push(_exchange);
            owners[_exchange].push(msg.sender);
            return exchanges.length;
        }
        _error("Can't add exchange");
        return 0;
    }

    function editExchange(address _exchangeOld, address _exchangeNew) onlyExchangeOwner(_exchangeOld) returns(bool) {
        for (uint i = 0; i < exchanges.length; i++) {
            if (exchanges[i] == _exchangeOld) {
                exchanges[i] = _exchangeNew;
                exchanges.length -= 1;
                return true;
            }
        }
        return false;
    }

    function removeExchange(address _exchange) onlyExchangeOwner(_exchange) returns(bool) {
        for (uint i = 0; i < exchanges.length; i++) {
            if (exchanges[i] == _exchange) {
                exchanges[i] = exchanges[exchanges.length - 1];
                exchanges.length -= 1;
                break;
            }
        }
        delete owners[_exchange];
        exchangeRemoved(msg.sender, _exchange);
        return true;
    }

    function createExchange(string _symbol, bool _useTicker) returns(uint) {
        address _erc20Manager = ContractsManager(contractsManager).getContractAddressByType(ContractsManager.ContractType.ERC20Manager);
        address tokenAddr = ERC20Manager(_erc20Manager).getTokenAddressBySymbol(_symbol);
        address rewards = ContractsManager(contractsManager).getContractAddressByType(ContractsManager.ContractType.Rewards);
        if(tokenAddr != 0x0 && rewards !=  0x0) {
            address exchangeAddr = new Exchange();
            address tickerAddr;
            if(_useTicker) {
                //address tickerAddr = new KrakenPriceTicker();
            }
            Exchange(exchangeAddr).init(Asset(tokenAddr),rewards,tickerAddr,10);
            exchanges.push(exchangeAddr);
            owners[exchangeAddr].push(msg.sender);
            return exchanges.length;
        }
        _error("Can't create new exchange");
        return 0;
    }

    function addExchangeOwner(address _exchange, address _owner) onlyExchangeOwner(_exchange) returns(bool) {
        for(uint i=0;i<owners[_exchange].length;i++) {
            if(owners[_exchange][i] == _owner) {
                return false;
            }
        }
        owners[_exchange].push(_owner);
        return true;
    }

    function removeExchangeOwner(address _exchange, address _owner) onlyExchangeOwner(_exchange) returns(bool) {
        if(_owner == msg.sender) {
            return false;
        }
        for(uint i=0;i<owners[_exchange].length;i++) {
            if(owners[_exchange][i] == _owner) {
                owners[_exchange][i] = owners[_exchange][owners[_exchange].length-1];
                owners[_exchange].length--;
                return true;
            }
        }
        return false;
    }

    function getExchangeOwners(address _exchange) returns (address[]) {
        return owners[_exchange];
    }

    function getExchangesForOwner(address owner) constant returns (address[]) {
        uint counter;
        uint i;
        for(i=0;i<exchanges.length;i++) {
            if(isExchangeOwner(exchanges[i],owner))
            counter++;
        }
        address[] memory result = new address[](counter);
        counter = 0;
        for(i=0;i<exchanges.length;i++) {
            if(isExchangeOwner(exchanges[i],owner)) {
                result[counter] = exchanges[i];
                counter++;
            }
        }
        return result;
    }

}
