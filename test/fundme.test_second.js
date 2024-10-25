// const { ethers, deployments } = require ("hardhat" )
// const { assert} = require ("chai")

// describe("test fundme contract", async function() {
//     let fundMe
//     let firstAccount
//     let secondAccount
//     beforeEach(async function() {
//         await deployments.fixture(["all"])
//         firstAccount = (await getNamedAccounts()).firstAccount
//         secondAccount = (await getNamedAccounts()).secondAccount
//         const fundMeDeployment = await deployments.get("FundMe")
//         fundMe = await ethers.getContractAt("FundMe", fundMeDeployment.address)
//         //fundMeSecondAccount = await ethers.getContract("FundMe", secondAccount)
//     })
//     it("test if the owner is msg,sender", async function() {
//         await fundMe.waitForDeployment ()
//         assert.equal((await fundMe.owner()), firstAccount)
//     })
//     it("test if the dätafeed is assigned correctly", async function(){
//         await fundMe.waitForDeployment()
//         assert.equal( (await fundMe.dataFeed()), "0x694AA1769357215DE4FAC081bf1f309aDC325306")
//     })
// })