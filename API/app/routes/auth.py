# API/app/routes/auth.py

from flask import Blueprint, request, jsonify
from app.services.auth_service import AuthService
from app import auth_service # Importation de l'instance du service d'authentification

auth_bp = Blueprint("auth", __name__, url_prefix="/auth")

@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")
    if not username or not password:
        return jsonify({"message": "Username and password are required"}), 400
    success, message = auth_service.create_user(username, password)
    if success:
        return jsonify({"message": "User created successfully"}), 201
    else:
        return jsonify({"message": message}), 400

@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")
    if not username or not password:
        return jsonify({"message": "Username and password are required"}), 400
    if auth_service.verify_password(username, password):
        token = auth_service.generate_token(username)
        return jsonify({"token": token}), 200
    else:
        return jsonify({"message": "Invalid username or password"}), 401