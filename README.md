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