# Blockchain-Based Supply Chain Provenance System for Food Safety Tracking

**CSE 540: Engineering Blockchain Applications Course Project**  
**Team Members:**  
Aviroop Nandy, Vatsal Nirmal, Maninderjit Singh Bhullar, Khalid Alamri, Vaibhavee Ketankumar Panchal

---

## Project Description

This project implements a blockchain-based food supply chain provenance system on Ethereum using Solidity smart contracts. Every participant in the food supply chain - farmers, processors, logistics providers, retailers, and regulators - can record, verify, and audit the complete journey of a food product batch from farm to consumer.

The system uses two smart contracts. `ProvenanceRegistry` records every custody transfer event as an immutable on-chain audit trail linked to a unique Batch ID. `AlertRecallManager` monitors safety violations and triggers product recalls, automatically freezing affected batches on-chain when a high-severity violation is reported. Supporting documents such as inspection reports and sensor logs are stored off-chain on IPFS; only the content hash is recorded on-chain.

---

## Dependencies

| Tool | Purpose |  
| --- | --- |  
| Node.js >= 18.x | JavaScript runtime |  
| Hardhat | Ethereum development environment - compile, test, deploy |  
| @nomicfoundation/hardhat-toolbox | Hardhat plugins bundle |  
| Ethers.js | Blockchain interaction library (frontend) |  
| MetaMask | Browser wallet for interacting with the frontend |  
| Pinata (optional) | Hosted IPFS pinning for off-chain file storage |

Install dependencies:

bash
npm install


---

## Setup and Deployment

### 1. Compile the contracts

bash
npx hardhat compile


### 2. Start a local blockchain

bash
npx hardhat node


### 3. Deploy to local network

bash
npx hardhat run scripts/deploy.js --network localhost


Note the two contract addresses printed in the terminal and update them in frontend/index.html.

### 4. Run the frontend

Open frontend/index.html in a browser. Connect MetaMask to the Hardhat localhost network (port 8545, Chain ID 31337).