//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IVerifier} from "./Verifier.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
contract Panagram is ERC1155, Ownable{
    IVerifier public s_verifier;
    uint256 public s_roundStartTime;
    bytes32 public s_answer;
    uint256 public constant MIN_DURATION = 10800;
    address public s_currentRoundWinner;
    uint256 public s_currentRound;
    mapping(address => uint256) public s_lastCorrectGuessedRound; 

    event Panagram__NewRoundStarted(uint256 roundStartedAt, uint256 currentround, bytes32 answer);
    event Panagram__WinnerCrowned(uint256 indexed currentRound, address user);
    event Panagram__VerifierUpdated(IVerifier newVerifier);
    event Panagram__RunnerUpsCrowned(uint256 indexed currentRound, address indexed user);

    error Panagram__NoRoundYet(uint256 currentRound);
    error Panagram__InvalidProof();
    error Panagram__AlreadyGuessedCorrectly(uint256 currentRound, address user);
    error Panagram__MinTimeNotPassed(uint256 min_duration, uint256 timePassed);
    error Panagram__WinnerNotYetAnnounced();
    constructor(IVerifier _verifier) ERC1155("ipfs://QmcPXv7GEyX3XeiHL6LG6wqVf93dnUpuJcBMSQxS8UbCKf/{id}.json") Ownable(msg.sender){
        s_verifier = _verifier;
    }

    function newRound(bytes32 _answer) external {
        if(s_roundStartTime == 0) {
            s_roundStartTime = block.timestamp;
            s_answer = _answer;
        } else {
            if(block.timestamp < s_roundStartTime + MIN_DURATION) {
                revert Panagram__MinTimeNotPassed(MIN_DURATION , block.timestamp - s_roundStartTime);
            }
            if(s_currentRoundWinner == address(0)) {
                revert Panagram__WinnerNotYetAnnounced();
            }
            s_roundStartTime = block.timestamp;
            s_currentRoundWinner = address(0);
            s_answer = _answer;
        }
        s_currentRound ++ ;
        emit Panagram__NewRoundStarted(s_roundStartTime, s_currentRound, _answer);
    }

    function makeGuess(bytes memory proof) external {
        if(s_currentRound == 0) {
            revert Panagram__NoRoundYet(s_currentRound);
        }
        if(s_lastCorrectGuessedRound[msg.sender] == s_currentRound) {
            revert Panagram__AlreadyGuessedCorrectly(s_currentRound, msg.sender);
        }

        bytes32[] memory publicInputs = new bytes32[](1);
        publicInputs[0] = s_answer;
        bool proofOutput = s_verifier.verify(proof, publicInputs);
        if(!proofOutput) {
            revert Panagram__InvalidProof();
        }
        s_lastCorrectGuessedRound[msg.sender] = s_currentRound;
        if(s_currentRoundWinner == address(0)) {
            s_currentRoundWinner = msg.sender;
            _mint(msg.sender, 0 , 1, "");
            emit Panagram__WinnerCrowned(s_currentRound, msg.sender);
        } else {
            _mint(msg.sender , 1, 1, "");
            emit Panagram__RunnerUpsCrowned(s_currentRound, msg.sender);
        }

    }
    function setVerifier(IVerifier _verifier) external onlyOwner {
        s_verifier = _verifier;
        emit Panagram__VerifierUpdated(_verifier);
    }
}