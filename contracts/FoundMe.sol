// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//预言机通过调用外部 API、物联网设备或数据库等数据源，将实时数据引入区块链，
//并通过主动推送、请求-响应、事件触发等机制实现数据更新。
//去中心化的预言机网络能够通过多方验证、数据聚合和共识机制，确保数据的准确性、可靠性和安全性，
//从而支持各种去中心化应用（如 DeFi、保险、供应链等）的顺利运行。
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

// EOA 账户 是用户通过钱包创建的账户，无法直接在 Solidity 中定义，它们是以太坊网络上的外部账户，代表用户或实体。
// 合约账户 是通过部署智能合约生成的，在 Solidity 中通过编写智能合约代码定义，当合约部署后会生成一个唯一的合约地址。

//1、创建收款函数(让函数有收款功能需要payable)
//2、记录投资人并查看
//3、锁定期限内，达到目标值，生产商可以提款
//4、在锁定期内，没有达到目标值，投资人在锁定期后可以退款
contract FundMe {
    mapping (address => uint256) public fundersToAmount;

    AggregatorV3Interface internal dataFeed;
    //设置最小额度，方便管理
    uint256 constant MINIMUM_VALUE = 100 * 10 ** 18 ;//单位是USD

    //设置筹集目标值
    uint256 constant TARGET = 1000 * 10 ** 18;

    //合约所有者
    address public owner;

    //部署的时间，设计锁定期限，没有date类、时间戳等
    uint256 deploymentTimesstamp;
    //锁定时间
    uint256 lockTime;

    //申明ERC20的地址
    address erc20Addr;

    bool public  getFundSuccess = false;

    modifier windowClosed() { 
        require(block.timestamp>=deploymentTimesstamp+lockTime,"window is not close");
        _;
    }
    modifier onlyOwner(){
        require(msg.sender == owner,"this function can only be called by owner");
        _;
    }

    constructor(uint256 _lockTime) {
        //sepolia testnet
        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
        owner = msg.sender;
        deploymentTimesstamp = block.timestamp;
        lockTime = _lockTime;
    }

    function setFunderToAmount(address funder,uint256 amountToUpdate) external {
        require(msg.sender == erc20Addr,"You do not have permission to call this function");
        fundersToAmount[funder] = amountToUpdate;
    }

    function setErc20Addr(address _erc20Addr) public onlyOwner{
        erc20Addr = _erc20Addr;
    }

    //如果以美元USD来计价的话，需要知道现在ETH的价格，需要引入预言机----链上和链下数据的交互
    function fund() external  payable {
        require(convertEthToUsd(msg.value)>= MINIMUM_VALUE,"Send more ETH"); //如果不满足条件会被revert掉
        require(block.timestamp<deploymentTimesstamp+lockTime,"window is close");
        fundersToAmount[msg.sender] = msg.value;
    }

    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    function convertEthToUsd(uint256 ethAmount) internal view  returns(uint256){
        uint256 ethPrice =uint256(getChainlinkDataFeedLatestAnswer());
        return  ethAmount * ethPrice /(10**8);
    }

    function transferOwnerShip(address newOwner) public  onlyOwner{ //设置捐赠的时候，哪一步把所有权转到发起人好？
        //require(msg.sender == owner,"this function can only be called by owner");
        owner = newOwner;
    }

    function getFund() external windowClosed onlyOwner{
        require(convertEthToUsd(address(this).balance) >= TARGET,"Target is not reacherd");
        //require(block.timestamp>=deploymentTimesstamp+lockTime,"window is not close");
        //require(msg.sender == owner ,"this function can only be called by owner");
        //有三个转账函数
        //1、transfer:transfer ETH and revert if tx failed（是最简单、最常用的方法）
        
        //将智能合约中当前持有的全部以太币余额转账给当前的调用者（msg.sender）。
        //常见的使用场景是当合约完成某个操作后，将合约中的资金归还给用户，或是执行某种退款逻辑
        //payable 关键字表示某个地址可以接收以太币。Solidity 中，地址有两种类型：address 和 address payable，其中 address payable 可以进行资金转账。
        //通过payable(msg.sender) 将 msg.sender 转换为 payable 类型，使得该地址能够接收以太币。
        //payable(msg.sender).transfer(address(this).balance);
        
        //2、send:transfer ETH and return false if failed,send、transfer、call是否会消耗gas
        //bool success = payable(msg.sender).send(address(this).balance);
        //require(success,"tx failed");

        //3、call:以太坊官方推荐的，transfer ETH with data return value of function and bool
        //aadr.call("fund") //调用fund函数
        //addr.call{value: value}("fund") //捐款多少
        (bool success, ) = payable (msg.sender).call{value:address(this).balance}("");
        require(success,"tx failed");
        //把账户归零
        fundersToAmount[msg.sender]=0;
        getFundSuccess = true;


        //详细对比：send、transfer、call是否会消耗gas
        //操作方式	成功时的gas 消耗   失败时的 gas 消耗	错误处理机制
        //send	   固定 2300 gas	固定 2300 gas	    返回 false，需要手动处理
        //transfer 固定 2300 gas	固定 2300 gas	    抛出异常，自动回退
        //call	   可自定义 gas	     消耗所有提供的 gas	   返回 false，需要手动处理
        //结论：
        // send 和 transfer 操作失败时，只会消耗固定的 2300 gas。
        // call 操作失败时，会消耗掉你为其提供的所有 gas，因此相对来说风险更大，需要仔细处理返回值以避免大量 gas 损失。

        // 全方位对比
        // 安全性: transfer > send > call，安全性上transfer是最高的，因为它会在失败时回滚。
        // 灵活性: call > send > transfer，灵活性上call提供了最高的灵活性，可以调用合约的函数，定制化程度高。
        // 推荐使用：目前社区推荐使用call，因为它灵活性和兼容性，但同时需要确保正确的错误处理机制。
        // Gas消耗：transfer和send虽然安全性较高由于其限制gas消耗到2300，但这限制了它们的灵活性和适应性，
        // 比方说不适合在需要一些复杂计算或多步操作的场合。而call虽提供极高灵活性和功能强大的控制，
        // 但同时带来了更高的风险，需要开发者手动管理这些风险。
    }

    function refund() external windowClosed {
        require(convertEthToUsd(address(this).balance) < TARGET,"Target is reacherd");
        require(fundersToAmount[msg.sender]!=0,"there is no fund for you");
        //require(block.timestamp>=deploymentTimesstamp+lockTime,"window is not close");
        //require(fundersToAmount[msg.sender]<=);
        (bool success,) = payable (msg.sender).call{value:fundersToAmount[msg.sender]}("");
        require(success,"tx failed");
        //把账户归零
        fundersToAmount[msg.sender]=0;
    }
        // 个人理解：Solidity 编程可以理解为一种 面向多用户、多角色 的编程模式。
        // 1. 多用户（Multi-User）编程
        // 在区块链上，每个地址代表一个用户或智能合约。不同用户通过地址相互交互，而 Solidity 智能合约允许多个用户与合约交互。
        // msg.sender: Solidity 合约中的 msg.sender 代表调用合约的用户地址，智能合约函数的行为通常会根据 msg.sender 的不同来决定。
        // 去中心化的用户交互：智能合约是公开的，任何人都可以调用它的公共函数。因此，合约的开发必须考虑到多个用户对同一个合约的并发访问，以及如何根据不同用户执行不同逻辑。
        // 权限管理：不同用户可能具有不同的权限，合约开发通常需要为用户设置角色和权限，控制用户能够调用哪些函数。例如，某些函数可能只允许合约的所有者或管理员执行。

        //2. 多角色（Multi-Role）编程
        // Solidity 合约经常需要区分不同角色的权限，并根据用户的角色来执行不同的操作。
        // 这可以通过角色管理、访问控制等机制来实现。角色的概念允许开发者设计复杂的权限体系，使得不同用户能够执行不同的操作。

        // 基于角色的访问控制：可以使用像 OpenZeppelin 提供的 AccessControl 模块来定义和管理不同的角色。例如，一个去中心化应用（DApp）中可能存在多个角色：
        // 管理员角色：能够管理其他用户的权限。
        // 普通用户角色：只能使用合约的某些功能。
        // 特殊角色：例如拍卖合约中的竞拍者、卖家和买家，或者众筹合约中的项目发起者和投资者。

        //3. 角色和用户的动态交互
        // 智能合约在区块链上是动态的，用户和角色的关系可以随时发生变化。
        // 合约中可以编写逻辑，允许角色动态变更。例如，一个普通用户可以在满足特定条件后成为管理员，
        // 或一个竞拍者在竞拍成功后成为拍卖赢家。

        // 4. 应用场景
        // 以下是一些应用场景，展现了 Solidity 如何支持多用户、多角色的编程模式：

        // 投票系统：区分投票者、管理员、候选人等不同角色。投票者可以投票，管理员可以管理候选人和投票过程。
        // 众筹平台：有项目发起人、投资者等角色。投资者可以根据项目状态选择投资，发起人可以管理项目资金使用。
        // 去中心化交易所：用户可以有买家、卖家等不同角色，不同的角色具有不同的权限和行为。
        
        // 总结
        // 在 Solidity 编程中，由于区块链是去中心化的环境，任何用户都可以与智能合约交互，
        // 因此可以认为 Solidity 编程是面向多用户的。而通过访问控制和角色管理机制，
        //合约中能够区分不同用户的权限和行为，使其成为面向多角色编程的一种模式。
        //因此，理解 Solidity 编程时，可以将其视为多用户、多角色的交互编程模式。
}