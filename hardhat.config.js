import "@nomicfoundation/hardhat-toolbox";

/** @type import('hardhat/config').HardhatUserConfig */
export const solidity = "0.8.20";
export const networks = {
    // Local Hardhat development network (default)
    localhost: {
        url: "http://127.0.0.1:8545",
        chainId: 31337,
    },
};