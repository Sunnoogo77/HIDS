# from flask import Blueprint, request, jsonify
# import json

# alerts_bp = Blueprint('alerts', __name__)

# ALERT_FILE = "Core/data/alerts.json"

# #Read alerts 
# def load_alerts():
#     if not(ALERT_FILE and isinstance(ALERT_FILE, str)):
#         return {"file":[], "folders":[], "ips":[]}
#     try:
#         with open(ALERT_FILE, "r") as file:
#             return json.load(file)
#     except(FileNotFoundError, json.JSONDecodeError):
#         return {"file":[], "folders":[], "ips":[]}

# #Save alerts
# def save_alerts(data):
#     with open(ALERT_FILE, "w") as file:
#         json.dump(data, file, indent=4)

# #Retreive all alerts
# @alerts_bp.route("/", methods=["GET"])
# def get_alerts():
#     alerts = load_alerts()
#     return jsonify(alerts)

# #Clear all alerts
# @alerts_bp.route("/clear", methods=["POST"])
# def clear_alerts():
#     save_alerts({"file":[], "folders":[], "ips":[]})
#     return jsonify({"message": "Alerts cleared."}), 200

from flask import Blueprint, jsonify
from app.services.alert_service import AlertService

alerts_bp = Blueprint('alerts', __name__, url_prefix='/alerts')
alert_service = AlertService()

@alerts_bp.route('/list', methods=['GET'])
def list_alerts():
    alerts = alert_service.list_recent_alerts()
    return jsonify({'alerts': alerts}), 200

@alerts_bp.route('/logs/list', methods=['GET'])
def list_logs():
    logs = alert_service.list_system_logs()
    return jsonify({'logs': logs}), 200