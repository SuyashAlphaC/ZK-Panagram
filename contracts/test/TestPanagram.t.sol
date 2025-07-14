//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {HonkVerifier} from "../src/Verifier.sol";
import {Panagram} from "../src/Panagram.sol";


contract TestPanagram is Test {
    address user = makeAddr("user");
    uint256 constant FEILD_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    Panagram public panagram;
    bytes32 INCORRECT_GUESS = bytes32(uint256(keccak256("Suyash")) % FEILD_MODULUS);
    bytes32 ANSWER = bytes32(uint256(keccak256("Triangle")) % FEILD_MODULUS);

    HonkVerifier public verifier;
    function setUp() external {
        verifier = new HonkVerifier();
        panagram = new Panagram(verifier);

        panagram.newRound(ANSWER);
    }

    function _getProof(bytes32 guess, bytes32 correctAnswer, address _user) internal returns(bytes memory proof) {
        uint256 NUM_ARGS = 6;

        string[] memory inputs = new string[](NUM_ARGS);
        inputs[0] = "npx";
        inputs[1] = "tsx";
        inputs[2] = "js-scripts/generateProof.ts";
        inputs[3] = vm.toString(guess);
        inputs[4] = vm.toString(correctAnswer);
        inputs[5] = vm.toString(_user);
        bytes memory encodedProof = vm.ffi(inputs);
        proof = abi.decode(encodedProof, (bytes));
        console.logBytes(proof);
    }

    function testCorrectGuessPasses() public {
        vm.prank(user);
        bytes memory proof = _getProof(ANSWER, ANSWER, user);
        panagram.makeGuess(proof);

        vm.assertEq(panagram.balanceOf(user, 0), 1);
        vm.assertEq(panagram.balanceOf(user , 1), 0);
    }

    function testStartSecodeRound() public {
        vm.prank(user);
        bytes memory proof = _getProof(ANSWER, ANSWER, user);
        panagram.makeGuess(proof);

        vm.warp(panagram.MIN_DURATION() + 1);
        vm.roll;
        bytes32 NEW_ANSWER = bytes32(uint256(keccak256("outnumber")) % FEILD_MODULUS);
        panagram.newRound(NEW_ANSWER);
        vm.assertEq(panagram.s_currentRound(), 2);
        vm.assertEq(panagram.s_currentRoundWinner(), address(0));
        vm.assertEq(panagram.s_answer(), NEW_ANSWER);
    }

    function testSecondWinner() public {
        vm.prank(user);
        bytes memory proof = _getProof(ANSWER, ANSWER, user);
        panagram.makeGuess(proof);

        address user2 = makeAddr("user2");
        vm.prank(user2);
        bytes memory proof2 = _getProof(ANSWER, ANSWER, user2);
        panagram.makeGuess(proof2);
        vm.assertEq(panagram.balanceOf(user2, 0), 0);
        vm.assertEq(panagram.balanceOf(user2, 1), 1);
    }

     function testIncorrectGuessFails() public {
        // panagram.newRound(INCORRECT_GUESS);
        // start a round
        // get hash(?) of guess
        // use script to get proof
        // make a guess call
        // validate they got the winner NFT
        // validate they have been incremented in winnerWins mapping  
        bytes memory incorrectProof = _getProof(INCORRECT_GUESS, INCORRECT_GUESS, user);
        vm.prank(user);
        vm.expectRevert();
        panagram.makeGuess(incorrectProof);
    }
}