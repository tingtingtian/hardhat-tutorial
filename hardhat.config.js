require("@nomicfoundation/hardhat-toolbox");
/** @type import('hardhat/config').HardhatUserConfig */
//require("dotenv").config();//引入环境变量,让敏感信息不暴露在代码中,从.env里面获取 npm install --save-dev dotenv

//@chainlink/env-enc    npm install --save-dev @chainlink/env-enc 用于敏感信息加密
require("@chainlink/env-enc").config();

//@nomicfoundation/hardhat-verify  npm install --save-dev @nomicfoundation/hardhat-verify
//require("@nomicfoundation/hardhat-verify"); //用于合约验证,需要配置验证器,需要合约地址,需要合约ABI,需要验证器地址,需要验证器私钥
require("./tasks")

const SEPOLIA_URL = process.env.SEPOLIA_URL;
const PRIVARE_KEY = process.env.PRIVARE_KEY;
const PRIVARE_KEY_1 = process.env.PRIVARE_KEY_1;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
module.exports = {
  //defaultNetwork: "hardhat", //可以不用写,默认配置
  solidity: "0.8.27",
  networks: {
    sepolia: {
      url: SEPOLIA_URL, //支持商有Alchemy、Infura、QuickNode等
      accounts: [PRIVARE_KEY,PRIVARE_KEY_1], //私钥,支持多个私钥,数组形式
      chainId: 11155111,
    }
  },
  etherscan: {
    apiKey: {
      sepolia: ETHERSCAN_API_KEY
    }
  }
};
