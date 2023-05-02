// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MerkleShare {
    bytes32 public root;
    IERC20 public token;

    mapping(uint256 => mapping(address => bool)) public claimed;

    event Claimed(uint256 indexed index, address indexed account, uint256 amount);

    constructor(bytes32 _root, address _token) {
        root = _root;
        token = IERC20(_token);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] memory proof) external {
        require(!claimed[index][account], "MerkleShare: Drop already claimed.");

        bytes32 leaf = keccak256(abi.encodePacked(index, account, amount));
        require(_verify(leaf, proof), "MerkleShare: Invalid proof.");

        claimed[index][account] = true;

        require(token.transfer(account, amount), "MerkleShare: Transfer failed.");

        emit Claimed(index, account, amount);
    }

    function isClaimed(uint256 index, address account) public view returns (bool) {
        return claimed[index][account];
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        bytes32 node = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (node < proofElement) {
                node = keccak256(abi.encodePacked(node, proofElement));
            } else {
                node = keccak256(abi.encodePacked(proofElement, node));
            }
        }

        return node == root;
    }
}