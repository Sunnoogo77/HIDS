import subprocess
from app.utils.json_utils import read_json, write_json
import os
import ipaddress

class IpService:
    def __init__(self):
        self.config_file = "../Core/data/config.json"
        self.scripts_dir = "../Core/scripts"
    
    def run_powershell_script(self, script_name, args=None):
        """
        Run a PowerShell script and return the output.
        """
        script_path = os.path.join(self.scripts_dir, script_name)
        command = ["powershell.exe", "-ExecutionPolicy", "Bypass", "-File", script_path]
        if args:
            command.extend(args)
        try:
            result = subprocess.run(command, capture_output=True, text=True, check=True)
            return result.stdout
        except subprocess.CalledProcessError as e:
            return e.stderr
    
    def add_ip_to_monitoring(self, ip_address):
        """
        Add an IP address to the list of monitored IP addresses.
        """
        try:
            ipaddress.ip_address(ip_address)
        except ValueError:
            raise ValueError("Invalid IP address.")
        output = self.run_powershell_script("configs.ps1", ["-Action", "ADD", "-Type", "IP", "-Value", ip_address])
        if "IP added:" not in output:
            raise ValueError("Failed to add IP address: " + output)
    
    def remove_ip_from_monitoring(self, ip_address):
        """
        Remove an IP address from the list of monitored IP addresses.
        """
        output = self.run_powershell_script("configs.ps1", ["-Action", "REMOVE", "-Type", "IP", "-Value", ip_address])
        if "IP removed:" not in output:
            raise ValueError("Failed to remove IP address: " + output)
    
    def list_monitored_ips(self):
        """
        List all IP addresses being monitored.
        """
        config = read_json(self.config_file)
        return config.get("ips", [])