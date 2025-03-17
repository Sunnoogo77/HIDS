from app.utils.json_utils import read_json, write_json
import os

class AlertService:
    def __init__(self):
        self.alerts_file = "../Core/data/alerts.json"
        self.logs_file = "../Core/logs/hids.json"
        
    def list_recent_alerts(self):
        """
        List the most recent alerts.
        """
        alerts = read_json(self.alerts_file)
        return alerts.get("alerts", [])
    
    def list_system_logs(self):
        """
        List the system logs.
        """
        logs = read_json(self.logs_file)
        return logs.get("logs", [])