import asyncio
import subprocess
import os

class MonitorService:
    def __init__(self):
        self.scripts_dir = "../Core/scripts"

    async def run_powershell_script(self, script_name, args=None):
        """
        Run a PowerShell script asynchronously.
        """
        script_path = os.path.join(self.scripts_dir, script_name)
        command = ["powershell.exe", "-ExecutionPolicy", "Bypass", "-File", script_path]
        if args:
            command.extend(args)

        process = await asyncio.create_subprocess_exec(*command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = await process.communicate()
        return stdout.decode(), stderr.decode()

    async def start_monitoring(self, monitor_types):
        """
        Launches the specified monitoring types asynchronously.
        """
        tasks = []
        if "files" in monitor_types:
            tasks.append(self.run_powershell_script("monitor_files.ps1"))
        if "folders" in monitor_types:
            tasks.append(self.run_powershell_script("monitor_folders.ps1"))
        if "ips" in monitor_types:
            tasks.append(self.run_powershell_script("monitor_ips.ps1"))
        if "emails" in monitor_types:
            tasks.append(self.run_powershell_script("alerts.ps1"))
        results = await asyncio.gather(*tasks)
        return results

    async def stop_monitoring(self, monitor_type):
        """
        Stop monitoring (files, folders, IPs, mails).
        """
        if monitor_type == "files":
            output = await self.run_powershell_script("stop_monitor_files.ps1")
        elif monitor_type == "folders":
            output = await self.run_powershell_script("stop_monitor_folders.ps1")
        elif monitor_type == "ips":
            output = await self.run_powershell_script("stop_monitor_ips.ps1")
        elif monitor_type == "emails":
            output = await self.run_powershell_script("stop_monitor_emails.ps1")
        else:
            raise ValueError("Invalid monitor type")
        return output