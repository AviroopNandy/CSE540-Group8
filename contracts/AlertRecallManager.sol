// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Interface to ProvenanceRegistry - only the functions this contract needs
interface IProvenanceRegistry {
    function markAsRecalled(string memory batchId) external;
    function getRole(address participant) external view returns (uint8);
}

// Manages safety violation reporting and product recalls.
// HIGH severity reports trigger an automatic recall via cross-contract call to ProvenanceRegistry.
// MEDIUM and LOW reports are stored as Open for Admin review and manual escalation.
// Off-chain oracles submit violation data through the API Gateway, which calls reportViolation().
contract AlertRecallManager {

    enum ViolationType { TemperatureExceedance, ContaminationDetected, PackagingBreach, RegulatoryFlag, FraudSuspicion, Other }

    // Only HIGH triggers automatic recall
    // LOW and MEDIUM require manual Admin review
    enum Severity { Low, Medium, High }

    enum ViolationStatus { Open, Recalled, Resolved, Dismissed }

    struct ViolationReport {
        uint256 reportId;
        string batchId;
        address reportedBy;
        ViolationType violationType;
        Severity severity;
        string details;
        string evidenceIpfsCid;  // IPFS CID of supporting evidence (sensor log, lab report)
        uint256 timestamp;
        ViolationStatus status;
    }

    // Defines acceptable min/max range for a given violation type
    struct ThresholdConfig {
        int256 minValue;
        int256 maxValue;
        bool isActive;
    }

    IProvenanceRegistry public provenanceRegistry;
    address public owner;
    uint256 private reportCounter;
    uint256 public totalReports;
    mapping(uint256 => ViolationReport) private violationReports;
    mapping(string => uint256[]) private batchViolations;
    mapping(string => bool) public isRecalled;
    mapping(ViolationType => ThresholdConfig) public thresholds;

    event ViolationReported(uint256 indexed reportId, string indexed batchId, address indexed reportedBy, ViolationType violationType, Severity severity, uint256 timestamp);
    event RecallTriggered(string indexed batchId, uint256 indexed triggeredByReportId, address triggeredBy, uint256 timestamp);
    event ViolationStatusUpdated(uint256 indexed reportId, ViolationStatus newStatus, address updatedBy, uint256 timestamp);
    event ThresholdUpdated(ViolationType violationType, int256 minValue, int256 maxValue, uint256 timestamp);

    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }
    modifier onlyRegisteredParticipant() { require(provenanceRegistry.getRole(msg.sender) != 0, "Not a registered participant"); _; }
    modifier reportExists(uint256 reportId) { require(reportId > 0 && reportId <= reportCounter, "Report not found"); _; }

    // Links this contract to the deployed ProvenanceRegistry
    // After deployment, Admin must also call ProvenanceRegistry.setRecallManagerAddress(address(this))
    constructor(address _provenanceRegistryAddress) {
        owner = msg.sender;
        provenanceRegistry = IProvenanceRegistry(_provenanceRegistryAddress);
    }

    // Any registered participant files a violation report
    // For HIGH severity, _triggerRecall() called immediately
    // For MEDIUM / LOW severity, reports are stored as Open for Admin review
    function reportViolation(
        string memory batchId,
        ViolationType violationType,
        Severity severity,
        string memory details,
        string memory evidenceIpfsCid
    ) external onlyRegisteredParticipant {}

    // Admin manually escalates an Open MEDIUM or LOW report to a recall
    function triggerRecallManually(string memory batchId, uint256 reportId) external onlyOwner reportExists(reportId) {}

    // Marks batch recalled locally, then cross-calls ProvenanceRegistry.markAsRecalled() to freeze the batch
    function _triggerRecall(string memory batchId, uint256 reportId) internal {}

    // Admin updates status of an Open report after review; cannot revert a Recalled status
    function updateViolationStatus(uint256 reportId, ViolationStatus newStatus) external onlyOwner reportExists(reportId) {}

    // Admin sets acceptable value ranges per violation type for automated threshold checks
    function setThreshold(ViolationType violationType, int256 minValue, int256 maxValue) external onlyOwner {}

    function getViolationReport(uint256 reportId) external view reportExists(reportId) returns (ViolationReport memory) {}

    // Returns all report IDs for a batch - use with getViolationReport() to retrieve full details
    function getViolationsForBatch(string memory batchId) external view returns (uint256[] memory) {}

    function isBatchRecalled(string memory batchId) external view returns (bool) {}

    function getThreshold(ViolationType violationType) external view returns (ThresholdConfig memory) {}
}
