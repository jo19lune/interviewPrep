import urllib.request
import json

data = json.dumps({
    "courriel": "test44@example.com",
    "mot_de_passe": "Test1234!"
}).encode()

req = urllib.request.Request(
    "http://127.0.0.1:9000/auth/login",
    data=data,
    headers={"Content-Type": "application/json"},
    method="POST"
)

try:
    resp = urllib.request.urlopen(req)
    body = resp.read().decode()
    print(f"STATUS: {resp.status}")
    print(f"BODY: {body[:300]}")
except urllib.error.HTTPError as e:
    body = e.read().decode()
    print(f"STATUS: {e.code}")
    print(f"BODY: {body[:500]}")
