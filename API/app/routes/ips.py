# from flask import Blueprint, request, jsonify
# import json
# import re

# ips_bp = Blueprint('ips', __name__)

# CONFIG_FILE = "Core/data/config.json"

# #Read config file
# def load_config():
#     with open(CONFIG_FILE, "r") as file:
#         return json.load(file)

# #Save config file
# def save_config(data):
#     with open(CONFIG_FILE, "w") as file:
#         json.dump(data, file, indent=4)

# # Verify if the IP is valid
# def is_valid_ip(ip):
#     return re.match(r"^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$", ip) is not None

# #Retreive all monitored IPs
# @ips_bp.route("/", methods=["GET"])
# def get_ips():
#     config = load_config()
#     return jsonify(config.get("ips", []))

# #Add an IP to monitor
# @ips_bp.route("/add", methods=["POST"])
# def add_ip():
#     data = request.json
#     ip = data.get("ip")

#     if not ip or not is_valid_ip(ip):
#         return jsonify({"error": "Valid IP address is required"}), 400
    
#     config = load_config()
#     if ip not in config["ips"]:
#         config["ips"].append(ip)
#         save_config(config)
#         return jsonify({"message": f"IP {ip} added to monitoring."}), 201
#     else:
#         return jsonify({"error": f"IP {ip} already monitored."}), 200
    

# #Remove an IP from monitoring
# @ips_bp.route("/remove", methods=["POST"])
# def remove_ip():
#     data = request.json
#     ip = data.get("ip")

#     if not ip or not is_valid_ip(ip):
#         return jsonify({"error": "Valid IP address is required"}), 400

#     config = load_config()
#     if ip in config["ips"]:
#         config["ips"].remove(ip)
#         save_config(config)
#         return jsonify({"message": f"IP {ip} removed from monitoring."}), 200
#     else:
#         return jsonify({"error": f"IP {ip} not monitored."}), 404

from flask import Blueprint, request, jsonify
from app.services.ip_service import IpService
import ipaddress

ips_bp = Blueprint('ips', __name__, url_prefix='/ips')
ip_service = IpService()

@ips_bp.route('/add', methods=['POST'])
def add_ip():
    data = request.get_json()
    ip_address = data.get('ip_address')
    if not ip_address:
        return jsonify({'error': 'IP address is required'}), 400
    try:
        ip_service.add_ip_to_monitoring(ip_address)
        return jsonify({'message': 'IP added successfully'}), 201
    except ValueError as e:
        return jsonify({'error': str(e)}), 400

@ips_bp.route('/remove', methods=['DELETE'])
def remove_ip():
    data = request.get_json()
    ip_address = data.get('ip_address')
    if not ip_address:
        return jsonify({'error': 'IP address is required'}), 400
    try:
        ip_service.remove_ip_from_monitoring(ip_address)
        return jsonify({'message': 'IP removed successfully'}), 200
    except ValueError as e:
        return jsonify({'error': str(e)}), 400

@ips_bp.route('/list', methods=['GET'])
def list_ips():
    ips = ip_service.list_monitored_ips()
    return jsonify({'ips': ips}), 200