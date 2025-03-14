import subprocess
from app.utils.json_utils import read_json, write_json
import os

class FileService:
    def __init__(self):
        self.config_file = "../Core/data/config.json"
        self.scripts_dir = "../Core/scripts"
        
    def run_powershell_script(self, script_name, args=None):
        """
        Run a PowerShell script. and return the output.
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
    
    def add_file_to_monitoring(self, file_path):
        """
        Add a file to the list of monitored files.
        """
        if not os.path.isfile(file_path):
            raise ValueError("File does not exist.")
        output = self.run_powershell_script("configs.ps1", ["-Action", "ADD", "-Type", "File", "-Value", file_path])
        if "File added:" not in output:
            raise ValueError("Failed to add file: " + output)
    
    def remove_file_from_monitoring(self, file_path):
        """
        Remove a file from the list of monitored files.
        """
        output = self.run_powershell_script("configs.ps1", ["-Action", "REMOVE", "-Type", "File", "-Value", file_path])
        if "File removed:" not in output:
            raise ValueError("Failed to remove file: " + output)
    
    def list_monitored_files(self):
        """
        List all files being monitored.
        """
        config = read_json(self.config_file)
        return config.get("files", [])