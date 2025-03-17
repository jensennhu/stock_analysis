import websocket, json
from config import *

socket = "wss://stream.data.alpaca.markets/v2/delayed_sip"

tickers = "NBIS"

def on_open(ws):
    print("opened")
    auth_data = {
        "action": "auth",
        "key": ALPACA_KEY_ID,
        "secret": ALPACA_SECRET_KEY
    }
    ws.send(json.dumps(auth_data))

    channel_data = {
        "action": "subscribe",
        "bars": [tickers]
    }
    ws.send(json.dumps(channel_data))

    # Vars	Type	Description
    # T	    string	message type: “b”, “d” or “u”
    # S	    string	symbol
    # o	    number	open price
    # h   	number	high price
    # l 	number	low price
    # c 	number	close price
    # v 	int 	volume
    # t 	string	RFC-3339 formatted timestamp

    # e.g. [{"T":"b","S":"NBIS","o":28.04,"h":28.13,"l":27.87,"c":27.87,"v":184101,"t":"2025-03-17T14:02:00Z","n":756,"vw":27.998943}]


def on_message(ws, message):
    print("received message")
    print(message)


def on_close(ws):
    print("closed connection")

ws = websocket.WebSocketApp(socket, on_open = on_open, on_message=on_message, on_close= on_close)

ws.run_forever()