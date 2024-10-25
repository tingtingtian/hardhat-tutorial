const DECIMAL = 8
const INITIAL_PRICE = 200000000000

const developmentChains = ["hardhat", "local"]
const LOCK_TIME = 180

const CONFIRMATIONS = 5

const networkConfig = {
    11155111: {
        ethUsdDataFeed: "0x694AA1769357215DE4FAC081bf1f309aDC325306", // kovan
    },
    97: {
        ethUsdDataFeed: "0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526", // bsc testnet
    },
}

module.exports = {
    DECIMAL,
    INITIAL_PRICE,
    developmentChains,
    LOCK_TIME,
    networkConfig,
    CONFIRMATIONS,
}