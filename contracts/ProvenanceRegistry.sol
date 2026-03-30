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

    // Deployer is assigned Admin role on deployment

    constructor() {
        owner = msg.sender;
        roles[msg.sender] = Role.Admin;
    }

    // Admin assigns roles to supply chain participants
    function assignRole(address participant, Role role) external onlyAdmin {}

    // Must be called after deployment to authorize AlertRecallManager cross-contract calls
    function setRecallManagerAddress(address _addr) external onlyAdmin {}

    // Farmer registers a new batch at harvest; logs the first CustodyEvent in the audit trail
    function createBatch(
        string memory batchId,
        string memory productName,
        string memory originIpfsCid,
        string memory location,
        string memory notes
    ) external onlyFarmer {}

    // Current custodian passes the batch to the next participant; stage must advance forward
    // Appends a new CustodyEvent to the immutable audit trail
    function transferCustody(
        string memory batchId,
        address to,
        BatchStage newStage,
        string memory location,
        string memory ipfsCid,
        string memory notes
    ) external batchExists(batchId) onlyCustodian(batchId) notRecalled(batchId) {}

    // Called only by AlertRecallManager to freeze a batch; blocks all further transfers
    function markAsRecalled(string memory batchId) external batchExists(batchId) onlyRecallManager {}

    // Returns current batch state - used by frontend for QR code provenance lookups
    function getBatch(string memory batchId) external view batchExists(batchId) returns (Batch memory) {}

    // Returns full ordered audit trail - primary data source for provenance verification
    function getCustodyHistory(string memory batchId) external view batchExists(batchId) returns (CustodyEvent[] memory) {}

    function getCustodyEventCount(string memory batchId) external view batchExists(batchId) returns (uint256) {}

    // Returns all batch IDs - used by Regulators for system-wide audits
    function getAllBatchIds() external view returns (string[] memory) {}

    // Used by AlertRecallManager to verify a caller is a registered participant
    function getRole(address participant) external view returns (Role) {}
}
