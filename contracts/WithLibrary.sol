pragma solidity 0.4.24;

import "./lib/Library.sol";

contract WithLibrary {
    address public owner;
    address public worker;
    address[] public children;
    uint256 public childId;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
        worker = msg.sender;
        children.length = 1;
    }

    function() external {
        revert();
    }

    function newChild()
        external
        onlyOwner
    {
        WithLibraryChild child = new WithLibraryChild();
        children.push(child);
        childId++;
    }
}

contract WithLibraryChild {
    WithLibrary public factory;
    Library.DataUint public varUint;
    Library.DataBytes public varBytes;
    Library.Lender[] public lenders;
    Library.LoanStatus[1] public status;

    modifier onlyWorker() {
        require(msg.sender == factory.worker());
        _;
    }

    constructor()
        public
    {
        factory = WithLibrary(msg.sender);
    }

    function() external {
        revert();
    }

    function store10Uint(uint256[10] input)
        external
        onlyWorker
    {
        Library.store10Uint(varUint, input);
    }

    function store10Bytes(bytes32[10] input)
        external
        onlyWorker
    {
        Library.store10Bytes(varBytes, input);
    }

    function store10Struct(uint256[40] inputUint, bytes32[30] inputBytes)
        external
        onlyWorker
    {
        Library.store10Struct(lenders, inputUint, inputBytes);
    }

    function change10Enum()
        external
        onlyWorker
    {
        Library.change10Enum(status);
    }

    function emitEvents()
        external
        onlyWorker
    {
        Library.emitEvents(lenders);
    }
}
