// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;
import '../contracts/wallet.sol';
import '@openzeppelin/contracts/utils/Counters.sol';


contract Dex is MyWallet{

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
            require(getBalance("ETH") >= amount * price,'Cost exdeeds the ETH balance');
        }
        else if(side == Side.SELL){
            require(getBalance(ticker) >= amount,'Insufficient tokens to sell');
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
            if(marketOrderBook[ticker][1].length > 0){
              settleOrder(orders, marketOrderBook[ticker][1], ticker, Side.SELL,0);
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
            if(marketOrderBook[ticker][0].length > 0){
              settleOrder(orders, marketOrderBook[ticker][0], ticker, Side.BUY,0);
            }
            
         }
          _counterIds.increment();
    }
   
   function createMarketOrder(Side side, bytes32 ticker, uint amount) public {
    
        if(Side.SELL == side){
            require(amount <= getBalance(ticker),"Insufficent tokens to sell");
        
            uint newCounterId = _marketIds.current();
            marketOrder[] storage marketOrders = marketOrderBook[ticker][1];
            Order[] storage orders = orderBook[ticker][0];
            if(orders.length == 0){
              marketOrders.push(marketOrder(newCounterId,msg.sender,side,ticker,amount, false));
              _marketIds.increment();
            }
            else{
              settleOrder(orders, marketOrders, ticker, side,amount);
            }
            
        }
        else if(Side.BUY == side){
            uint newCounterId = _marketIds.current();
            marketOrder[] storage marketOrders = marketOrderBook[ticker][0];
            Order[] storage orders = orderBook[ticker][1]; 
            if(orders.length == 0){
               marketOrders.push(marketOrder(newCounterId,msg.sender,side,ticker,amount, false));
               _marketIds.increment();
            }
            else{
              settleOrder(orderBook[ticker][1], marketOrderBook[ticker][0], ticker, side,amount);
            }
        }
         
   }

   function settleOrder(Order[] storage orders, marketOrder[] storage marketOrders, bytes32 ticker, Side side,uint amount) private {
            
       while(orders.length > 0 && (marketOrders.length > 0 || amount > 0)){
           address trader;
           uint expectedAmount = 0;
           if(marketOrders.length > 0){
               trader = marketOrders[0].trader;
               amount = marketOrders[0].amount;
           }
           else{
               trader = msg.sender;
           }
           if (side == Side.BUY) {
                require(balances[trader]["ETH"] > orders[0].price * orders[0].amount,"Insufficient ETH");
            }
           
            if (amount >= orders[0].amount) {
                amount -= orders[0].amount;
                orders[0].filled = true;
                expectedAmount = orders[0].amount;
                orders[0].amount = 0;
            }
         
            else if(amount < orders[0].amount){
                orders[0].amount -= amount;
                expectedAmount = amount;
                amount = 0;
            }
            
            if (side == Side.BUY) {
                settleTrade(orders[0], expectedAmount, orders[0].trader, trader, ticker);
            }
            else {
                settleTrade(orders[0], expectedAmount, trader, orders[0].trader, ticker);
            }
            
            if(marketOrders.length > 0){
                marketOrders[0].amount = amount;
                if(amount == 0){
                  marketOrders[0].filled = true;
                }
            }
            deleteOrders(orders, marketOrders);
        }
        if(marketOrders.length == 0 && amount > 0 && orders.length == 0 ){
           marketOrderBook[ticker][uint256(side)].push(marketOrder(_marketIds.current(),msg.sender,side,ticker,amount, false));
           _marketIds.increment();
        }
    }

   function deleteOrders(Order[] storage orders, marketOrder[] storage marketOrders) private {

    if (orders[0].filled) {
            
        for (uint j = 0; j < orders.length-1; j++){
            orders[j] = orders[j+1];
        }    
        orders.pop();
    }

    if(marketOrders.length > 0 && marketOrders[0].filled){
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
