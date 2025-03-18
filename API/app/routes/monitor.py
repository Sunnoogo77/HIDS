# # from flask import Blueprint, request, jsonify
# # from app.services.monitor_service import MonitorService

# # monitor_bp = Blueprint('monitor', __name__, url_prefix='/monitor')
# # monitor_service = MonitorService()

# # @monitor_bp.route('/start', methods=['POST'])
# # def start_monitor():
# #     """Lance les types de monitoring spécifiés."""
# #     data = request.get_json()
# #     monitor_types = data.get('monitor_types')
# #     if not monitor_types or not isinstance(monitor_types, list):
# #         return jsonify({'error': 'Monitor types list is required'}), 400
# #     results = monitor_service.start_monitoring(monitor_types)
# #     return jsonify(results), 200

# # @monitor_bp.route('/stop', methods=['POST'])
# # def stop_monitor():
# #     """Arrête un type de monitoring."""
# #     data = request.get_json()
# #     monitor_type = data.get('monitor_type')
# #     if not monitor_type:
# #         return jsonify({'error': 'Monitor type is required'}), 400
# #     try:
# #         output = monitor_service.stop_monitoring(monitor_type)
# #         return jsonify({'message': 'Monitoring stopped successfully', 'output': output}), 200
# #     except ValueError as e:
# #         return jsonify({'error': str(e)}), 400

# #monitor.py
# from flask import Blueprint, request, jsonify
# from app.services.monitor_service import MonitorService
# from app.utils.auth_decorators import token_required
# # from quart import Blueprint, request, jsonify
# # from app.services.monitor_service import MonitorService

# monitor_bp = Blueprint('monitor', __name__, url_prefix='/monitor')
# monitor_service = MonitorService()

# @monitor_bp.route('/start', methods=['POST'])
# @token_required
# async def start_monitor():
#     """Starts the specified types of monitoring asynchronously."""
    
#     data = await request.get_json()
#     monitor_types = data.get('monitor_types')
#     if not monitor_types or not isinstance(monitor_types, list):
#         return jsonify({'error': 'Monitor types list is required'}), 400
#     results = await monitor_service.start_monitoring(monitor_types)
#     return jsonify({"results": results}), 200

# @monitor_bp.route('/stop', methods=['POST'])
# @token_required
# async def stop_monitor():
#     """Stops a type of monitoring."""
    
#     data = await request.get_json()
#     monitor_type = data.get('monitor_type')
#     if not monitor_type:
#         return jsonify({'error': 'Monitor type is required'}), 400
#     try:
#         output = await monitor_service.stop_monitoring(monitor_type)
#         return jsonify({'message': 'Monitoring stopped successfully', 'output': output}), 200
#     except ValueError as e:
#         return jsonify({'error': str(e)}), 400

#-----------------------------------------

# from flask import Blueprint, request, jsonify
# from app.services.monitor_service import MonitorService
# from app.utils.auth_decorators import token_required

# monitor_bp = Blueprint('monitor', __name__, url_prefix='/monitor')
# monitor_service = MonitorService()

# @monitor_bp.route('/start', methods=['POST'])
# @token_required
# async def start_monitor():
#     """Starts the specified types of monitoring asynchronously."""
#     data = await request.get_json()
#     monitor_types = data.get('monitor_types')
#     if not monitor_types or not isinstance(monitor_types, list):
#         return jsonify({'error': 'Monitor types list is required'}), 400
#     try:
#         results = await monitor_service.start_monitoring(monitor_types)
#         return jsonify({"results": results}), 200
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# @monitor_bp.route('/stop', methods=['POST'])
# @token_required
# async def stop_monitor():
#     """Stops a type of monitoring."""
#     data = await request.get_json()
#     monitor_type = data.get('monitor_type')
#     if not monitor_type:
#         return jsonify({'error': 'Monitor type is required'}), 400
#     try:
#         output = await monitor_service.stop_monitoring(monitor_type)
#         return jsonify({'message': 'Monitoring stopped successfully', 'output': output}), 200
#     except ValueError as e:
#         return jsonify({'error': str(e)}), 400
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500


#--------------------------------------

# API/app/routes/monitor.py

from flask import Blueprint, request, jsonify
from app.services.monitor_service import MonitorService
from app.utils.auth_decorators import token_required

monitor_bp = Blueprint('monitor', __name__, url_prefix='/monitor')
monitor_service = MonitorService()

@monitor_bp.route('/start', methods=['POST'])
@token_required
async def start_monitor():
    """Starts the specified types of monitoring asynchronously."""
    data = request.get_json()
    monitor_types = data.get('monitor_types')
    if not monitor_types or not isinstance(monitor_types, list):
        return jsonify({'error': 'Monitor types list is required'}), 400
    try:
        results = await monitor_service.start_monitoring(monitor_types)
        return jsonify({"message": "Monitoring started", "results": results}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@monitor_bp.route('/stop/<monitor_type>', methods=['POST'])
@token_required
async def stop_monitor(monitor_type):
    """Stops a type of monitoring."""
    try:
        message, code = await monitor_service.stop_monitoring(monitor_type)
        return jsonify(message), code
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@monitor_bp.route('/stop/all', methods=['POST'])
@token_required
async def stop_all_monitor():
    """Stops all monitoring scripts."""
    try:
        results = await monitor_service.stop_all_monitoring()
        return jsonify({"message": "All monitoring stopped", "results": results}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

#start all
@monitor_bp.route('/start/all', methods=['POST'])
@token_required
async def start_all_monitor():
    """Starts all monitoring scripts."""
    try:
        results = await monitor_service.start_all_monitoring()
        return jsonify({"message": "All monitoring started", "results": results}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500