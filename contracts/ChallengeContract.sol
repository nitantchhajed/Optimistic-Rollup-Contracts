// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ChallengeContract {
    address payable admin;
    uint256 challengePeriod;
    uint256 id;

    struct Transaction {
        address sender;
        uint256 amount;
        address payable recipient;
        uint256 challengeEndTime;
        bool challenged;
        bool claimed;
        bool isReverted;
        bool isCompleted;
        uint256 id;
    }
    Transaction[] public allTransactions;
    mapping(address => uint256[]) public recipientTransactions;
    mapping(address => uint256[]) public senderTransactions;

    event TransactionSent(
        address indexed sender,
        uint256 amount,
        address indexed recipient,
        uint256 challengeEndTime
    );
    event TransactionChallenged(
        address indexed sender,
        uint256 amount,
        address indexed recipient
    );
    event FundsClaimed(address indexed recipient, uint256 amount);
    event TransactionReverted(
        address indexed sender,
        uint256 amount,
        address indexed recipient
    );

    constructor(uint256 _challengePeriod) {
        admin = payable(msg.sender);
        challengePeriod = _challengePeriod;
        id = 1;
        allTransactions.push();
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can call this function.");
        _;
    }

    function sendFunds(address payable _recipient) external payable {
        require(msg.value > 0, "Amount should be greater than zero.");
        require(_recipient != address(0), "Invalid recipient address.");

        uint256 challengeEndTime = block.timestamp + challengePeriod;

        Transaction memory txn = Transaction(
            msg.sender,
            msg.value,
            _recipient,
            challengeEndTime,
            false,
            false,
            false,
            false,
            id
        );

        allTransactions.push(txn);
        senderTransactions[msg.sender].push(id);
        recipientTransactions[_recipient].push(id);

        emit TransactionSent(
            msg.sender,
            msg.value,
            _recipient,
            challengeEndTime
        );
        id = id + 1;
    }

    function challengeTransaction(address payable _recipient, uint256 _id)
        external
    {
        require(_id != 0, "Invalid ID");
        require(_id <= allTransactions.length, "Invalid transaction index.");

        Transaction storage txnAll = allTransactions[_id];

        require(msg.sender == txnAll.sender, "Invalid Sender");

        require(!txnAll.challenged, "Transaction already challenged.");
        require(!txnAll.claimed, "Funds already claimed.");
        require(
            block.timestamp <= txnAll.challengeEndTime,
            "Challenge period has ended."
        );

        txnAll.challenged = true;

        emit TransactionChallenged(txnAll.sender, txnAll.amount, _recipient);
    }

    function revertTransaction(uint256 _id) external payable onlyAdmin {
        require(_id <= allTransactions.length, "Invalid Transaction Index");
        require(_id != 0, "Invalid ID");
        Transaction storage txnAll = allTransactions[_id];

        require(!txnAll.isCompleted, "Transaction already Completed.");
        require(txnAll.challenged, "Transaction is not challenged.");
        require(!txnAll.claimed, "Transaction already approved.");
        require(!txnAll.isReverted, "Transaction is already reverted");

        txnAll.isReverted = true;
        txnAll.isCompleted = true;

        payable(txnAll.sender).transfer(txnAll.amount);
        emit TransactionReverted(
            txnAll.sender,
            txnAll.amount,
            txnAll.recipient
        );
    }

    function abortDispute(uint256 _id) external onlyAdmin {
        require(_id <= allTransactions.length, "Invalid Transaction Index");

        Transaction storage txnAll = allTransactions[_id];

        require(!txnAll.isCompleted, "Transaction already Completed.");
        require(txnAll.challenged, "Transaction is not challenged.");
        require(!txnAll.claimed, "Transaction already approved.");
        require(!txnAll.isReverted, "Transaction is already reverted");
        require(
            txnAll.challengeEndTime >= block.timestamp,
            "Challenge period has not been ended yet"
        );

        txnAll.challenged = false;
    }

    function claimFunds(uint256 _id) external payable {
        require(_id < allTransactions.length, "Invalid transaction index.");

        Transaction storage txnAll = allTransactions[_id];

        require(msg.sender == txnAll.recipient, "Invalid recipient");
        require(!txnAll.isCompleted, "Transaction already Completed.");
        require(!txnAll.claimed, "Funds already claimed.");
        require(!txnAll.challenged, "Cannot claim a challenged transaction.");
        require(
            block.timestamp > txnAll.challengeEndTime,
            "Challenge period has not ended yet."
        );

        txnAll.recipient.transfer(txnAll.amount);

        txnAll.claimed = true;
        txnAll.isCompleted = true;

        emit FundsClaimed(txnAll.recipient, txnAll.amount);
    }

    function withdrawFunds() external onlyAdmin {
        admin.transfer(address(this).balance);
    }

/* @notice - View functions */

    //Get Recipient Txns
    function viewTransactionsByRecipient()
        external
        view
        returns (uint256[] memory)
    {
        return recipientTransactions[msg.sender];
    }

    //Get Sender Txn
    function viewTransactionsBySender()
        external
        view
        returns (uint256[] memory)
    {
        return senderTransactions[msg.sender];
    }

    // Get all the sendFunds() Txn
    function getAllSentTransactions()
        external
        view
        onlyAdmin
        returns (Transaction[] memory)
    {
        return allTransactions;
    }
}
