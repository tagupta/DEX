// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import '../node_modules/@openzeppelin/contracts/access/Ownable.sol';
import '../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Wallet is Ownable{

  struct Token{
      bytes32 ticker;
      address tokenAddress;
  }
   bytes32[] public tickerList;
   mapping(bytes32 => Token) public tokenMapping;
   mapping(address => mapping(bytes32 => uint)) public balances;
   
   modifier tokenExist(bytes32 _ticker){
      require(tokenMapping[_ticker].tokenAddress != address(0),"Wallet: token doesn't exist");
      _;
   }

   function addToken(bytes32 _ticker,address _tickerAddress) external onlyOwner{
      require(tokenMapping[_ticker].tokenAddress == address(0),"Wallet: Token already exist");
      tokenMapping[_ticker] = Token(_ticker,_tickerAddress);
      tickerList.push(_ticker);
   } 
   
   function deposit(uint _amount,bytes32 _ticker) external tokenExist(_ticker){
       IERC20 instance = IERC20(tokenMapping[_ticker].tokenAddress);
       require(instance.balanceOf(msg.sender) >= _amount);
       balances[msg.sender][_ticker] += _amount;
       instance.transferFrom(msg.sender, address(this), _amount);
   
   }
   
   function withdraw(uint _amount,bytes32 _ticker)external tokenExist(_ticker){
        require(balances[msg.sender][_ticker] >= _amount,"Wallet: insufficient balance");
        balances[msg.sender][_ticker] -= _amount;
        IERC20(tokenMapping[_ticker].tokenAddress).transfer(msg.sender, _amount);
   }
   
}