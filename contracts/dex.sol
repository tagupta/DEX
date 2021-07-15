// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import './wallet.sol';
import '../node_modules/@openzeppelin/contracts/utils/Counters.sol';

// add market type to order attrbiute
//
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
       bool filled;
   }

    struct marketOrder{
       uint id;
       address trader;
       Side side;
       bytes32 ticker;
       uint amount;
       bool filled;
   }


   mapping(bytes32 => mapping(uint => Order[]))public orderBook;
   mapping(bytes32 => mapping(uint => marketOrder[]))public marketOrderBook;
   Counters.Counter private _counterIds;
   Counters.Counter private _marketIds;

   function getBalance(bytes32 ticker) public view returns (uint256) {
       return balances[msg.sender][ticker];
   }
  
   function getOrderBook(bytes32 _ticker,Side side) public view returns(Order[] memory){
       return orderBook[_ticker][uint(side)];
   }

   function getMarketOrderBook(bytes32 _ticker,Side side) public view returns(marketOrder[] memory){
       return marketOrderBook[_ticker][uint(side)];
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
        orders.push(Order(newCounterId,msg.sender,side,ticker,amount,price, false));
         
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
            settleOrder(orders, marketOrderBook[ticker][1], ticker, side);
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
            settleOrder(orders, marketOrderBook[ticker][0], ticker, side);
         }
         _counterIds.increment();
         
        }
   }
   

   function createMarketOrder(Side side, bytes32 ticker, uint amount) public {
    
        if(Side.SELL == side){
            require(amount <= balances[msg.sender][ticker],"Insufficent tokens to sell");
        
            uint256 newCounterId = _marketIds.current();
            marketOrder[] storage marketOrders = marketOrderBook[ticker][1];
            Order[] storage orders = orderBook[ticker][0];
            marketOrders.push(marketOrder(newCounterId,msg.sender,side,ticker,amount, false));

            settleOrder(orderBook[ticker][0], marketOrderBook[ticker][1], ticker, side);
        }
        else if(Side.BUY == side){
            
            uint256 newCounterId = _marketIds.current();
            marketOrder[] storage marketOrders = marketOrderBook[ticker][0];
            Order[] storage orders = orderBook[ticker][1]; 
            marketOrders.push(marketOrder(newCounterId,msg.sender,side,ticker,amount, false));

            settleOrder(orderBook[ticker][1], marketOrderBook[ticker][0], ticker, side);
        }
         _marketIds.increment();
   }

   function settleOrder(Order[] storage orders, marketOrder[] storage marketOrders, bytes32 ticker, Side side) private {

       while(marketOrders.length > 0 && orders.length > 0){
           uint i = 0;
           if (side == Side.BUY) {
                require(balances[msg.sender]["ETH"] > orders[i].price * orders[i].amount);
            }

            if (marketOrders.length == 0 || orders.length == 0) {
                break;
            }
           
            if (marketOrders[0].amount > orders[0].amount) {
                marketOrders[0].amount = marketOrders[0].amount - orders[0].amount;
                
                orders[0].filled = true;
            }
            else if (marketOrders[0].amount == orders[0].amount) {
                marketOrders[0].amount -= orders[0].amount;
                orders[0].filled = true;
                marketOrders[0].filled = true;
            }
            else {
                orders[0].amount -= marketOrders[0].amount;
                marketOrders[0].filled = true;
            }
            
            if (side == Side.BUY) {
                settleTrade(orders[0], orders[0].amount, orders[0].trader, msg.sender, ticker);
            }
            else {
                settleTrade(orders[0], orders[0].amount, msg.sender, orders[0].trader, ticker);
            }
        
            deleteOrders(orders, marketOrders);
            i++;
     }

   }

   function deleteOrders(Order[] storage orders, marketOrder[] storage marketOrders) private {

    if (orders[0].filled) {
            
        for (uint j = 0; j < orders.length-1; j++){
            orders[j] = orders[j+1];
        }    
        orders.pop();
    }

    if (marketOrders[0].filled) {
               
        for (uint j = 0; j < marketOrders.length-1; j++){
            marketOrders[j] = marketOrders[j+1];
        }    
            marketOrders.pop();
    }

   }

   function settleTrade(Order memory temp, uint amt, address seller, address buyer,bytes32 _ticker) private{
        uint cost = temp.price * amt;
        balances[seller]["ETH"] += cost; 
        balances[seller][_ticker] -= amt; 
        balances[buyer]["ETH"] -= cost; 
        balances[buyer][_ticker] += amt; 
   }
  
}