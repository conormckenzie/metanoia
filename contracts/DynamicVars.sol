//SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

// vvv STAGING vvv

contract dynamicUniqueVarSet {
    uint _nextID = 0;
    mapping (uint => string) _stringVarID; //makes the _stringVars enumerable by assigning them a numeric ID, 0-indexed
    mapping (string => string) _stringVars; //maps "name" to "value"
    mapping (string => string) _stringVarsInv; //maps "value" to "name"

    function declareStringVar(string memory name) public {
        _stringVarID[_nextID++] = name;
    }

    function setStringVarValue(string memory name, string memory value) public {
        //require that all existing varIDs do not have a shared value with any other stringVar (NEED TO IMPLEMENT)
        _stringVars[name] = value;
        _stringVarsInv[value] = name;
    }
}

// ^^^ STAGING ^^^