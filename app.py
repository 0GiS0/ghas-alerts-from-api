import requests
from getenv import os
from dotenv import load_dotenv

load_dotenv()

GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
REPO_NAME = os.getenv("REPO_NAME")

print(GITHUB_TOKEN)
print(REPO_NAME)

# GITHUB_TOKEN="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"
# REPO_NAME="dragonstone-org/dependabot-poc"


headers = {"Authorization": f"Bearer {GITHUB_TOKEN}",
           "X-GitHub-Api-Version": "2022-11-28"}

params = {"page": 1, "per_page": 100, "state": "open"}
alerts = []

while True:
    response = requests.get(
        url=f"https://api.github.com/repos/{REPO_NAME}/dependabot/alerts",
        headers=headers,
        params=params
    )
    response.raise_for_status()
    response_data = response.json()
    if len(response_data) == 0:
        break
    else:
        params["page"] += 1
    alerts.extend(response_data)
print(alerts)
