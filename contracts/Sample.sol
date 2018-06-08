pragma solidity 0.4.24;

contract Sample {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }
}
