pragma solidity 0.4.24;

contract Ownable {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }
}
