pragma solidity ^0.4.8;

contract ChronoBankAssetProxyInterface {
    address public chronoBankPlatform;
    bytes32 public smbl;
    function __transferWithReference(address _to, uint _value, string _reference, address _sender) returns(bool);
    function __transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) returns(bool);
    function __approve(address _spender, uint _value, address _sender) returns(bool);    
    function getLatestVersion() returns(address);
}
