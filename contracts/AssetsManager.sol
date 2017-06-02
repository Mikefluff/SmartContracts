pragma solidity ^0.4.11;

import "./Managed.sol";
import {ERC20ManagerInterface as ERC20Manager} from "./ERC20ManagerInterface.sol";
import "./ChronoBankPlatformInterface.sol";
import "./ChronoBankAssetInterface.sol";
import "./ChronoBankAssetProxyInterface.sol";
import "./ERC20Interface.sol";
import "./OwnedInterface.sol";

contract ChronoBankAsset {
    function init(ChronoBankAssetProxyInterface _proxy) returns(bool);
}

contract ProxyFactory {
    function createProxy() returns (address);
    function createAsset() returns (address);
    function createAssetWithFee() returns (address);
}

contract CrowdsaleManager {
function createCompain(address _fund,
bytes32 _symbol,
string  _reference,
uint256 _startBlock,
uint256 _stopBlock,
uint256 _minValue,
uint256 _maxValue,
uint256 _scale,
uint256 _startRatio,
uint256 _reductionStep,
uint256 _reductionValue) returns(address);
}

contract AssetsManager is Managed {

    address platform;
    address contractsManager;
    address proxyFactory;

    bytes32[] public assetSymbols;
    mapping(bytes32 => address) assets;
    mapping(address => address[]) owners;

    mapping (address => bool) timeHolder;

    modifier onlyAssetOwner(bytes32 _symbol) {
        if(isAssetOwner(_symbol, msg.sender))
        {
            _;
        }
    }

    function isAssetOwner(bytes32 _symbol, address _owner) returns (bool) {
        for(uint i=0;i<owners[assets[_symbol]].length;i++) {
            if (owners[assets[_symbol]][i] == _owner)
            return true;
        }
        return false;
    }

    function AssetsManager(Storage _store, bytes32 _crate) EventsHistoryAndStorageAdapter(_store, _crate) {

    }

    function init(address _platform, address _contractsManager, address _proxyFactory) returns(bool) {
        if (platform != 0x0) {
            return false;
        }
        if(contractsManager != 0x0)
        return false;
        if(!ContractsManagerInterface(_contractsManager).addContract(this,ContractsManagerInterface.ContractType.AssetsManager))
        return false;
        contractsManager = _contractsManager;
        platform = _platform;
        contractsManager = _contractsManager;
        proxyFactory = _proxyFactory;
        return true;
    }

    // this method is implemented only for test purposes
    function sendTime() returns (bool) {
        if(!timeHolder[msg.sender] && assets[bytes32('TIME')] != address(0)) {
            timeHolder[msg.sender] = true;
            return ERC20Interface(assets[bytes32('TIME')]).transfer(msg.sender, 1000000000);
        }
        else {
            return false;
        }
    }

    function claimPlatformOwnership() returns (bool) {
        if (OwnedInterface(platform).claimContractOwnership()) {
            return true;
        }
        platform = address(0);
        return false;
    }

    function getAssetBalance(bytes32 symbol) constant returns (uint) {
        return ERC20Interface(assets[symbol]).balanceOf(this);
    }

    function getAssets() constant returns(bytes32[]) {
        return assetSymbols;
    }

    function sendAsset(bytes32 _symbol, address _to, uint _value) onlyAssetOwner(_symbol) returns (bool) {
        return ERC20Interface(assets[_symbol]).transfer(_to, _value);
    }

    function reissueAsset(bytes32 _symbol, uint _value) onlyAssetOwner(_symbol) returns(bool) {
        return ChronoBankPlatformInterface(platform).reissueAsset(_symbol, _value);
    }

    function revokeAsset(bytes32 _symbol, uint _value) onlyAssetOwner(_symbol) returns(bool) {
        return ChronoBankPlatformInterface(platform).revokeAsset(_symbol, _value);
    }

    function addAsset(address asset, bytes32 _symbol, address owner) returns (bool) {
        if(ChronoBankAssetProxyInterface(asset).chronoBankPlatform() == platform) {
            if(ChronoBankPlatformInterface(platform).proxies(_symbol) == asset) {
                if(ChronoBankPlatformInterface(platform).isOwner(this,_symbol)) {
                    uint8 decimals = ChronoBankPlatformInterface(platform).baseUnit(_symbol);
                    address erc20Manager = ContractsManagerInterface(contractsManager).getContractAddressByType(ContractsManagerInterface.ContractType.ERC20Manager);
                    if(!ERC20Manager(erc20Manager).addToken(asset,'',bytes32ToString(_symbol),'',decimals,bytes32(0), bytes32(0))) {

                    }
                    assets[_symbol] = asset;
                    assetSymbols.push(_symbol);
                    owners[asset].push(owner);
                    return true;
                }
            }
        }
        return false;
    }

    function createAsset(bytes32 symbol, string name, string description, uint value, uint8 decimals, bool isMint, bool withFee) returns (address) {
        string memory smbl = bytes32ToString(symbol);
        address erc20Manager = ContractsManagerInterface(contractsManager).getContractAddressByType(ContractsManagerInterface.ContractType.ERC20Manager);
        address token = ERC20Manager(erc20Manager).getTokenAddressBySymbol(smbl);
        if(token == address(0)) {
            token = ProxyFactory(proxyFactory).createProxy();
            address asset;
            ChronoBankPlatformInterface(platform).issueAsset(symbol, value, name, description, decimals, isMint);
            if(withFee) {
                asset = ProxyFactory(proxyFactory).createAssetWithFee();
            }
            else {
                asset = ProxyFactory(proxyFactory).createAsset();
            }
            ChronoBankPlatformInterface(platform).setProxy(token, symbol);
            ChronoBankAssetProxyInterface(token).init(platform, smbl, name);
            ChronoBankAssetProxyInterface(token).proposeUpgrade(asset);
            ChronoBankAsset(asset).init(ChronoBankAssetProxyInterface(token));
            if(!ERC20Manager(erc20Manager).addToken(token, name, smbl, '', decimals, bytes32(0), bytes32(0))) {

            }
            assets[symbol] = token;
            assetSymbols.push(symbol);
            owners[token].push(msg.sender);
            return token;
        }
        return 0;
    }

    function startCompain() {

    }

    function addAssetOwner(bytes32 _symbol, address _owner) onlyAssetOwner(_symbol) returns(bool) {
        for(uint i=0;i<owners[assets[_symbol]].length;i++) {
            if(owners[assets[_symbol]][i] == _owner) {
                return false;
            }
        }
        owners[assets[_symbol]].push(_owner);
        return true;
    }

    function deleteAssetOwner(bytes32 _symbol, address _owner) onlyAssetOwner(_symbol) returns(bool) {
        for(uint i=0;i<owners[assets[_symbol]].length;i++) {
            if(owners[assets[_symbol]][i] == msg.sender) {
                return false;
            }
            if(owners[assets[_symbol]][i] == _owner) {
                owners[assets[_symbol]][i] = owners[assets[_symbol]][owners[assets[_symbol]].length-1];
                owners[assets[_symbol]].length--;
                return true;
            }
        }
        return false;
    }

    function getAssetOwners(bytes32 _symbol) constant returns (address[]) {
        return owners[assets[_symbol]];
    }

    function getAssetsForOwner(address owner) constant returns (bytes32[]) {
        uint counter;
        uint i;
        for(i=0;i<assetSymbols.length;i++) {
            if(isAssetOwner(assetSymbols[i],owner))
            counter++;
        }
        bytes32[] memory result = new bytes32[](counter);
        counter = 0;
        for(i=0;i<assetSymbols.length;i++) {
            if(isAssetOwner(assetSymbols[i],owner)) {
                result[counter] = assetSymbols[i];
                counter++;
            }
        }
        return result;
    }

    function bytes32ToString(bytes32 x) constant returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function()
    {
        throw;
    }
}
