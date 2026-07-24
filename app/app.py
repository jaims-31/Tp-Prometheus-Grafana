from flask import Flask, jsonify
import os
from azure.monitor.opentelemetry import configure_azure_monitor
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Gauge

app = Flask(__name__)

if "APPLICATIONINSIGHTS_CONNECTION_STRING" in os.environ:
    configure_azure_monitor(
        connection_string=os.environ["APPLICATIONINSIGHTS_CONNECTION_STRING"]
    )

metrics = PrometheusMetrics(app)
errors_gauge = Gauge('log_erreurs_total', "Nombre d'erreurs détectées")
errors_gauge.set(0)


@app.route('/health')
def health():
    return jsonify({"status": "healthy", "mode": "solo"}), 200


@app.route('/')
def index():
    return "Bienvenue sur l'API de supervision de Franck !", 200


if __name__ == '__main__':
    port = int(os.environ.get("PORT", 8000))
    app.run(host='0.0.0.0', port=port)
