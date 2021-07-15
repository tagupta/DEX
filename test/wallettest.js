const Dex = artifacts.require("Dex");
const Link = artifacts.require("Link");
const truffleAssert = require('truffle-assertions');

contract("Dex",async accounts =>{
 it("should only be possible for owner to add Link", async () => {    
  let dex = await Dex.deployed();
  let link = await Link.deployed();
  await truffleAssert.passes(dex.addToken(web3.utils.fromUtf8("LINK"),link.address,{from: accounts[0]}));
  await truffleAssert.reverts(dex.addToken(web3.utils.fromUtf8("LINK"),link.address,{from: accounts[1]}));

 });

 it("should handle deposit correctly", async () => {    
    let dex = await Dex.deployed();
    let link = await Link.deployed();
    await link.approve(dex.address,200);
    await dex.deposit(100,web3.utils.fromUtf8("LINK"));
    let balance = await dex.balances(accounts[0],web3.utils.fromUtf8("LINK"));
    assert.equal(balance,100);
  
   });

   it("should handle faulty withdrwals correctly", async () => {    
    let dex = await Dex.deployed();
    await truffleAssert.reverts(dex.withdraw(550,web3.utils.fromUtf8("LINK")));
   });

   it("should handle correct withdrwals correctly", async () => {    
    let dex = await Dex.deployed();
    let oldBalance = await dex.balances(accounts[0],web3.utils.fromUtf8("LINK"));
    await dex.withdraw(50,web3.utils.fromUtf8("LINK"));
    let newbalance = await dex.balances(accounts[0],web3.utils.fromUtf8("LINK"));
    assert.equal(newbalance,oldBalance-50);
  
   });

});