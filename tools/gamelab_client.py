"""Small SSE MCP client; credentials come only from GAMELAB_API_KEY."""
import json
import os
import sys
import urllib.parse
import urllib.request

BASE = "https://mcp.gamelabstudio.co/sse"

def event(stream):
    kind, data = "message", []
    while True:
        raw = stream.readline()
        if not raw:
            raise RuntimeError("SSE stream closed")
        line = raw.decode().rstrip("\r\n")
        if not line:
            if data:
                return kind, "\n".join(data)
            continue
        if line.startswith("event:"):
            kind = line[6:].strip()
        if line.startswith("data:"):
            data.append(line[5:].strip())

def request(method, params):
    key = os.environ["GAMELAB_API_KEY"]
    headers = {"X-API-Key": key, "Accept": "text/event-stream"}
    with urllib.request.urlopen(urllib.request.Request(BASE, headers=headers), timeout=90) as stream:
        kind, value = event(stream)
        if kind != "endpoint":
            raise RuntimeError("Missing message endpoint")
        endpoint = urllib.parse.urljoin(BASE, value)
        if urllib.parse.urlsplit(endpoint).netloc != urllib.parse.urlsplit(BASE).netloc:
            raise RuntimeError("Unexpected endpoint host")
        def send(payload):
            req = urllib.request.Request(endpoint, data=json.dumps(payload).encode(), headers={"X-API-Key": key, "Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=90) as response:
                response.read()
        def receive(identifier):
            while True:
                _, payload = event(stream)
                message = json.loads(payload)
                if message.get("id") == identifier:
                    if "error" in message:
                        raise RuntimeError(json.dumps(message["error"]))
                    return message["result"]
        send({"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"codex-game-assets","version":"1.0"}}})
        receive(1)
        send({"jsonrpc":"2.0","method":"notifications/initialized"})
        send({"jsonrpc":"2.0","id":2,"method":method,"params":params})
        return receive(2)

if __name__ == "__main__":
    payload = json.loads(sys.stdin.read())
    print(json.dumps(request(payload["method"], payload.get("params", {})), ensure_ascii=False))
