pragma solidity 0.4.23;

contract Ownable {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }
}
