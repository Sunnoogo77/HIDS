from flask import Blueprint, jsonify
import psutil

status_bp = Blueprint('status', __name__)

#Verify if the script is running
def is_script_running(script_name):
    for process in psutil.process_iter():
        try:
            if script_name in " ".join(process.info["cmdline"]):
                return True
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            continue
    return False

#Check the general status of the monitoring
@status_bp.route("/", methods=["GET"])
def get_status():
    status = {
        "files_monitoring": is_script_running("monitor_files.ps1"),
        "folders_monitoring": is_script_running("monitor_folders.ps1"),
        "ips_monitoring": is_script_running("monitor_ips.ps1"),
        "email_sending": is_script_running("send_email.ps1")
    }
    return jsonify(status)