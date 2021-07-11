const Dex = artifacts.require("Dex");
const Link = artifacts.require("Link");
const truffleAssert = require('truffle-assertions');

contract("Dex - Market Orders",async accounts => {

  it("should throw an error when creating the sell market order without adequate balance",async () =>{
    let dex = await Dex.deployed();

    const balance = await dex.balances(accounts[0],web3.utils.fromUtf8("LINK"));
    assert.equal(balance.toNumber(),0,"Initial LINK balance is not 0");

    await truffleAssert.reverts(dex.createMarketOrder(1,web3.utils.fromUtf8("LINK"),35)); //sell market order
  });

  it("should throw an error when creating the buy market order without adequate balance",async () =>{
    let dex = await Dex.deployed();

    const balance = await dex.balances(accounts[0],web3.utils.fromUtf8("ETH"));
  
    assert.equal(balance.toNumber(),0,"Initial ETH balance is 0");

    await truffleAssert.reverts(dex.createMarketOrder(0,web3.utils.fromUtf8("LINK"),35)); //buy market order
  });

  it("market orders can be submitted even if the order book is empty",async () =>{
     let dex = await Dex.deployed();
     
     await dex.depositETH({value: 100000});
     const buyBook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"),0);

     assert(buyBook.length == 0, "Initially buy book is not empty");
     await truffleAssert.passes(dex.createMarketOrder(0,web3.utils.fromUtf8("LINK"),35)); //buy market order

  });
  it("seller needs to have enough tokens for the trade", async () => {
    let dex = await Dex.deployed();
    let link = await Link.deployed();

    await truffleAssert.reverts(dex.createMarketOrder(1,web3.utils.fromUtf8("LINK"),35)); //sell market order
    
    await link.approve(dex.address,200);
    await dex.addToken(web3.utils.fromUtf8("LINK"),link.address,{from: accounts[0]});
    await dex.deposit(100,web3.utils.fromUtf8("LINK"),{from: accounts[0]}); //account 0 has 100 links in its account

    await truffleAssert.passes(dex.createMarketOrder(1,web3.utils.fromUtf8("LINK"),35)); //100 > 35
  });

  it("market sell orders should be filled until the buy order book is empty or order is 100% filled",async () => {
    let dex = await Dex.deployed();
    await dex.depositETH({value: 1000,from: accounts[1]});
       
    await dex.createLimitOrder(0,web3.utils.fromUtf8("LINK"),10, 9,{from: accounts[1]}); //buy limit order
    await dex.createLimitOrder(0,web3.utils.fromUtf8("LINK"),10, 9,{from: accounts[1]});
    await dex.createLimitOrder(0,web3.utils.fromUtf8("LINK"),10, 9,{from: accounts[1]});
    
    var linkBefore = await dex.balances(accounts[0],web3.utils.fromUtf8("LINK"));

    await truffleAssert.passes(dex.createMarketOrder(1,web3.utils.fromUtf8("LINK"),30,{from: accounts[0]}));//sell market order
    
    const buyList = await dex.getOrderBook(web3.utils.fromUtf8("LINK"),0);
    assert(buyList.length == 0);

    var linkAfter = await dex.balances(accounts[0],web3.utils.fromUtf8("LINK"));

    assert(linkAfter == (linkBefore-30),"token balance of the seller should decrease with the filled amounts");
  
  });

  it("market buy order should be filled until the sell order book is empty or order is 100% filled",async () => {
    let dex = await Dex.deployed();
    let link = await Link.deployed();
    
    //Eth for accounts[0] has already been deposited in test case 3 - 100000

    const sellOrderBook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"),1);
    assert(sellOrderBook.length == 0,"Keep sell order book empty before starting the test");

    await link.transfer(accounts[1],50); //50 Link
    await link.transfer(accounts[2],50); //50 Link
    await link.transfer(accounts[3],50); //50 Link

    // await link.mintTokens(accounts[3],2000);
    await link.approve(dex.address,50,{from: accounts[1]});
    await link.approve(dex.address,50,{from: accounts[2]});
    await link.approve(dex.address,50,{from: accounts[3]});

    await dex.deposit(50,web3.utils.fromUtf8("LINK"),{from: accounts[1]});
    await dex.deposit(50,web3.utils.fromUtf8("LINK"),{from: accounts[2]});
    await dex.deposit(50,web3.utils.fromUtf8("LINK"),{from: accounts[3]});


    await dex.createLimitOrder(1,web3.utils.fromUtf8("LINK"),5, 300,{from: accounts[1]});//sell limit order
    await dex.createLimitOrder(1,web3.utils.fromUtf8("LINK"),5, 400,{from: accounts[2]});//sell limit order
    await dex.createLimitOrder(1,web3.utils.fromUtf8("LINK"),5, 500,{from: accounts[3]});//sell limit order
    
    var sellList = await dex.getOrderBook(web3.utils.fromUtf8("LINK"),1);

    var oldBalance = await dex.balances(accounts[0],web3.utils.fromUtf8("ETH"));

    await truffleAssert.passes(dex.createMarketOrder(0,web3.utils.fromUtf8("LINK"),10));//buy market order

    sellList = await dex.getOrderBook(web3.utils.fromUtf8("LINK"),1);
    assert(sellList.length == 1);
    
    var newBalance = await dex.balances(accounts[0],web3.utils.fromUtf8("ETH"));
   
    assert(newBalance == (oldBalance - (5*300 + 5*400)),"ETH balance of the buyer should decrease with the filled amount");
  });

});