const {DECIMAL,INITIAL_PRICE,developmentChains} = require("../helper-hardhat-config")
module.exports= async({getNamedAccounts, deployments}) => {

    if (developmentChains.includes(network.name)) {
        const {firstAccount} = await getNamedAccounts()
        const {deploy} = deployments
        
        await deploy("MockV3Aggregator", {
            from: firstAccount,
            log: true,
            args: [DECIMAL, INITIAL_PRICE] // 1 ETH = 2000 USD
        })
    }else{
        console.log("You are not in a development chain")
    }
    


}

module.exports.tags = ["all", "mock"]