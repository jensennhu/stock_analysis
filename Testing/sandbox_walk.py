import config
from alpaca.trading.client import TradingClient
from alpaca.trading.requests import GetAssetsRequest, GetOrdersRequest, TrailingStopOrderRequest, MarketOrderRequest, LimitOrderRequest, TakeProfitRequest, StopLossRequest
from alpaca.trading.enums import AssetClass, OrderSide, TimeInForce, OrderClass, QueryOrderStatus
from alpaca.trading.stream import TradingStream


# We are working with the TradingAPI from Alpaca
trading_client = TradingClient(
    api_key = config.ALPACA_KEY_ID, 
    secret_key = config.ALPACA_SECRET_KEY
    )

# -- Get account info ---
account = trading_client.get_account()

# check if account is restricted from trading
if account.account_blocked:
    print('Account is currently restricted from trading.')
    # account number
    # account fees
    # account buying power
    # equity
    # last_equity

# check how much money we can use to open new positions
print('${} is available as buying power.'.format(account.buying_power))

# Check our current balance vs. our balance at the last market close
balance_change = float(account.equity) - float(account.last_equity)
print(f'Today\'s portfolio balance change: ${balance_change}')

# -- Get Assets --
#  search for US equities
search_params = GetAssetsRequest(asset_class=AssetClass.US_EQUITY)
assets = trading_client.get_all_assets(search_params)

# search for AAPL
aapl_asset = trading_client.get_asset('AAPL')

if aapl_asset.tradable:
    print('We can trade AAPL.')


# # preparing market order
# market_order_data = MarketOrderRequest(
#                     symbol="SPY",
#                     qty=0.023,
#                     side=OrderSide.BUY,
#                     time_in_force=TimeInForce.DAY
#                     )

# Market order
# market_order = trading_client.submit_order(
#                 order_data=market_order_data
#                )

# # preparing limit order
# limit_order_data = LimitOrderRequest(
#                     symbol="BTC/USD",
#                     limit_price=17000,
#                     notional=4000,
#                     side=OrderSide.SELL,
#                     time_in_force=TimeInForce.FOK
#                    )

# # Limit order
# limit_order = trading_client.submit_order(
#                 order_data=limit_order_data
#               )

# # preparing orders
# market_order_data = MarketOrderRequest(
#                     symbol="SPY",
#                     qty=1,
#                     side=OrderSide.SELL,
#                     time_in_force=TimeInForce.GTC
#                     )

# # Market order
# market_order = trading_client.submit_order(
#                 order_data=market_order_data
#                )

# preparing orders
market_order_data = MarketOrderRequest(
                    symbol="SPY",
                    qty=0.023,
                    side=OrderSide.BUY,
                    time_in_force=TimeInForce.DAY,
                    client_order_id='my_first_order',
                    )

# # Market order
# market_order = trading_client.submit_order(
#                 order_data=market_order_data
#                )

# # Get our order using its Client Order ID.
# my_order = trading_client.get_order_by_client_id('my_first_order')
# print('Got order #{}'.format(my_order.id))


# # preparing bracket order with both stop loss and take profit
# bracket__order_data = MarketOrderRequest(
#                     symbol="SPY",
#                     qty=5,
#                     side=OrderSide.BUY,
#                     time_in_force=TimeInForce.DAY,
#                     order_class=OrderClass.BRACKET,
#                     take_profit=TakeProfitRequest(limit_price=400),
#                     stop_loss=StopLossRequest(stop_price=300)
#                     )

# bracket_order = trading_client.submit_order(
#                 order_data=bracket__order_data
#                )

# # preparing oto order with stop loss
# oto_order_data = LimitOrderRequest(
#                     symbol="SPY",
#                     qty=5,
#                     limit_price=350,
#                     side=OrderSide.BUY,
#                     time_in_force=TimeInForce.DAY,
#                     order_class=OrderClass.OTO,
#                     stop_loss=StopLossRequest(stop_price=300)
#                     )

# # Market order
# oto_order = trading_client.submit_order(
#                 order_data=oto_order_data
#                )


# Get the last 100 closed orders
# get_orders_data = GetOrdersRequest(
#     status=QueryOrderStatus.CLOSED,
#     limit=100,
#     nested=True  # show nested multi-leg orders
# )

# trading_client.get_orders(filter=get_orders_data)


stream = TradingStream(config.ALPACA_KEY_ID, config.ALPACA_SECRET_KEY, paper=True)


@conn.on(client_order_id)
async def on_msg(data):
    # Print the update to the console.
    print("Update for {}. Event: {}.".format(data.event))

stream.subscribe_trade_updates(on_msg)
# Start listening for updates.
stream.run()
