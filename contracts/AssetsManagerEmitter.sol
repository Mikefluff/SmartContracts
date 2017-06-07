pragma solidity ^0.4.8;

import './MultiEventsHistoryAdapter.sol';

contract AssetsManagerEmitter is MultiEventsHistoryAdapter {

    event Error(address indexed self, bytes32 indexed error);

}