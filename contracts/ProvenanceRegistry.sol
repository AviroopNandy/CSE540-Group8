// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Tracks food product batches through the supply chain.
// Every custody transfer is recorded as an immutable on-chain event.
// IPFS content hashes are stored on-chain; bulk files live off-chain.
// Recalled state is set exclusively by AlertRecallManager.
contract ProvenanceRegistry {

    // Stages must progress forward — no reversals allowed
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
        emit RoleAssigned(msg.sender, Role.Admin, block.timestamp);
    }

    // Admin assigns roles to supply chain participants
    function assignRole(address participant, Role role) external onlyAdmin {
        roles[participant] = role;
        emit RoleAssigned(participant, role, block.timestamp);
    }

    // Must be called after deployment to authorize AlertRecallManager cross-contract calls
    function setRecallManagerAddress(address _addr) external onlyAdmin {
        recallManagerAddress = _addr;
    }

    // Farmer registers a new batch at harvest; logs the first CustodyEvent in the audit trail
    function createBatch(
        string memory batchId,
        string memory productName,
        string memory originIpfsCid,
        string memory location,
        string memory notes
    ) external onlyFarmer {
        require(bytes(batches[batchId].batchId).length == 0, "Batch ID already exists");

        batches[batchId] = Batch({
            batchId: batchId,
            productName: productName,
            currentCustodian: msg.sender,
            currentStage: BatchStage.Harvested,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            originIpfsCid: originIpfsCid,
            isRecalled: false
        });

        // address(0) as 'from' marks this as the origin event with no prior custodian
        custodyHistory[batchId].push(CustodyEvent({
            from: address(0),
            to: msg.sender,
            stage: BatchStage.Harvested,
            timestamp: block.timestamp,
            location: location,
            ipfsCid: originIpfsCid,
            notes: notes
        }));

        allBatchIds.push(batchId);
        emit BatchCreated(batchId, productName, msg.sender, block.timestamp);
    }

    // Current custodian passes the batch to the next participant; stage must advance forward
    // Appends a new CustodyEvent to the immutable audit trail
    function transferCustody(
        string memory batchId,
        address to,
        BatchStage newStage,
        string memory location,
        string memory ipfsCid,
        string memory notes
    ) external batchExists(batchId) onlyCustodian(batchId) notRecalled(batchId) {
        require(roles[to] != Role.None, "Recipient not registered");
        require(uint8(newStage) > uint8(batches[batchId].currentStage), "Stage must advance forward");
        require(newStage != BatchStage.Recalled && newStage != BatchStage.Consumed, "Use dedicated functions for these stages");

        address prev = batches[batchId].currentCustodian;
        batches[batchId].currentCustodian = to;
        batches[batchId].currentStage = newStage;
        batches[batchId].updatedAt = block.timestamp;

        custodyHistory[batchId].push(CustodyEvent({
            from: prev,
            to: to,
            stage: newStage,
            timestamp: block.timestamp,
            location: location,
            ipfsCid: ipfsCid,
            notes: notes
        }));

        emit CustodyTransferred(batchId, prev, to, newStage, block.timestamp);
    }

    // Called only by AlertRecallManager to freeze a batch; blocks all further transfers
    function markAsRecalled(string memory batchId) external batchExists(batchId) onlyRecallManager {
        batches[batchId].isRecalled = true;
        batches[batchId].currentStage = BatchStage.Recalled;
        batches[batchId].updatedAt = block.timestamp;
        emit BatchRecalled(batchId, msg.sender, block.timestamp);
    }

    // Returns current batch state — used by frontend for QR code provenance lookups
    function getBatch(string memory batchId) external view batchExists(batchId) returns (Batch memory) {
        return batches[batchId];
    }

    // Returns full ordered audit trail — primary data source for provenance verification
    function getCustodyHistory(string memory batchId) external view batchExists(batchId) returns (CustodyEvent[] memory) {
        return custodyHistory[batchId];
    }

    function getCustodyEventCount(string memory batchId) external view batchExists(batchId) returns (uint256) {
        return custodyHistory[batchId].length;
    }

    // Returns all batch IDs — used by Regulators for system-wide audits
    function getAllBatchIds() external view returns (string[] memory) {
        return allBatchIds;
    }

    // Used by AlertRecallManager to verify a caller is a registered participant
    function getRole(address participant) external view returns (Role) {
        return roles[participant];
    }
}
