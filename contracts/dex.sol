// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import './wallet.sol';
import '../node_modules/@openzeppelin/contracts/utils/Counters.sol';

contract Dex is Wallet{

    using Counters for Counters.Counter; 
    
    enum Side{
        BUY,
        SELL
    }

   struct Order{
       uint id;
       address trader;
       Side side;
       bytes32 ticker;
       uint amount;
       uint price;
   }
   
   mapping(bytes32 => mapping(uint => Order[]))public orderBook;
   Counters.Counter private _counterIds;

   //getOrderBook(bytes32("LINK"),Side.BUY)
   function getOrderBook(bytes32 _ticker,Side side) public view returns(Order[] memory){
       return orderBook[_ticker][uint(side)];
   }
 
   function createLimitOrder(Side side,bytes32 ticker,uint amount, uint price) public{
      if(side == Side.BUY){
          require(balances[msg.sender]["ETH"] >= amount * price,'Cost exdeeds the ETH balance');
      }
      else if(side == Side.SELL){
          require(balances[msg.sender][ticker] >= amount,'Insufficient tokens to sell');
      }

        uint256 newCounterId = _counterIds.current();
        Order[] storage orders = orderBook[ticker][uint(side)];
        orders.push(Order(newCounterId,msg.sender,side,ticker,amount,price));
         
        uint j =  orders.length > 0 ? orders.length-1 : 0;
         if(side == Side.BUY){
            for( ; j > 0 ; j--){
                 if(orders[j].price > orders[j-1].price){
                    Order memory temp = orders[j];
                    orders[j] = orders[j-1];
                    orders[j-1] = temp;
                }
                else{
                    break;
                }
            }
         }
         else if(side == Side.SELL){
            for(; j > 0 ; j--){
                 if(orders[j].price < orders[j-1].price){
                    Order memory temp = orders[j];
                    orders[j] = orders[j-1];
                    orders[j-1] = temp;
                }
                else{
                    break;
                }
            }
         }
         _counterIds.increment();
   }

    
}