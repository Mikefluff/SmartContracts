pragma solidity ^0.4.8;
import './Crowdsale.sol';
import './Managed.sol';
import "./AssetsManagerInterface.sol";

/**
 * @title Crowdfunding contract
 */
contract CrowdfundingManager is Managed {

    address[] compains;

    function init(address _contractsManager) returns(bool) {
        if(contractsManager != 0x0)
        return false;
        if(!ContractsManagerInterface(_contractsManager).addContract(this,ContractsManagerInterface.ContractType.CrowdsaleManager,'Crowdsale Manager',0x0,0x0))
        return false;
        contractsManager = _contractsManager;
        return true;
    }

    function createCompain(address _creator, bytes32 _symbol) returns(address) {
        AssetsManagerInterface assetsManager = AssetsManagerInterface(ContractsManagerInterface(contractsManager).getContractAddressByType(ContractsManagerInterface.ContractType.AssetsManager));
        if(assetsManager.isAssetOwner(_symbol,_creator))
        {
            address crowdsale = new Crowdsale(contractsManager,_symbol);
            compains.push(crowdsale);
            return crowdsale;
        }
    }

}