"""Sample app for the AKS DevSecOps platform POC.

Minimal Flask service exposing health/readiness/version endpoints so the
pipeline smoke tests, Helm probes and Prometheus scrape config have targets.
"""
import os

from flask import Flask, jsonify

app = Flask(__name__)

VERSION = os.getenv("APP_VERSION", "1.0.0")
ENV = os.getenv("APP_ENV", "local")


@app.route("/")
def index():
    return jsonify(service="sample-app", version=VERSION, environment=ENV)


@app.route("/health")
def health():
    return jsonify(status="healthy"), 200


@app.route("/ready")
def ready():
    return jsonify(status="ready"), 200


@app.route("/metrics")
def metrics():
    # Placeholder Prometheus-style metrics - swap for prometheus_client in real apps
    return "app_requests_total 1\n", 200, {"Content-Type": "text/plain"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
