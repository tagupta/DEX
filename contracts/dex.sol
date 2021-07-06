// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import './wallet.sol';

contract Dex is Wallet{
    
    enum Side{
        BUY,
        SELL
    }

   struct Order{
       uint id;
       address trader;
       bool buyOrder;
       bytes32 ticker;
       uint amount;
       uint price;
   }
   
   mapping(bytes32 => mapping(uint => Order[]))public orderBook;
   
   //getOrderBook(bytes32("LINK"),Side.BUY)
   function getOrderBook(bytes32 _ticker,Side side) public view returns(Order[] memory){
       return orderBook[_ticker][uint(side)];
   }
}