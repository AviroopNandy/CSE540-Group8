// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Tracks food product batches through the supply chain.
// Every custody transfer is recorded as an immutable on-chain event.
// IPFS content hashes are stored on-chain; bulk files live off-chain.
// Recalled state is set exclusively by AlertRecallManager.
contract ProvenanceRegistry {

    // Stages must progress forward - no reversals allowed
    enum BatchStage { Harvested, Processing, Packaged, InTransit, AtRetail, Recalled, Consumed }

    // Each address holds one role assigned by Admin
    enum Role { None, Admin, Farmer, Processor, Logistics, Retailer, Regulator }

    struct Batch {
        string batchId;
        string productName;
        address currentCustodian;
        BatchStage currentStage;
        uint256 createdAt;
        uint256 updatedAt;
        string originIpfsCid;
        bool isRecalled;
    }

    // Appended to the audit trail on every custody transfer
    struct CustodyEvent {
        address from;
        address to;
        BatchStage stage;
        uint256 timestamp;
        string location;
        string ipfsCid;
        string notes;
    }

    address public owner;
    mapping(address => Role) public roles;
    mapping(string => Batch) private batches;
    mapping(string => CustodyEvent[]) private custodyHistory;
    string[] private allBatchIds;
    address public recallManagerAddress;

    event BatchCreated(string indexed batchId, string productName, address indexed farmer, uint256 timestamp);
    event CustodyTransferred(string indexed batchId, address indexed from, address indexed to, BatchStage newStage, uint256 timestamp);
    event BatchRecalled(string indexed batchId, address triggeredBy, uint256 timestamp);
    event RoleAssigned(address indexed participant, Role role, uint256 timestamp);

    modifier onlyAdmin() { require(roles[msg.sender] == Role.Admin, "Not Admin"); _; }
    modifier onlyFarmer() { require(roles[msg.sender] == Role.Farmer, "Not Farmer"); _; }
    modifier onlyCustodian(string memory batchId) { require(batches[batchId].currentCustodian == msg.sender, "Not custodian"); _; }
    modifier batchExists(string memory batchId) { require(bytes(batches[batchId].batchId).length > 0, "Batch not found"); _; }
    modifier notRecalled(string memory batchId) { require(!batches[batchId].isRecalled, "Batch recalled"); _; }
    modifier onlyRecallManager() { require(msg.sender == recallManagerAddress, "Not RecallManager"); _; }
}
