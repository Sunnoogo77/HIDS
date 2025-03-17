# from flask import Blueprint, request, jsonify
# import json

# folders_bp = Blueprint('folders', __name__)

# CONFIG_FILE = "Core/data/config.json"

# #Read config file
# def load_config():
#     with open(CONFIG_FILE, "r") as file:
#         return json.load(file)

# #Save config file
# def save_config(data):
#     with open(CONFIG_FILE, "w") as file:
#         json.dump(data, file, indent=4)

# #Retreive all monitored folders
# @folders_bp.route("/", methods=["GET"])
# def get_folders():
#     config = load_config()
#     return jsonify(config.get("folders", []))

# #Add a folder to monitor
# @folders_bp.route("/add", methods=["POST"])
# def add_folder():
#     data = request.json
#     folder_path = data.get("folder")

#     if not folder_path:
#         return jsonify({"error": "Missing folder parameter"}), 400

#     config = load_config()
#     if folder_path not in config["folders"]:
#         config["folders"].append(folder_path)
#         save_config(config)
#         return jsonify({"message": f"Folder {folder_path} added to monitoring."}), 201
#     else:
#         return jsonify({"error": f"Folder {folder_path} already monitored."}), 200

# #Remove a folder from monitoring
# @folders_bp.route("/remove", methods=["POST"])
# def remove_folder():
#     data = request.json
#     folder_path = data.get("folder")

#     if not folder_path:
#         return jsonify({"error": "Missing folder parameter"}), 400

#     config = load_config()
#     if folder_path in config["folders"]:
#         config["folders"].remove(folder_path)
#         save_config(config)
#         return jsonify({"message": f"Folder {folder_path} removed from monitoring."}), 200
#     else:
#         return jsonify({"error": f"Folder {folder_path} not monitored."}), 404


from flask import Blueprint, request, jsonify
from app.services.folder_service import FolderService
import os

folders_bp = Blueprint('folders', __name__, url_prefix='/folders')
folder_service = FolderService()

@folders_bp.route('/add', methods=['POST'])
def add_folder():
    data = request.get_json()
    folder_path = data.get('folder_path')
    if not folder_path:
        return jsonify({'error': 'Folder path is required'}), 400
    try:
        folder_service.add_folder_to_monitoring(folder_path)
        return jsonify({'message': 'Folder added successfully'}), 201
    except ValueError as e:
        return jsonify({'error': str(e)}), 400

@folders_bp.route('/remove', methods=['DELETE'])
def remove_folder():
    data = request.get_json()
    folder_path = data.get('folder_path')
    if not folder_path:
        return jsonify({'error': 'Folder path is required'}), 400
    try:
        folder_service.remove_folder_from_monitoring(folder_path)
        return jsonify({'message': 'Folder removed successfully'}), 200
    except ValueError as e:
        return jsonify({'error': str(e)}), 400

@folders_bp.route('/list', methods=['GET'])
def list_folders():
    folders = folder_service.list_monitored_folders()
    return jsonify({'folders': folders}), 200