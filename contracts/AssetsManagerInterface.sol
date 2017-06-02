pragma solidity ^0.4.8;

contract AssetsManagerInterface {
    function sendAsset(bytes32 _symbol, address _to, uint _value) returns (bool);
    function reissueAsset(bytes32 _symbol, uint _value) returns(bool);
    function revokeAsset(bytes32 _symbol, uint _value) returns(bool);
    function isAssetOwner(bytes32 _symbol, address _owner) returns (bool);

}


