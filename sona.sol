pragma solidity ^0.5.0;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/master/contracts/token/ERC20/ERC20Detailed.sol";

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/master/contracts/token/ERC20/ERC20.sol";

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/master/contracts/token/ERC20/ERC20Mintable.sol";

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/master/contracts/token/ERC20/ERC20Pausable.sol";

contract Sona is ERC20, ERC20Detailed, ERC20Mintable, ERC20Pausable {
    
    uint256 totalPosVotes;
    
    struct Community {
        string name;
        string description;
        address founder;
        bool isCommunity;
    }
    
    struct User {
        bool isUser;
        string name;
    }
    
    struct Vote {
        uint256 value;
        string info;
        address rater;
        address ratee;
    }
    
    mapping (address => User) public allUsers;
    
    mapping (uint256 => Community) public allCommunities; 
    
    uint256 numCommunites;
    
    mapping (address => mapping (uint256 => mapping (uint256 => Vote))) allVotes;
    
    mapping (address => mapping (uint256 => uint256)) allUpVotes;
    
    mapping (address => mapping (uint256 => uint256)) allDownVotes;
    
    mapping (address => mapping (uint256 => uint256)) allScores;
    
    mapping (address => mapping (uint256 => uint256)) allReputations;
    
    mapping (address => mapping (uint256 => bool)) isMember;
    
    uint8 public constant DECIMALS = 18;
    
    uint256 public constant INITIAL_SUPPLY = 1000000 * (10 ** uint256(DECIMALS));
    
    constructor () public ERC20Detailed("Sona", "SNA", DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function foundCommunity(string memory _communityName, string memory _communityDesc) public {
        Community memory c;
        c.name = _communityName;
        c.description = _communityDesc;
        c.founder = msg.sender;
        allCommunities[numCommunites] = c;
        allCommunities[numCommunites].isCommunity = true;
        numCommunites++;
    }

    function becomeMember(uint256 _communityId) public {
        require(allCommunities[_communityId].isCommunity == true);
        require(isMember[msg.sender][_communityId] == false);
        isMember[msg.sender][_communityId] = true;
        allReputations[msg.sender][_communityId] = 1;
    }
    
    function _computeUserScore(address _userAddress, uint256 _communityId)view internal returns (uint256) {
        uint256 userScore;
        if ((allUpVotes[_userAddress][_communityId] - allDownVotes[_userAddress][_communityId]) > 0){
            userScore = allUpVotes[_userAddress][_communityId] - allDownVotes[_userAddress][_communityId];
        } else {
            userScore = 0; 
        }
        return userScore;
    }
    
    function upVoteUser(address _userAddress, uint256 _communityId, uint256 _value) public {
        require(allCommunities[_communityId].isCommunity == true);
        require(isMember[_userAddress][_communityId] == true);
        require(isMember[msg.sender][_communityId] == true);
        uint256 senderReputation = allReputations[msg.sender][_communityId];  
        uint256 originUserScore = _computeUserScore(_userAddress, _communityId);
        uint256 repLimit = (allReputations[_userAddress][_communityId] + 1) ** 2;
        allUpVotes[_userAddress][_communityId] += (_value * senderReputation);
        uint256 newUserScore = _computeUserScore(_userAddress, _communityId);
        if (newUserScore > originUserScore) {
            totalPosVotes += (newUserScore - originUserScore);
        }
        allScores[_userAddress][_communityId] = newUserScore;
        if (allReputations[_userAddress][_communityId] ** 2 < newUserScore &&
            repLimit <= allScores[_userAddress][_communityId]) {
                allReputations[_userAddress][_communityId]++; 
        }
    }
    
    function downVoteUser (address _userAddress, uint256 _communityId, uint256 _value) public {
        require(allCommunities[_communityId].isCommunity == true);
        require(isMember[_userAddress][_communityId] == true);
        require(isMember[msg.sender][_communityId] == true);
        uint256 senderReputation = allReputations[msg.sender][_communityId]; 
        uint256 originUserScore = _computeUserScore(_userAddress, _communityId);
        allDownVotes[_userAddress][_communityId] += (_value * senderReputation);
        uint256 newUserScore = _computeUserScore(_userAddress, _communityId);
        if (newUserScore < originUserScore) {
            totalPosVotes -= (newUserScore - originUserScore);
        }
        allReputations[_userAddress][_communityId] = newUserScore;
        if (allReputations[_userAddress][_communityId] ** 2 > newUserScore &&
            allReputations[_userAddress][_communityId] > 1) {
                allReputations[_userAddress][_communityId]--; 
        }
    }
    
    function collectDividends(uint256 _communityId) public {
        require(allUpVotes[msg.sender][_communityId] > allDownVotes[msg.sender][_communityId]);
        uint256 userRating = allUpVotes[msg.sender][_communityId] - allDownVotes[msg.sender][_communityId];
        uint256 balancePerPoint = balanceOf(address(this))/totalPosVotes;
        uint256 balanceOwed = balancePerPoint * userRating;
        _transfer(address(this), msg.sender, balanceOwed);
    }
    
}

