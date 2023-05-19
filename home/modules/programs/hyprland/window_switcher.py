import subprocess
import json
from typing import NamedTuple


class Window(NamedTuple):
    class_name: str
    title: str
    address: str

    def __str__(self) -> str:
        return f"{self.class_name} -- {self.title}"


raw_windows = json.loads(
    subprocess.run(["hyprctl", "clients", "-j"], stdout=subprocess.PIPE).stdout
)
windows = [Window(w["class"], w["title"], w["address"]) for w in raw_windows]
search_list = [f"{i+1} {w}" for i, w in enumerate(windows)]
search_result = subprocess.run(
    ["wofi", "-di"], input="\n".join(search_list), text=True, stdout=subprocess.PIPE
).stdout
selected_window = windows[int(search_result.split(" ")[0]) - 1]
subprocess.run(
    ["hyprctl", "dispatch", "focuswindow", f"address:{selected_window.address}"]
)
