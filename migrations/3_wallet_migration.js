const Wallet = artifacts.require("Wallet");
const Link = artifacts.require("Link");

module.exports = async function (deployer,network,accounts) {
  await deployer.deploy(Wallet);
  let wallet = await Wallet.deployed();
  let link = await Link.deployed();
  await wallet.addToken(web3.utils.fromUtf8("LINK"),link.address);
  await link.approve(wallet.address,200);
  await  wallet.deposit(100,web3.utils.fromUtf8("LINK"));
  let balance = await wallet.balances(accounts[0],web3.utils.fromUtf8("LINK"));
  console.log(balance);
};
