import sys
import json
import subprocess

monitor_name = sys.argv[1]
monitor_infos = json.loads(
    subprocess.run(["hyprctl", "monitors", "-j"], stdout=subprocess.PIPE).stdout
)
is_special_displayed_on_monitor = False
for monitor in monitor_infos:
    if monitor["name"] == monitor_name and monitor["specialWorkspace"]["id"] != 0:
        is_special_displayed_on_monitor = True

subprocess.run(["hyprctl", "dispatch", "focusmonitor", monitor_name])

if is_special_displayed_on_monitor:
    subprocess.run(["hyprctl", "dispatch", "workspace", "special"])
