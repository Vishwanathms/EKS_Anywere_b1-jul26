import os
import redis
from flask import Flask

app = Flask(__name__)

# Read environment variables (default values for local dev)
REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", 6379))
REDIS_DB = int(os.getenv("REDIS_DB", 0))

# Connect to Redis
redis_client = redis.StrictRedis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    db=REDIS_DB,
    decode_responses=True
)

@app.route('/')
def hello():
    # Simple counter stored in Redis
    count = redis_client.incr("hits")
    return f"Hello from Gitlab-Docker-K8s Pipeline! This page has been visited {count} times."

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("APP_PORT", 5000)))
