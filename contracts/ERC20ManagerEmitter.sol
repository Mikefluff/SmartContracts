pragma solidity ^0.4.8;

import './MultiEventsHistoryAdapter.sol';

contract ERC20ManagerEmitter is MultiEventsHistoryAdapter {

    event Error(address indexed self, bytes32 indexed error);

    function emitError(bytes32 _message) {
        Error(_self(),_message);
    }

}