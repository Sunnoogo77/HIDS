# import asyncio
# import subprocess
# import os

# class MonitorService:
#     def __init__(self):
#         self.scripts_dir = "../Core/scripts"

#     async def run_powershell_script(self, script_name, args=None):
#         """
#         Run a PowerShell script asynchronously.
#         """
#         script_path = os.path.join(self.scripts_dir, script_name)
#         command = ["powershell.exe", "-ExecutionPolicy", "Bypass", "-File", script_path]
#         if args:
#             command.extend(args)

#         process = await asyncio.create_subprocess_exec(*command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
#         stdout, stderr = await process.communicate()
#         return stdout.decode(), stderr.decode()

#     async def start_monitoring(self, monitor_types):
#         """
#         Launches the specified monitoring types asynchronously.
#         """
#         tasks = []
#         if "files" in monitor_types:
#             tasks.append(self.run_powershell_script("monitor_files.ps1"))
#         if "folders" in monitor_types:
#             tasks.append(self.run_powershell_script("monitor_folders.ps1"))
#         if "ips" in monitor_types:
#             tasks.append(self.run_powershell_script("monitor_ips.ps1"))
#         if "emails" in monitor_types:
#             tasks.append(self.run_powershell_script("alerts.ps1"))
#         results = await asyncio.gather(*tasks)
#         return results

#     async def stop_monitoring(self, monitor_type):
#         """
#         Stop monitoring (files, folders, IPs, mails).
#         """
#         if monitor_type == "files":
#             output = await self.run_powershell_script("stop_monitor_files.ps1")
#         elif monitor_type == "folders":
#             output = await self.run_powershell_script("stop_monitor_folders.ps1")
#         elif monitor_type == "ips":
#             output = await self.run_powershell_script("stop_monitor_ips.ps1")
#         elif monitor_type == "emails":
#             output = await self.run_powershell_script("stop_monitor_emails.ps1")
#         else:
#             raise ValueError("Invalid monitor type")
#         return output

#-------------------------------------------------------

# import asyncio
# import subprocess
# import os
# import logging

# class MonitorService:
#     def __init__(self):
#         self.scripts_dir = os.path.abspath("../Core/scripts")
#         logging.basicConfig(level=logging.INFO)

#     async def run_powershell_script(self, script_name, args=None):
#         """Run a PowerShell script asynchronously."""
#         script_path = os.path.join(self.scripts_dir, script_name)
#         command = ["powershell.exe", "-ExecutionPolicy", "Bypass", "-File", script_path]
#         if args:
#             command.extend(args)

#         logging.info(f"Running PowerShell script: {script_path}")
#         process = await asyncio.create_subprocess_exec(*command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
#         stdout, stderr = await process.communicate()
#         stdout_decoded, stderr_decoded = stdout.decode(), stderr.decode()
#         logging.info(f"PowerShell script output: {stdout_decoded}, error: {stderr_decoded}")
#         return stdout_decoded, stderr_decoded

#     async def start_monitoring(self, monitor_types):
#         """Launches the specified monitoring types asynchronously."""
#         tasks = []
#         if "files" in monitor_types:
#             tasks.append(self.run_powershell_script("monitor_files.ps1"))
#         if "folders" in monitor_types:
#             tasks.append(self.run_powershell_script("monitor_folders.ps1"))
#         if "ips" in monitor_types:
#             tasks.append(self.run_powershell_script("monitor_ips.ps1"))
#         if "emails" in monitor_types:
#             tasks.append(self.run_powershell_script("alerts.ps1"))
#         results = await asyncio.gather(*tasks)
#         return results

#     async def stop_monitoring(self, monitor_type):
#         """Stop monitoring (files, folders, IPs, mails)."""
#         if monitor_type == "files":
#             output = await self.run_powershell_script("stop_monitor_files.ps1")
#         elif monitor_type == "folders":
#             output = await self.run_powershell_script("stop_monitor_folders.ps1")
#         elif monitor_type == "ips":
#             output = await self.run_powershell_script("stop_monitor_ips.ps1")
#         elif monitor_type == "emails":
#             output = await self.run_powershell_script("stop_monitor_emails.ps1")
#         else:
#             raise ValueError("Invalid monitor type")
#         return output


#---------------------------------------------------------
# OUPSSSSSSSSS

# API/app/services/monitor_service.py

import asyncio
import subprocess
import os
import logging
from configs.settings import Config
import psutil
import json

class MonitorService:
    def __init__(self):
        self.scripts_dir = os.path.join(Config.BASE_DIR, "Core", "scripts")
        self.status_file = os.path.join(Config.BASE_DIR, "Core", "data", "status.json")
        logging.basicConfig(level=logging.INFO)

    def _read_status(self):
        try:
            with open(self.status_file, "r") as f:
                return json.load(f)
        except FileNotFoundError:
            return {}
        except json.JSONDecodeError:
            return {}

    def _write_status(self, data):
        try:
            with open(self.status_file, "w") as f:
                json.dump(data, f, indent=4)
            return True
        except Exception as e:
            print(f"Error writing to status file: {e}")
            return False

    async def run_powershell_script(self, script_name, args=None):
        """Run a PowerShell script asynchronously."""
        script_path = os.path.join(self.scripts_dir, script_name)
        command = ["powershell.exe", "-ExecutionPolicy", "Bypass", "-File", script_path]
        if args:
            command.extend(args)

        logging.info(f"Running PowerShell script: {script_path}")
        process = await asyncio.create_subprocess_exec(*command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = await process.communicate()
        stdout_decoded, stderr_decoded = stdout.decode(), stderr.decode()
        logging.info(f"PowerShell script output: {stdout_decoded}, error: {stderr_decoded}")
        return stdout_decoded, stderr_decoded, process.returncode, process.pid

    async def start_monitoring(self, monitor_types):
        """Launches the specified monitoring types asynchronously."""
        tasks = []
        script_map = {
            "files": "monitor_files.ps1",
            "folders": "monitor_folders.ps1",
            "ips": "monitor_ips.ps1",
            "emails": "alerts.ps1"
        }
        results = {}
        for monitor_type in monitor_types:
            if monitor_type in script_map:
                script_name = script_map[monitor_type]
                stdout, stderr, returncode, pid = await self.run_powershell_script(script_name)
                results[monitor_type] = {"stdout": stdout, "stderr": stderr, "returncode": returncode}
                if returncode == 0:
                    self._update_status(script_name, "Running", pid)
            else:
                results[monitor_type] = {"error": "Invalid monitor type"}
        return results

    def _update_status(self, script_name, status, pid=None):
        """Updates the status.json file with the current status of the script."""
        status_data = self._read_status()
        if script_name not in status_data:
            status_data[script_name] = {}
        status_data[script_name]["Status"] = status
        if pid:
            status_data[script_name]["PID"] = pid
        self._write_status(status_data)

    async def stop_monitoring(self, monitor_type):
        """Stop monitoring (files, folders, IPs, mails)."""
        script_map = {
            "files": "monitor_files.ps1",
            "folders": "monitor_folders.ps1",
            "ips": "monitor_ips.ps1",
            "emails": "alerts.ps1"
        }
        if monitor_type not in script_map:
            return {"error": "Invalid monitor type"}, 400

        script_name = script_map[monitor_type]
        status_data = self._read_status()
        script_status = status_data.get(script_name, {})

        pid = script_status.get("PID")
        if not pid:
            return {"error": f"PID for {script_name} not found"}, 400

        try:
            process = psutil.Process(pid)
            process.terminate()
            self._update_status(script_name, "Stopped")
            return {"message": f"{script_name} stopped successfully"}, 200
        except psutil.NoSuchProcess:
            return {"error": f"Process with PID {pid} not found"}, 404
        except Exception as e:
            return {"error": f"An error occurred: {str(e)}"}, 500

    async def stop_all_monitoring(self):
        """Stops all monitoring scripts."""
        status_data = self._read_status()
        script_map = {
            "files": "monitor_files.ps1",
            "folders": "monitor_folders.ps1",
            "ips": "monitor_ips.ps1",
            "emails": "alerts.ps1"
        }
        results = {}
        for monitor_type, script_name in script_map.items():
            script_status = status_data.get(script_name, {})
            pid = script_status.get("PID")
            if pid:
                try:
                    process = psutil.Process(pid)
                    process.terminate()
                    self._update_status(script_name, "Stopped")
                    results[monitor_type] = {"message": f"{script_name} stopped successfully"}
                except psutil.NoSuchProcess:
                    results[monitor_type] = {"error": f"Process with PID {pid} not found"}
                except Exception as e:
                    results[monitor_type] = {"error": f"An error occurred: {str(e)}"}
            else:
                results[monitor_type] = {"message": f"{script_name} not running"}
        return results