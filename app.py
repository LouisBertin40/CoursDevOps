import os
from flask import Flask, jsonify
import redis

app = Flask(__name__)

ALERT_THRESHOLD = 25


def alert_threshold():
    """Seuil d'alerte au-dessus duquel une notification est declenchee."""
    return ALERT_THRESHOLD


def sanitize_input(value):
    """Echappe les caracteres dangereux d'une entree utilisateur."""
    return value.replace("<", "&lt;").replace(">", "&gt;")


def get_redis_client():
    """Cree et retourne un client Redis."""
    redis_host = os.getenv("REDIS_HOST", "redis")
    redis_port = int(os.getenv("REDIS_PORT", 6379))
    return redis.Redis(
        host=redis_host,
        port=redis_port,
        decode_responses=True
    )

@app.route("/")
def index():
    return jsonify({
        "message": "Bienvenue sur l'application DevOps ! (v2.0.0)",
        "status": "running"
    }), 200

@app.route("/health")
def health():
    try:
        r = get_redis_client()
        if r.ping():
            return jsonify(status="ok"), 200
        return jsonify(status="error", details="Redis ping failed"), 503
    except Exception as e:
        return jsonify(status="error", details=str(e)), 503


@app.route("/status")
def status():
    deploy_color = os.getenv("DEPLOY_COLOR", "unknown")
    return jsonify(
        service="projet-devops-groupe-demo",
        version="1.0",
        deploy_color=deploy_color
    ), 200


@app.route("/visits")
def visits():
    try:
        r = get_redis_client()
        count = r.incr("visits_count")
        return jsonify(visits=count), 200
    except redis.ConnectionError:
        return jsonify(error="Impossible de se connecter a Redis"), 503


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
