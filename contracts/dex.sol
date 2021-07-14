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
   struct MarketBuyOrder{
       address trader;
       bytes32 ticker;
       uint amount;
   }

   mapping(bytes32 => mapping(uint => Order[]))public orderBook;
   MarketBuyOrder[] public marketOrders;
   Counters.Counter private _counterIds;

   //getOrderBook(bytes32("LINK"),Side.BUY)
   function getOrderBook(bytes32 _ticker,Side side) public view returns(Order[] memory){
       return orderBook[_ticker][uint(side)];
   }
  
  function getPendingBuyMktOrders() public view returns(MarketBuyOrder[] memory){
      return marketOrders;
  }
   function createLimitOrder(Side side,bytes32 ticker,uint amount, uint price) public{
      if(side == Side.BUY){
          require(balances[_msgSender()]["ETH"] >= amount * price,'Cost exdeeds the ETH balance');
      }
      else if(side == Side.SELL){
          require(balances[_msgSender()][ticker] >= amount,'Insufficient tokens to sell');
      }

        uint256 newCounterId = _counterIds.current();
        Order[] storage orders = orderBook[ticker][uint(side)];
        orders.push(Order(newCounterId,_msgSender(),side,ticker,amount,price));
         
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
         //handling unsettled market buy orders
         if(marketOrders.length > 0 && orderBook[marketOrders[0].ticker][1].length > 0 ){
            MarketBuyOrder memory temp = marketOrders[0];
            deleteMarketOrder(marketOrders); //for FCFS structure
            createMarketOrder(Side.BUY,temp.ticker,temp.amount,temp.trader); 
        }
   }
   
   function settleTrade(Order memory temp, uint amt, address seller, address buyer,bytes32 _ticker) private{
        uint cost = temp.price * amt;
        balances[seller]["ETH"] += cost; 
        balances[seller][_ticker] -= amt; 
        balances[buyer]["ETH"] -= cost; 
        balances[buyer][_ticker] += amt; 
   }
   
   function deleteMarketOrder(MarketBuyOrder[] storage orders) private{
       for(uint j = 0 ; j < orders.length-1 ; j++){
                orders[j] = orders[j+1];
            }
      orders.pop(); 
   }
   function deleteFilledOrder(Order[] storage orders) private{
      for(uint j = 0 ; j < orders.length-1 ; j++){
                orders[j] = orders[j+1];
            }
      orders.pop(); 
   }

   function createMarketOrder(Side side, bytes32 ticker, uint amount, address trader) public {

     if(Side.SELL == side){
        require(amount <= balances[trader][ticker],"Insufficent tokens to sell");
        Order[] storage orders = orderBook[ticker][0]; //Buy order book

        while(amount > 0 && orders.length > 0){
         if(amount >= orders[0].amount){
             amount -= orders[0].amount; 
             settleTrade(orders[0],orders[0].amount, trader,orders[0].trader,ticker);
             orders[0].amount = 0;
             deleteFilledOrder(orders);
         }
         else if(amount < orders[0].amount){
             orders[0].amount -= amount;
             settleTrade(orders[0],amount,trader,orders[0].trader,ticker);
             amount = 0;
         }
       }
      }
     else if(Side.BUY == side){

        Order[] storage orders = orderBook[ticker][1]; //limit order sell book 
        
        if(orders.length <= 0){
            marketOrders.push(MarketBuyOrder(trader,ticker,amount));
        }
        else {
            while(amount > 0 && orders.length > 0){
            if(amount >= orders[0].amount){
               require(balances[trader]["ETH"] >= orders[0].amount * orders[0].price,"Insufficient ETH in your wallet");
               amount -= orders[0].amount;
               settleTrade(orders[0],orders[0].amount, orders[0].trader,trader,ticker);
               orders[0].amount = 0;
               deleteFilledOrder(orders);
            }
            else if(amount < orders[0].amount){
                require(balances[trader]["ETH"] >= amount * orders[0].price,"Insufficient ETH in your wallet");
                orders[0].amount -= amount;
                settleTrade(orders[0],amount,orders[0].trader,trader,ticker);
                amount = 0;
            }
          } 
        }
      }
   }  
}