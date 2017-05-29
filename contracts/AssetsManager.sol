pragma solidity ^0.4.11;

import "./Managed.sol";
import "./ERC20ManagerInterface.sol";
import "./ContractsManagerInterface.sol";
import "./ChronoBankAssetWithFee.sol";
import "./ChronoBankPlatformInterface.sol";
import "./ChronoBankAssetProxyInterface.sol";
import "./ERC20Interface.sol";
import "./OwnedInterface.sol";

contract ProxyFactory {
    function createProxy() returns (address);
}

contract AssetsManager is Managed {

    address platform;
    address contractsManager;
    address proxyFactory;

    bytes32[] public assetSymbols;
    mapping(bytes32 => address) assets;
    mapping(address => mapping(address => bool)) owners;

    mapping (address => bool) timeHolder;

    modifier onlyAssetOwner(bytes32 _symbol) {
        if (owners[assets[_symbol]][msg.sender]) {
            _;
        }
    }

    function init(address _platform, address _contractsManager, address _proxyFactory) returns(bool) {
        if (platform != 0x0) {
            return false;
        }
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

    function claimPlatformOwnership() onlyAuthorized returns (bool) {
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
        if(ChronoBankAssetProxy(asset).chronoBankPlatform() == platform) {
            if(ChronoBankPlatformInterface(platform).proxies(_symbol) == asset) {
                if(ChronoBankPlatformInterface(platform).isOwner(this,_symbol)) {
                    uint8 decimals = ChronoBankPlatformInterface(platform).baseUnit(_symbol);
                    if(!ERC20ManagerInterface(contractsManager).addToken(asset,'',bytes32ToString(_symbol),'',decimals,bytes32(0), bytes32(0))) {

                    }
                    assets[_symbol] = asset;
                    assetSymbols.push(_symbol);
                    owners[asset][owner] = true;
                    return true;
                }
            }
        }
        return false;
    }

    function createAsset(bytes32 symbol, string name, string description, uint value, uint8 decimals, bool isMint, bool withFee) returns (address) {
        string memory smbl = bytes32ToString(symbol);
        address token = ERC20ManagerInterface(contractsManager).getTokenAddressBySymbol(smbl);
        if(token == address(0)) {
            token = ProxyFactory(proxyFactory).createProxy();
            address asset;
            ChronoBankPlatformInterface(platform).issueAsset(symbol, value, name, description, decimals, isMint);
            if(withFee) {
                asset = new ChronoBankAssetWithFee();
            }
            else {
                asset = new ChronoBankAsset();
            }
            ChronoBankPlatformInterface(platform).setProxy(token, symbol);
            ChronoBankAssetProxy(token).init(platform, smbl, name);
            ChronoBankAssetProxy(token).proposeUpgrade(asset);
            ChronoBankAsset(asset).init(ChronoBankAssetProxyInterface(token));
            if(!ERC20ManagerInterface(contractsManager).addToken(token, name, smbl, '', decimals, bytes32(0), bytes32(0))) {

            }
            assets[symbol] = token;
            assetSymbols.push(symbol);
            owners[token][msg.sender] = true;
            return token;
        }
        return 0;
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
