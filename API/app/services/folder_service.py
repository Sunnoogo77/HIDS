import subprocess
from app.utils.json_utils import read_json, write_json
import os

class FolderService:
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
    
    def add_folder_to_monitoring(self, folder_path):
        """
        Add a folder to the list of monitored folders.
        """
        if not os.path.isdir(folder_path):
            raise ValueError("Folder does not exist.")
        output = self.run_powershell_script("configs.ps1", ["-Action", "ADD", "-Type", "Folder", "-Value", folder_path])
        if "Folder added:" not in output:
            raise ValueError("Failed to add folder: " + output)
    
    def remove_folder_from_monitoring(self, folder_path):
        """
        Remove a folder from the list of monitored folders.
        """
        output = self.run_powershell_script("configs.ps1", ["-Action", "REMOVE", "-Type", "Folder", "-Value", folder_path])
        if "Folder removed:" not in output:
            raise ValueError("Failed to remove folder: " + output)
    
    def list_monitored_folders(self):
        """
        List all folders being monitored.
        """
        config = read_json(self.config_file)
        return config.get("folders", [])