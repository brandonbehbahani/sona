pragma solidity ^0.5.0;


/**
 * This smart contract is called "Sona". It is a rating system where there is a set number of ratings
 * made available to users via tokens. These tokens are redistributted at the end of every week from
 * the time that the contract is deployed. The scarcity and distribution of these tokens is meant
 * to encourage user responcibility. There is no oversight of this smart contract and it is
 * monolithic and immutable by design.
 */



/// safe math library used here to ensure all calculations go off without a hitch.
/// There are a few calculations that really benefit from this.
/// Namely the function that computes the average of recent ratings and
/// sets that value to the users current rating.
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {

        if (a == 0) {

            return 0;

        }

        c = a * b;

        assert(c / a == b);

        return c;

    }



    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        (b > 0); // Solidity automatically throws when dividing by 0

        uint256 c = a / b;

        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return a / b;

    }



    function sub(uint256 a, uint256 b) internal pure returns (uint256) {

        assert(b <= a);

        return a - b;

    }



    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {

        c = a + b;

        assert(c >= a);

        return c;

    }

}





contract SonaAdmin {



    struct Admin {
        address userAddress;
        bool isAdmin;
    }

    mapping (address => Admin ) public  allAdmin ;


    modifier onlyAdmin(address _userAddress){
        require(allAdmin[_userAddress].isAdmin == true);
        _;
    }


    function addAdmin(address _userAddress) onlyAdmin(msg.sender) public {
        allAdmin[_userAddress].isAdmin = true;
    }



}




/// Interface used for the ERC20 token standard
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }


///This next contract is the sona token.
/// the puspose of this token is to be used to pay for ratings.
/// it is also used to create an account
contract SonaToken is SonaAdmin{

    using SafeMath for uint256;

    string public name;

    string public symbol;

    /// the decimals are kept at 18 as is standard practice
    /// with ERC20 tokens
    uint8 public decimals = 18;

    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);


    function SonaToken () public

    {

        totalSupply = 1000000000 * 10 ** uint256(decimals);

        balanceOf[msg.sender] = totalSupply;

        name = "Sona";

        symbol = "SNA";

    }



    function transfer(address _to, uint256 _value) public {

        _transfer(msg.sender, _to, _value);

    }



    function transferFrom(

        address _from, address _to, uint256 _value

        ) public returns (bool success)

        {

        require(_value <= allowance[_from][msg.sender]);     // Check allowance

        allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;

    }



    function approve(

        address _spender, uint256 _value

        ) public returns (bool success)

        {

        allowance[msg.sender][_spender] = _value;

        return true;

    }



    function approveAndCall(

        address _spender, uint256 _value, bytes _extraData

        ) public returns (bool success)

        {

        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {

            spender.receiveApproval(msg.sender, _value, this, _extraData);

            return true;

        }

    }



    function _transfer(

        address _from, address _to, uint _value

        ) internal {

        require(_to != 0x0);

        require(balanceOf[_from] >= _value);

        require(balanceOf[_to] + _value > balanceOf[_to]);

        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;

        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

    }

}


///Sona base contract is where functions are held
///that an individual user calls on himself/herself
/// This includes making the user account active and
/// collecting tokens at the end of the week.
contract SonaBase is SonaToken {

    using SafeMath for uint256;



    struct User {

        address userAddress;

        uint256[] ratings;

        uint256 currentRating;

        uint256 userStartTime;

        uint256 deadline;

        bool isUser;

    }




    mapping (address => User) public allUsers;

    uint256 public totalUsers;

    event TokensCollected(address userAddress, uint256 rating, uint256 balance);

    event NewUser(address userAddress);



    modifier onlyUser(address _userAddress){
        require( allUsers[_userAddress].isUser == true);
        _;
    }

    /// here is where a user can become active and
    /// start using the smart contract to rate other
    /// ethereum addresses
    function becomeUser() public returns (bool success)

    {

        require(allUsers[msg.sender].isUser != true);

        require(balanceOf[msg.sender] >= 1000000000000000000);

        _transfer(msg.sender, address(this), 1000000000000000000);

        allUsers[msg.sender].isUser = true;

        allUsers[msg.sender].deadline = (now + 10 minutes);

        allUsers[msg.sender].ratings.push(0);

        allUsers[msg.sender].userAddress = msg.sender;

        /// This variable is used to track how long this address has
        /// been a Sona user.
        /// Only after 10 weeks of use does the user get full
        /// token rewards for their rating.
        allUsers[msg.sender].userStartTime = now;

        totalUsers++;

        emit NewUser(msg.sender);

        return true;

    }

    /// Returns a given the message senders own rating
    function getYourRating() onlyUser(msg.sender) public view returns (uint256){

        return allUsers[msg.sender].currentRating;

    }






    function getBlockTime() onlyUser(msg.sender) public returns (uint256){



        return now;

    }


    /// the most important and interesting part of the app is below
    /// this function distributes the tokens back to the community
    /// based on the users rating. The higher the rating the more
    /// coins the user gets
    function collectTokens() onlyUser(msg.sender)public returns (bool success)

    {

        require(balanceOf[address(this)] > 1000000000000000000); // this checks if the user has enough tokens to pay for this action

        User memory user = allUsers[msg.sender];

        require(now > user.deadline);

        require(user.isUser == true);

        uint256 lifeTimeModifier;

        uint256 tokenSupply = balanceOf[address(this)];

        uint256 tokensPerStar = tokenSupply/(totalUsers * 5);

        /// Computes the lifetime modifier based on
        /// length of time this address has been
        /// a Sona user.
        if (now - user.userStartTime > 10 hours){

            lifeTimeModifier = 1;

        } else if (now - user.userStartTime > 5 hours){

            lifeTimeModifier = 2;

        } else {

            lifeTimeModifier = 3;


        }

        /// THis distributes the tokens based on the currentRating
        /// the currentRating rating is an ever evovling average of
        /// an array of integers
        if (user.currentRating >= 100) {

            _transfer(address(this), user.userAddress, (1 * tokensPerStar/lifeTimeModifier));

        } else if (user.currentRating >= 200) {

            _transfer(address(this), user.userAddress, (2 * tokensPerStar/lifeTimeModifier));

        } else if (user.currentRating >= 300) {

            _transfer(address(this), user.userAddress, (3 * tokensPerStar/lifeTimeModifier));

        } else if (user.currentRating >= 400) {

            _transfer(address(this), user.userAddress, (4 * tokensPerStar/lifeTimeModifier));

        }

        user.deadline = (now + 10 minutes); // resets the new deadline

        user.currentRating -= 25; //rating decay

        allUsers[msg.sender] = user;

        emit TokensCollected(msg.sender, user.currentRating, balanceOf[msg.sender]);

        return true;
    }



    ///Admin functions////
    ///////////////////////
    ///
    ///
    function banUser(address _userAddress) onlyAdmin(msg.sender) public returns (bool success) {

        User memory user = allUsers[_userAddress];

        require (user.currentRating < 100);

        user.isUser = false;

        allUsers[_userAddress].isUser = false;

        return true;
    }




    function removeAdmin(address _userAddress) onlyAdmin(msg.sender) public returns  (bool success){

        require(allAdmin[_userAddress].isAdmin == true );



        require(allUsers[msg.sender].currentRating > 400);
        require(allUsers[_userAddress].currentRating < 100);
        allAdmin[_userAddress].isAdmin = false;

        return true;
    }



}




contract SonaSocial is SonaBase {



    struct Profile {

        string userName;

        string bio;

        string link;

        string emailAddress;

    }



    struct Status {

        string content;

    }



    struct Comment {

        string textContent;

        address commeneterAddress;

    }



    mapping (address => Profile) public allProfiles;

    mapping (address => Status[]) public allStatus;



    function SonaSocial(){



    }



    function updateUserProfile(

        string _userName, string _bio, string _link, string _emailAddress

    ) onlyUser(msg.sender) public {

        require(allUsers[msg.sender].isUser == true);

        Profile memory profile = allProfiles[msg.sender];

        profile.userName = _userName;

        profile.bio = _bio;

        profile.link = _link;

        profile.emailAddress = _emailAddress;

    }



    function createStatus(string _content) onlyUser(msg.sender) public {

        require(allUsers[msg.sender].isUser == true);

        Status memory status;

        status.content = _content;



        allStatus[msg.sender].push(status);



    }








    function retriveStatus(address _userAddress){



    }





    function getUserProfile(address _userAddress){



    }












}

/// Sona core is the core implementation of the sona smart contract
/// this is where user ratings are averaged into their current ratings
/// Also here is where you can find the function returning the rating of
/// any sona user.
contract SonaCore is SonaSocial {

    using SafeMath for uint256;

    event UserIsRated(address userAddress, uint256 rating, address rater);

    /// fallback function ///
    function () public payable {}


    function getUserRating(

        address _userAddress

        )

        public view returns (uint256 rating)

    {

        return allUsers[_userAddress].currentRating;

    }


    /// This function is for adding a rating to a user account
    /// ratings are between 0 to 5
    /// each rating costs 1 Sona token
    function rateUserFromOneToFive(

        address _userAddress, uint256 _rating

        ) public returns (bool success)

    {

        require(balanceOf[msg.sender] > 1000000000000000000);

        require(allUsers[msg.sender].isUser == true);

        require(_rating <= 5 && _rating >= 0);

        /// we mulitiply the rating by 100 as
        /// the internal rating system works on
        /// a basis of 0 to 500
        _rating = _rating * 100;

        /// here the contract withdraws 1 sona token from the rater
        /// and send it to the contrat address.
        /// at the end of the week these tokens stored in the contract
        /// will be distributed to the users.
        _transfer(msg.sender, address(this), 1000000000000000000);

        allUsers[_userAddress].ratings.push(_rating);

        User memory user = allUsers[_userAddress];

        if (allUsers[_userAddress].ratings.length > 25){

            for (uint256 i = user.ratings.length - 25; i < user.ratings.length; i++){

                user.currentRating += allUsers[_userAddress].ratings[i];

            }

            allUsers[_userAddress].currentRating = user.currentRating / user.ratings.length;

        } else {

            for (i = 0; i < allUsers[_userAddress].ratings.length; i++){

                user.currentRating += user.ratings[i];

            }

            allUsers[_userAddress].currentRating = user.currentRating / user.ratings.length;

        }

        emit UserIsRated(_userAddress, _rating, msg.sender);

        /// here we give the user a small reward for their participation
        /// in the Sona ecosystem
        allUsers[msg.sender].ratings.push(allUsers[msg.sender].currentRating + 5);

        return true;
    }

    function terminate() public {
        selfdestruct(msg.sender);
    }


}
