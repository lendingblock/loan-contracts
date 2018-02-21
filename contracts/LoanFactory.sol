pragma solidity ^0.4.18;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Loan {

	uint256 public createdAt;
	uint256 public updatedAt;
	string public currency;
	uint256 public term;
	uint256 public rate;
	uint256 public amount;
	uint256 public effectiveRate;
	string public collateralCurrency;
	uint256 public collateralAmount;
	bytes32[] public requests;
	bytes32[] public offers;
	uint256 public status;

	LoanFactory public factory;

	function Loan(
		uint256[8] _input,
		string _currency,
		string _collateralCurrency,
		bytes32[] _requests,
		bytes32[] _offers
	)
		public
	{
		factory = LoanFactory(msg.sender);
		createdAt = _input[0];
		updatedAt = _input[1];
		term = _input[2];
		rate = _input[3];
		amount = _input[4];
		effectiveRate = _input[5];
		collateralAmount = _input[6];
		status = _input[7];
		currency = _currency;
		collateralCurrency = _collateralCurrency;
		requests = _requests;
		offers = _offers;
	}

	function getSpecs() public view returns (
		uint256[8],
		string,
		string,
		bytes32[],
		bytes32[]
	) {
		return (
			[
				createdAt,
				updatedAt,
				term,
				rate,
				amount,
				effectiveRate,
				collateralAmount,
				status
			],
			currency,
			collateralCurrency,
			requests,
			offers
		);
	}
}

contract LoanFactory is Ownable {

	struct OrderStruct {
		uint256 createdAt;
		uint256 updatedAt;
		string userId;
		string currency;
		uint256 term;
		uint256 rate;
		uint256 amount;
		uint256 effectiveRate;
		uint256 matchedAmount;
	}

	address[] public loans;
	uint256 public loansCount;
	address public worker;

	mapping(bytes32 => OrderStruct) public requests;
	mapping(bytes32 => OrderStruct) public offers;

	event NewRequest(bytes32 indexed id);
	event NewOffer(bytes32 indexed id);
	event NewLoan(address indexed loan, uint256 loanCount);

	modifier onlyWorker() {
		require(msg.sender == worker);
		_;
	}

	function LoanFactory() public {
		worker = msg.sender;
		loans.length = 1;
	}

	function newWorker(address _worker)
		external
		onlyOwner
	{
		worker = _worker;
	}

	function newRequest(bytes32 _id, uint256[7] _input, string _userId, string _currency)
		external
	{
		requests[_id].createdAt = _input[0];
		requests[_id].updatedAt = _input[1];
		requests[_id].term = _input[2];
		requests[_id].rate = _input[3];
		requests[_id].amount = _input[4];
		requests[_id].effectiveRate = _input[5];
		requests[_id].matchedAmount = _input[6];
		requests[_id].userId = _userId;
		requests[_id].currency = _currency;
		NewRequest(_id);
	}

	function newOffer(bytes32 _id, uint256[7] _input, string _userId, string _currency)
		external
	{
		offers[_id].createdAt = _input[0];
		offers[_id].updatedAt = _input[1];
		offers[_id].term = _input[2];
		offers[_id].rate = _input[3];
		offers[_id].amount = _input[4];
		offers[_id].effectiveRate = _input[5];
		offers[_id].matchedAmount = _input[6];
		offers[_id].userId = _userId;
		offers[_id].currency = _currency;
		NewOffer(_id);
	}

	function newLoan(
		uint256[8] _input,
		string _currency,
		string _collateralCurrency,
		bytes32[] _requests,
		bytes32[] _offers
	)
		external
	{
		Loan createdLoan = new Loan(_input, _currency, _collateralCurrency, _requests, _offers);
		loans.push(createdLoan);
		loansCount++;
		NewLoan(createdLoan, loansCount);
	}

	function () external {
		revert();
	}

}
