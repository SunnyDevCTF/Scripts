import subprocess
import time
from datetime import datetime

IMAGE_DIR = "/var/log/security-control/images"
LOG_FILE = "/var/log/security-control/events.log"

def take_photo(user):
    ts = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")

    path = f"{IMAGE_DIR}/fail_{user}_{ts}.jpg"

    subprocess.run([
        "fswebcam",
        "-r", "1280x720",
        "--no-banner",
        path
    ])

    with open(LOG_FILE, "a") as f:
        f.write(f"{ts} | FAILED LOGIN | user={user} | photo={path}\n")

def monitor():
    print("[SecurityWatcher] running...")

    process = subprocess.Popen(
        ["journalctl", "-f", "-o", "short"],
        stdout=subprocess.PIPE,
        text=True
    )

    triggered_users = set()

    for line in process.stdout:
        line_lower = line.lower()

        # Fedora / systemd login failure patterns
        if "failed password" in line_lower or "authentication failure" in line_lower:
            
            # versuche user zu extrahieren
            user = "unknown"

            for part in line.split():
                if "user=" in part:
                    user = part.split("=")[-1]

            # Anti Spam
            if user not in triggered_users:
                triggered_users.add(user)
                take_photo(user)

                # Reset nach 10 Sekunden
                time.sleep(10)
                triggered_users.clear()

if __name__ == "__main__":
    monitor()
