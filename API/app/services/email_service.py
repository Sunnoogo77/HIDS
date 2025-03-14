import subprocess
from app.utils.json_utils import read_json, write_json
import os

class EmailService:
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
    
    def add_email_to_recipient(self, email_address):
        """
        Add an email address to the list of monitored email addresses.
        """
        output = self.run_powershell_script("configs.ps1", ["-Action", "ADD", "-Type", "Email", "-Value", email_address])
        if "Recipient added:" not in output:
            raise ValueError("Failed to add Recipient: " + output)
    
    def remove_email_recipient(self, email_address):
        """
        Remove an email address from the list of monitored email addresses.
        """
        output = self.run_powershell_script("configs.ps1", ["-Action", "REMOVE", "-Type", "Email", "-Value", email_address])
        if "Recipient removed:" not in output:
            raise ValueError("Failed to remove Recipient: " + output)
    
    def list_email_recipients(self):
        """
        List all email addresses being monitored.
        """
        config = read_json(self.config_file)
        return config.get('email', {}).get('recipients', [])
    
    # def send_test_email(self):
    #     """Force l'envoi immédiat d'un email d'alerte."""
    #     output = self.run_powershell_script("alerts.ps1", ["-ForceSend"]) # Assumant que -ForceSend force l'envoi
    #     if "Email sent successfully" not in output:
    #         raise ValueError("Failed to send test email: " + output)
        
    def set_email_frequency(self, frequency):
        """
        Set the email notification frequency.
        """
        output = self.run_powershell_script("configs.ps1", ["-Action", "SET-EMAIL-INTERVAL", "-Value", str(frequency)])
        if "Email frequency set:" not in output:
            raise ValueError("Failed to set email frequency: " + output)