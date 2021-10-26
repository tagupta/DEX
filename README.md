# DEX
A simple Decentralized Exchange that allows users to BUY/SELL ERC20 tokens in exchange of ETH.

## Prerequisites
To run this project you need to have **Truffle** installed on your machine. I've intergrated this project by using latest version of truffle and nodejs. In this project I'm using 
**openZeppelin**, a open source solidity library for secure development.

For installation of [openZeppelin](https://docs.openzeppelin.com/contracts/4.x/) use the following command in your terminal - 
``` 
$ npm install @openzeppelin/contracts
```

To assert the statements in test cases, I'm using a library called **truffle assertions**.To install it, use the below command in your terminal -
```
$ npm install truffle-assertions
```

## Overview
Before going into technical details, let's consider the scenario when we go to market to buy goods. We usually follow two approaches. One we buy/sell goods at available prices 
and the other we try to bargain. Here I'm following similar kinda approches for exchange of ERC20 tokens. Have a look at the code to understand the technical details.

***To have a look at Dapp for the same, please click [Dapp for DEX](https://github.com/tagupta/Dapp-for-DEX)***


## Project Setup 
After the initial setup of truffle, open Visual Studio IDE to run the project. Open your working directory and then open your bash terminal to run initial commands - 
 ```
$ npm init
$ truffle init
$ git clone https://github.com/tagupta/DEX.git
 ```

Now open your command prompt terminal to run the below commands in the working directory
```
truffle compile 
truffle develop
migrate
```

Then create contract instances to proceed.To run the test cases, use the following command in your terminal - 
```
truffle test
```

## Enjoy
Play around with the code.
