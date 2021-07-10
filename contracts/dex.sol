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

   function createMarketOrder(Side side, bytes32 ticker, uint amount) public {
    
    if(Side.SELL == side){
        require(amount <= balances[msg.sender][ticker],"Insufficent tokens to sell");
        Order[] storage orders = orderBook[ticker][0]; //Buy order book

        while(amount > 0 && orders.length > 0){
         if(amount >= orders[0].amount){
             //updating the amount for seller
             Order memory temp = orders[0];
             amount -= temp.amount; //left amount
             balances[msg.sender]["ETH"] += (temp.price * temp.amount); // depositing eth in the account of seller
             balances[msg.sender][ticker] -= temp.amount; // withdrawing tickers from the account of seller
             balances[temp.trader]["ETH"] -= (temp.price * temp.amount); // reducing eth from the acccount of buyer
             balances[temp.trader][ticker] += temp.amount; //adding ticker to the account of buyer
             temp.amount = 0;
             orders[0] = temp;
             //deleting the fulfilled order from buy order book by shifting rows to the front
             for(uint j = 0 ; j < orders.length-1 ; j++){
                 orders[j] = orders[j+1];
             }
             orders.pop(); // removing the last duplicate row
          
         }
         else if(amount < orders[0].amount){
             Order memory temp = orders[0];
             temp.amount -= amount;
             balances[msg.sender]["ETH"] += temp.price * amount;
             balances[msg.sender][ticker] -= amount; //should become 0
             balances[temp.trader]["ETH"] -= temp.price * amount;
             balances[temp.trader][ticker] += amount;
             amount = 0;
             orders[0] = temp;
         }
     }
    }
    else if(Side.BUY == side){
        //make sure that buyer has enough eth to buy tokens
         Order[] storage orders = orderBook[ticker][1]; //limit order sell book to get maximum selling price
        if(orders.length > 0){
            //require(balances[msg.sender]["ETH"] >= amount * orders[orders.length-1].price,"Insufficient ETH to buy");
            uint minEther = 0;
            uint _amount = amount ;// amount used in function parameter
            for(uint i = 0 ; i < orders.length ; i++){
                if(_amount >= orders[i].amount){
                     _amount -= orders[i].amount;
                     minEther += orders[i].price * orders[i].amount;
                }else if(_amount < orders[i].amount){
                    minEther += orders[i].price * _amount;
                    _amount = 0;
                    break;
                }
            }
            require(balances[msg.sender]["ETH"] >= minEther, "Insufficient ETH in your wallet");

        }
        else{
            require(balances[msg.sender]["ETH"] >= 100000,"Should keep your wallet heavy");
        }
 
        while(amount > 0 && orders.length > 0){
            if(amount >= orders[0].amount){
               Order memory temp = orders[0];
               amount -= temp.amount;
               balances[msg.sender][ticker] += temp.amount ;//buyer
               balances[msg.sender]["ETH"] -= temp.price * temp.amount; // buyer
               balances[temp.trader][ticker] -= temp.amount; // seller
               balances[temp.trader]["ETH"] += temp.price * temp.amount; //seller
               temp.amount = 0;
               orders[0] = temp;

               //deleting the fulfilled order from sell order book by shifting rows to the front
                for(uint j = 0 ; j < orders.length-1 ; j++){
                    orders[j] = orders[j+1];
                }
                orders.pop(); // removing the last duplicate row
            }
            else if(amount < orders[0].amount){
                Order memory temp = orders[0];
                temp.amount -= amount;
                balances[msg.sender][ticker] += amount ;//buyer
                balances[msg.sender]["ETH"] -= temp.price * amount; // buyer
                balances[temp.trader][ticker] -= amount; // seller
                balances[temp.trader]["ETH"] += temp.price * amount; //seller
                amount = 0;
                orders[0] = temp;
            }
        } 
    }

   }

    
}