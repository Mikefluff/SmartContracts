pragma solidity ^0.4.8;

import "./EternalStorage.sol";

library SharedLibrary {
    function getCount(address db, string countKey) internal returns(uint count) {
        count = EternalStorage(db).getUIntValue(sha3(countKey));
    }

    function createNext(address db, string countKey) internal returns(uint result) {
        result = EternalStorage(db).addUIntValue(sha3(countKey), 1);
    }

    function increment(address db, string countKey) internal returns(uint result) {
        result = EternalStorage(db).addUIntValue(sha3(countKey), 1);        
    }

    function decrement(address db, string countKey) internal returns(uint result) {
        result = EternalStorage(db).subUIntValue(sha3(countKey), 1);        
    }

    function containsValue(address db, uint id, string key, uint8[] array) internal returns(bool) {
        if (array.length == 0) {
            return true;
        }
        var val = EternalStorage(db).getUInt8Value(sha3(key, id));
        for (uint i = 0; i < array.length ; i++) {
            if (array[i] == val) {
                return true;
            }
        }
        return false;
    }

    function getArrayItemsCount(address db, uint id, string countKey) internal constant returns (uint) {
        return EternalStorage(db).getUIntValue(sha3(countKey, id));
    }

    function getItemIndex(address db, uint id, string key, string countKey, uint item) internal constant returns (uint) {
        var items = getUIntArray(db, id, key, countKey);
        for (uint i = 0; i < items.length ; i++) {
            if (items[i] == item) {
                return i;
            }
        }
        return uint(-1);        
    }

    function getItem(address db, uint id, string key, uint idx) internal constant returns (uint) {
        return EternalStorage(db).getUIntValue(sha3(key, id, idx));        
    }
    
    function addItem(address db, uint id, string key, string countKey, uint item) internal {
        var idx = getArrayItemsCount(db, id, countKey);
        EternalStorage(db).setUIntValue(sha3(key, id, idx), item);
        EternalStorage(db).setUIntValue(sha3(countKey, id), idx + 1);
    }

    // TODO: AG
    function removeItem(address db, uint id, string key, string countKey, uint item) internal {
        var idx = getItemIndex(db, id, key, countKey, item);
        EternalStorage(db).deleteUIntValue(sha3(key, id, idx));
        EternalStorage(db).subUIntValue(sha3(countKey, id), 1);
    }

    function setUIntArray(address db, uint id, string key, string countKey, uint[] array) internal{
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == 0) throw;
            EternalStorage(db).setUIntValue(sha3(key, id, i), array[i]);
        }
        EternalStorage(db).setUIntValue(sha3(countKey, id), array.length);
    }
    
    function getUIntArray(address db, uint id, string key, string countKey) internal constant returns(uint[] result) {
        uint count = getArrayItemsCount(db, id, countKey);
        result = new uint[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = EternalStorage(db).getUIntValue(sha3(key, id, i));
        }
        return result;
    }

    function addRemovableArrayItem(address db, uint[] ids, string key, string countKey, string keysKey, uint val) internal {
        if (ids.length == 0) {
            return;
        }
        for (uint i = 0; i < ids.length; i++) {
            if (EternalStorage(db).getUInt8Value(sha3(key, ids[i], val)) == 0) { // never seen before
                addItem(db, ids[i], keysKey, countKey, val);
            }
            EternalStorage(db).setUInt8Value(sha3(key, ids[i], val), 1); // 1 == active
        }
    }

    function removeArrayItem(address db, uint[] ids, string key, uint val) internal {
        if (ids.length == 0) {
            return;
        }
        for (uint i = 0; i < ids.length; i++) {
            EternalStorage(db).setUInt8Value(sha3(key, ids[i], val), 2); // 2 == blocked
        }
    }

    function sort(uint[] array) internal returns(uint[]) {
        uint n = array.length;
        if (array.length == 0) {
            return array;
        }

        for (uint c = 0 ; c < ( n - 1 ); c++) {
            for (uint d = 0 ; d < n - c - 1; d++) {
                if (array[d] >= array[d + 1]) {
                    (array[d], array[d + 1]) = (array[d + 1], array[d]);
                }
            }
        }
        return array;
    }
}
