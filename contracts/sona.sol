pragma solidity 0.5.0;

/**
 * @title: SONA: The governance and funding protocol.
 *
 *
 * This smart contract is a DAO or "decentralized autonoums organization" that
 * distributes a token reward based on rating. Ratings are democratically decided
 * by the community using the SONA token. Much of the source code is comprised of
 * OpenZeppelin smart contracts to ensure core token and Role functionality. 
 * 
 */




contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableBase is PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

/**
 * @title Pausable token
 * @dev ERC20 with pausable transfers and allowances.
 *
 * Useful if you want to e.g. stop trades until the end of a crowdsale, or have
 * an emergency switch for freezing all token transfers in the event of a large
 * bug.
 */
contract Pausable is ERC20, PausableBase {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}


/**
 * @dev Extension of `ERC20` that adds a set of accounts with the `MinterRole`,
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract Mintable is ERC20, MinterRole {
    /**
     * @dev See `ERC20._mint`.
     *
     * Requirements:
     *
     * - the caller must have the `MinterRole`.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

/**
 * @dev Extension of `ERC20` that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract Burnable is ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See `ERC20._burn`.
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    /**
     * @dev See `ERC20._burnFrom`.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

/**
 * @title Detailed
 * @dev Optional functions from the ERC20 standard.
 */
contract Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract SonaToken is Pausable, Mintable, Burnable, Detailed {

    uint8 public constant DECIMALS = 18;
    
    uint256 public constant INITIAL_SUPPLY = 1000000 * (10 ** uint256(DECIMALS));
    
    constructor () public Detailed("Sona", "SNA", DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}

/**
 * @title SonaCore
 *
 * @author Brandon Behbahani
 *
 * @notice This is the core smart contract. Other functionality and upgrades
 * will be built around this smart contract.
 * @dev This contract contains mechanisms for storing rating and allocating
 * rewards. This contract contains admin functions.
 * 
 */
contract SonaCore is SonaToken, AdminRole {
    
    using SafeMath for uint256;
    
    uint256 public totalPosVotes_;
    
    uint256 private interval_;
    
    uint256 private divisor_;
    
    uint256 private price_;
    
    enum VoteType {DEFAULT, UPVOTE, DOWNVOTE}
    
    struct User {
        bool isUser;
        string name;
        string desc;
        uint256 deadLine;
        uint256 numVotes;
        uint256 upVotes;
        uint256 downVotes;
        uint256 score;
    }
    
    struct Vote {
        VoteType voteType;
        uint256 value;
        string info;
        address rater;
    }
    
    ////////////////////////////////// Evnets /////////////////////////////////////////////
    
    event Rated(address account, string info, VoteType vt, uint256 value);
    
    event NewPersona(address account, string name, string desc);
    
    event RewardCollected(address account, string name, uint256 amount);
    
    mapping (address => User) public _allUsers;
    
    mapping (address => mapping (uint256 => Vote)) public _allVotes;
    
    /////////////////////////////////// admin functions /////////////////////////////////////////
    
    function setInterval(uint256 _interval) public onlyAdmin {
        interval_ = _interval;
    }
    
    function setDivisor(uint256 _divisor) public onlyAdmin {
        divisor_ = _divisor;
    }
    
    function setPrice(uint256 _price) public onlyAdmin {
        price_ = _price;
    }
    
    ///////////////////////////////////////core functions///////////////////////////////////////////

    function BecomePersona(string memory _userName, string memory _userDesc) public {
        User memory u = _allUsers[msg.sender];
        require(u.isUser == false);
        u.isUser = true;
        u.name = _userName;
        u.desc = _userDesc;
        u.deadLine = now.add(interval_);
        _allUsers[msg.sender] = u;
        emit NewPersona(msg.sender, _userName, _userDesc);
    }
    
    modifier onlyUser() {
        require(_allUsers[msg.sender].isUser, "SonaCore: caller does not have the User role");
        _;
    }
    
    function setUserDescription (string memory _userDesc) public onlyUser {
        _allUsers[msg.sender].desc = _userDesc; 
    }
    
    /**
     * @dev Collects Sona tokens for positive ratings.
     *
     * This is a public funtion used to give upvotes.
     * The cost of the rating is sent to the address of this smart contract.
     *
     */
    function upVoteUser(address _userAddress, uint256 _value, string memory _info) public onlyUser{
        User memory u = _allUsers[_userAddress];
        require(u.isUser == true, "SonaCore: user address is invalid");
        require(_userAddress != msg.sender, "SonaCore: user address is invalid");
        totalPosVotes_ = totalPosVotes_.sub(u.score);
        u.numVotes = u.numVotes.add(1);
        uint256 voteVal = _value.div(price_);
        u.upVotes = u.upVotes.add(voteVal);
        if (u.upVotes > u.downVotes){
            u.score = u.upVotes.sub(u.downVotes);
        } else {
            u.score = 0;
        }
        Vote memory v;
        v.voteType = VoteType.UPVOTE;
        v.value = voteVal;
        v.info = _info;
        v.rater = msg.sender;
        totalPosVotes_ = totalPosVotes_.add(u.score);
        _transfer(msg.sender, address(this), _value);
        _allUsers[_userAddress] = u;
        _allVotes[_userAddress][u.numVotes] = v;
        emit Rated(_userAddress, _info, VoteType.UPVOTE, voteVal);
    }
    
    /**
     * @dev Collects Sona tokens for negative ratings.
     *
     * This is a public funtion used to give downvotes.
     * The cost of the rating is sent to the address of this smart contract.
     *
     */
    function downVoteUser (address _userAddress, uint256 _value, string memory _info) public onlyUser{
        User memory u = _allUsers[_userAddress];
        require(u.isUser == true, "SonaCore: user address is invalid");
        require(_userAddress != msg.sender, "SonaCore: user address is invalid");
        totalPosVotes_ = totalPosVotes_.sub(u.score);
        u.numVotes = u.numVotes.add(1);
        uint256 voteVal = _value.div(price_);
        u.downVotes = u.downVotes.add(voteVal);
        if (u.upVotes > u.downVotes){
            u.score = u.upVotes.sub(u.downVotes);
        } else {
            u.score = 0;
        }
        Vote memory v;
        v.voteType = VoteType.DOWNVOTE;
        v.value = voteVal;
        v.info = _info;
        v.rater = msg.sender;
        totalPosVotes_ = totalPosVotes_.add(u.score);
        _transfer(msg.sender, address(this), _value);
        _allUsers[_userAddress] = u;
        _allVotes[_userAddress][u.numVotes] = v;
        emit Rated(_userAddress, _info, VoteType.DOWNVOTE, voteVal);
    }
    
    /**
     * @dev Distributes tokens for user when their deadLine is finished.
     *
     * The token rewards are determined by the user score;
     * 
     */
    function collectReward() public onlyUser {
        User memory u = _allUsers[msg.sender];
        require(now > u.deadLine, "SonaCore: The deadline has not been reached."); 
        require(u.score > 0, "SonaCore: positive score is required.");
        uint256 balancePerPoint = balanceOf(address(this)).div(totalPosVotes_);
        uint256 balanceOwed = balancePerPoint.mul(u.score).div(divisor_);
        _transfer(address(this), msg.sender, balanceOwed);
        u.deadLine = u.deadLine.add(interval_);
        _allUsers[msg.sender] = u; 
        emit RewardCollected(msg.sender, u.name, balanceOwed); 
    }
   
   //////////////////////////////// constructor //////////////////////////////////
   
    constructor() public {
        interval_ = 100; // intentionally short interval for testing pusposes
        divisor_ = 100;
        price_ = 1000000000000000000;
    }
    
    //////////////////////////////// getters /////////////////////////////////////
    
    
    function getInterval() public view returns (uint256){
        return interval_;
    }
    
    function getDivisor() public view returns (uint256){
        return divisor_;
    }
    
    function getPrice() public view returns (uint256){
        return price_;
    }
}
