# from flask import Blueprint, request, jsonify
# from app.services.file_service import FileService
# import json

# files_bp = Blueprint('files', __name__)

# CONFIG_FILE = "Core/data/config.json"

# #Read config file
# def load_config():
#     with open(CONFIG_FILE, "r") as file:
#         return json.load(file)
    
# #Save config file
# def save_config(data):
#     with open(CONFIG_FILE, "w") as file:
#         json.dump(data, file, indent=4)

# #Retreive all monitored files
# @files_bp.route("/", methods=["GET"])
# def get_files():
#     config = load_config()
#     return jsonify(config["files"])

# #Add a file to monitor
# @files_bp.route("/add", methods=["POST"])
# def add_file():
#     data = request.json()
#     file_path = data.get("file")
    
#     if not file_path:
#         return jsonify({"error": "Missing file parameter"}), 400
    
#     config = load_config()
#     if file_path not in config["files"]:
#         config["files"].append(file_path)
#         save_config(config)
#         return jsonify({"message": f"File {file_path} added to monitoring."}), 201
#     else:
#         return jsonify({"error": f"File {file_path} already monitored."}), 200

# #Remove a file from monitoring
# @files_bp.route("/remove", methods=["POST"])
# def remove_file():
#     data = request.json()
#     file_path = data.get("file")
    
#     if not file_path:
#         return jsonify({"error": "Missing file parameter"}), 400
    
#     config = load_config()
#     if file_path in config["files"]:
#         config["files"].remove(file_path)
#         save_config(config)
#         return jsonify({"message": f"File {file_path} removed from monitoring."}), 200
#     else:
#         return jsonify({"error": f"File {file_path} not monitored."}), 404




from flask import Blueprint, request, jsonify
from app.services.file_service import FileService
import os

files_bp = Blueprint('files', __name__, url_prefix='/files')
file_service = FileService()

@files_bp.route('/add', methods=['POST'])
def add_file():
    data = request.get_json()
    file_path = data.get('file_path')
    if not file_path:
        return jsonify({'error': 'File path is required'}), 400
    try:
        file_service.add_file_to_monitoring(file_path)
        return jsonify({'message': 'File added successfully'}), 201
    except ValueError as e:
        return jsonify({'error': str(e)}), 400

@files_bp.route('/remove', methods=['DELETE'])
def remove_file():
    data = request.get_json()
    file_path = data.get('file_path')
    if not file_path:
        return jsonify({'error': 'File path is required'}), 400
    try:
        file_service.remove_file_from_monitoring(file_path)
        return jsonify({'message': 'File removed successfully'}), 200
    except ValueError as e:
        return jsonify({'error': str(e)}), 400

@files_bp.route('/list', methods=['GET'])
def list_files():
    files = file_service.list_monitored_files()
    return jsonify({'files': files}), 200