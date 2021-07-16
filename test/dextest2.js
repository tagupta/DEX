const Dex = artifacts.require("Dex");
const Link = artifacts.require("Link");
const truffleAssert = require('truffle-assertions');

contract("Dex - Market Orders",async accounts => {

  it("buy market orders can be submitted even if the sell order book is empty",async () =>{
    let dex = await Dex.deployed();
    await dex.depositETH({value: 1000,from: accounts[0]});
    const sellBook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"),1);
    assert(sellBook.length == 0, "Initially sell book is not empty");
    await truffleAssert.passes(dex.createMarketOrder(0,web3.utils.fromUtf8("LINK"),35)); //buy market order
    const pendingBuyMarketOrders = await dex.getMarketOrderBook(web3.utils.fromUtf8("LINK"),0);
   
    assert(pendingBuyMarketOrders.length == 1,"Problem with pending buy market order");
 });

  it("should throw an error when creating the sell market order without adequate balance",async () =>{
    let dex = await Dex.deployed();

    const balance = await dex.getBalance(web3.utils.fromUtf8("LINK"));
    assert.equal(balance.toNumber(),0,"Initial LINK balance is not 0");
    await truffleAssert.reverts(dex.createMarketOrder(1,web3.utils.fromUtf8("LINK"),35)); //sell market order
  });

  it("should not throw an error when creating the sell market order with adequate balance",async () =>{
    let dex = await Dex.deployed();
    let link = await Link.deployed();

    await link.approve(dex.address,200);
    await dex.addToken(web3.utils.fromUtf8("LINK"),link.address,{from: accounts[0]});
    await dex.deposit(100,web3.utils.fromUtf8("LINK"),{from: accounts[0]});

    await truffleAssert.passes(dex.createMarketOrder(1,web3.utils.fromUtf8("LINK"),20));

    const pendingSellMarketOrders = await dex.getMarketOrderBook(web3.utils.fromUtf8("LINK"),1);
    assert(pendingSellMarketOrders.length == 1,"Problem with pending sell market order");
  });
  
  it("dealing with pending buy market order on creation of sell Limit order",async () =>{
    let dex = await Dex.deployed();
    let link = await Link.deployed();
    
    await link.transfer(accounts[1],50);
    await link.approve(dex.address,50,{from: accounts[1]});
    await dex.deposit(50,web3.utils.fromUtf8("LINK"),{from: accounts[1]});
    
    const oldLink =  await dex.getBalance(web3.utils.fromUtf8("LINK"));
    await dex.createLimitOrder(1,web3.utils.fromUtf8("LINK"),5, 10,{from: accounts[1]});
    const buyMarketBook = await dex.getMarketOrderBook(web3.utils.fromUtf8("LINK"),0);
    const sellLimitBook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"),1);
    const newLink =  await dex.getBalance(web3.utils.fromUtf8("LINK"));
   
    assert(buyMarketBook.length == 1,'Problem with pending buy market order');
    assert(sellLimitBook.length == 0,'Problem with sell limit order');
    assert(newLink.toNumber() == oldLink.toNumber()+5,'Problem with calculation');
  });
  
  it("buy market order should get fulfilled on sufficient amount",async()=>{
    let dex = await Dex.deployed();

    const oldLink = await dex.getBalance(web3.utils.fromUtf8("LINK"));
    await truffleAssert.passes(dex.createLimitOrder(1,web3.utils.fromUtf8("LINK"),40, 10,{from: accounts[1]}));

    const buyMarketBook = await dex.getMarketOrderBook(web3.utils.fromUtf8("LINK"),0);
    const sellLimitBook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"),1);
    const newLink = await dex.getBalance(web3.utils.fromUtf8("LINK"));
    
    assert(buyMarketBook.length == 0,'Problem with pending buy market order');
    assert(sellLimitBook.length == 1,'Problem with sell limit order');
    assert(newLink.toNumber() == oldLink.toNumber()+30,'Problem with calculation');
  });
 
  it("direct call to create market order",async ()=> {
    let dex = await Dex.deployed();

    const oldLink = await dex.getBalance(web3.utils.fromUtf8("LINK"));
    await truffleAssert.passes(dex.createMarketOrder(0,web3.utils.fromUtf8("LINK"),2));

    const buyMarketBook = await dex.getMarketOrderBook(web3.utils.fromUtf8("LINK"),0);
    const sellLimitBook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"),1);
    const newLink = await dex.getBalance(web3.utils.fromUtf8("LINK"));

    assert(buyMarketBook.length == 0,'Problem with pending buy market order');
    assert(sellLimitBook.length == 1,'Problem with sell limit order');
    assert(newLink.toNumber() == oldLink.toNumber()+2,'Problem with calculation');
  });

  it("half filled buy market orders should be pushed into the pending list of buy market orders",async ()=>{
    let dex = await Dex.deployed();
    
    const oldLink = await dex.getBalance(web3.utils.fromUtf8("LINK"));
    await truffleAssert.passes(dex.createMarketOrder(0,web3.utils.fromUtf8("LINK"),18));
    
    const buyMarketBook = await dex.getMarketOrderBook(web3.utils.fromUtf8("LINK"),0);
    const sellLimitBook = await dex.getOrderBook(web3.utils.fromUtf8("LINK"),1);
    const newLink = await dex.getBalance(web3.utils.fromUtf8("LINK"));

    assert(buyMarketBook.length == 1,'Problem with pending buy market order');
    assert(sellLimitBook.length == 0,'Problem with sell limit order');
    assert(newLink.toNumber() == oldLink.toNumber()+8,'Problem with calculation');
    
  });

});