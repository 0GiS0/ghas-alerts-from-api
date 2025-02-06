```bash
source .env


curl -L \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/dragonstone-org/dependabot-poc/dependabot/alerts
  ```


  ## Using GitHub CLI




  ```bash
gh api /repos/${{ github.repository }}/code-scanning/alerts --paginate --jq '.items[] | {name: .rule.name, level: .rule.severity, url: .html_url}'