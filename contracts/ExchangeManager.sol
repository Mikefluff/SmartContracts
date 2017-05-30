pragma solidity ^0.4.11;

import "./Managed.sol";
import "./Exchange.sol";
//import "./KrakenPriceTicker.sol";
import {ERC20ManagerInterface as ERC20Manager} from "./ERC20ManagerInterface.sol";
import {ERC20Interface as Asset} from "./ERC20Interface.sol";
import {ContractsManagerInterface as ContractsManager} from "./ContractsManagerInterface.sol";

contract ExchangeManager is Managed {
    address contractsManager;
    address[] public exchanges;
    mapping(address => address[]) owners;

    //Exchanges APIs for rate tracking array
    //string[] public URLs;
    //mapping(bytes32 => bool) URLexsist;

    event Test(address test);

    event exchangeRemoved(address user, address exchange);

    modifier onlyExchangeOwner(address _exchange) {
        for(uint i=0;i<owners[_exchange].length;i++) {
            if (owners[_exchange][i] == msg.sender) {
                _;
            }
        }
    }

    function init(address _contractsManager) returns(bool) {
        if(contractsManager != 0x0)
        return false;
        if(!ContractsManagerInterface(_contractsManager).addContract(this,ContractsManagerInterface.ContractType.ExchangeManager,'Exchange Manager',0x0,0x0))
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
        if(owners[_exchange].length == 0) {
            exchanges.push(_exchange);
            owners[_exchange].push(msg.sender);
            return exchanges.length;
        }
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
        Test(_erc20Manager);
        address tokenAddr = ERC20Manager(_erc20Manager).getTokenAddressBySymbol(_symbol);
        Test(tokenAddr);
        address rewards = ContractsManager(contractsManager).getContractAddressByType(ContractsManager.ContractType.Rewards);
        Test(rewards);
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

    function deleteExchangeOwner(address _exchange, address _owner) onlyExchangeOwner(_exchange) returns(bool) {
        for(uint i=0;i<owners[_exchange].length;i++) {
            if(owners[_exchange][i] == msg.sender) {
                return false;
            }
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
}
