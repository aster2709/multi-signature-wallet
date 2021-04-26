//SPDX-License-Identifier: MIT 
pragma solidity ^0.8;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
contract MultiSigWallet is Ownable {
    uint public minEntry;
    uint memberCount;
    mapping (address => bool) public members;
    Transaction[] transactions;
    struct Transaction {
        address creator;
        address to;
        uint amount;
        uint approveCount;
        bool completed;
        mapping (address => bool) approvers;
    }
    modifier isMember() {
        require(members[msg.sender], "you are not a member");
        _;
    }
    modifier txExists(uint id) {
        require(id < transactions.length, "transaction id invalid");
        _;
    }
    constructor(uint _minEntry) {
        minEntry = _minEntry;
    }
    function enter() external payable {
        require(msg.value >= minEntry, "requires minimum amount");
        if (!members[msg.sender]) {
            memberCount++;
        }
        members[msg.sender] = true;
    }
    function createTransaction(address _to, uint _amount) external isMember {
        require(_amount <= address(this).balance, "amount cannot be more than contract balance");
        transactions.push();
        Transaction storage s = transactions[transactions.length-1];
        s.creator = msg.sender;
        s.to = _to;
        s.amount = _amount;
    }
    function approveTransaction(uint _id) external isMember txExists(_id) {
        Transaction storage t = transactions[_id];
        require(!t.completed, "transaction already executed");
        require(!t.approvers[msg.sender], "You have already voted");
        t.approveCount++;
    }
    function finalizeTransaction(uint _id) external isMember txExists(_id) {
        Transaction storage t = transactions[_id];
        require(!t.completed, "transaction already executed");
        require(t.creator == msg.sender, "only the create of the transaction can finalize");
        require(t.approveCount >= memberCount/2,"approve count not enough");
        (bool success, ) = t.to.call{value: t.amount}("");
        require(success, "tx failed, doe");
        t.completed = true;
    }
    function removeMember(address _member) external onlyOwner {
        require(members[_member], "invalid member address");
        members[_member] = false;
    }
}
