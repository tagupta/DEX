const Dex = artifacts.require("Dex");
const Link = artifacts.require("Link");
const truffleAssert = require('truffle-assertions');

contract.skip("Dex - Order Book",async accounts =>{
  it("deposited ETH must be more than the buy order value", async ()=>{
    let dex = await Dex.deployed();

    await truffleAssert.reverts(dex.createLimitOrder(0,web3.utils.fromUtf8("LINK"),10,2,{from: accounts[0]}));
    await dex.depositETH({value: 90});
    await truffleAssert.passes(dex.createLimitOrder(0,web3.utils.fromUtf8("LINK"),10,2,{from: accounts[0]}));

  });

  it("should have enough tokens deposited for sell",async () =>{
    let dex = await Dex.deployed();
    let link = await Link.deployed();

    await truffleAssert.reverts(dex.createLimitOrder(1,web3.utils.fromUtf8("LINK"),7,2,{from: accounts[0]}));

    await link.approve(dex.address,200);
    dex.addToken(web3.utils.fromUtf8("LINK"),link.address,{from: accounts[0]});
    await dex.deposit(100,web3.utils.fromUtf8("LINK"));

    await truffleAssert.passes(dex.createLimitOrder(1,web3.utils.fromUtf8("LINK"),7,2,{from: accounts[0]}));
  });

  it("buy order book should be in descending order by price",async ()=>{
       let dex = await Dex.deployed();

       await dex.depositETH({value: 400});

       await dex.createLimitOrder(0,web3.utils.fromUtf8("LINK"),1, 9);
       await dex.createLimitOrder(0,web3.utils.fromUtf8("LINK"),1, 13);
       await dex.createLimitOrder(0,web3.utils.fromUtf8("LINK"),1, 10);

       const buyList = await dex.getOrderBook(web3.utils.fromUtf8("LINK"),0);
       assert(buyList.length > 0,"Buy order book should not be empty");
       buyList.every(function (x, i) {
            assert(i === 0 || x.price <= buyList[i - 1].price,"Buy order book not in correct order");
        });

  });

  it("sell order book should be in ascending order by price",async ()=>{
    let dex = await Dex.deployed();
    let link = await Link.deployed();

    await link.approve(dex.address,1000);
    await dex.deposit(500,web3.utils.fromUtf8("LINK"));

    await dex.createLimitOrder(1,web3.utils.fromUtf8("LINK"),1, 13);
    await dex.createLimitOrder(1,web3.utils.fromUtf8("LINK"),1, 10);
    await dex.createLimitOrder(1,web3.utils.fromUtf8("LINK"),1, 9);

    const sellList = await dex.getOrderBook(web3.utils.fromUtf8("LINK"),1);
    assert(sellList.length > 0,"Sell order book should not be empty");
    sellList.every(function (x, i) {
        assert(i === 0 || x.price >= sellList[i - 1].price,"Sell order book not in correct order");
    });

});
}); 