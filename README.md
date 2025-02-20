# GitHub Advanced Security (GHAS) - DefectDojo Integration

¡Hi developer 👋🏻!

This repo is a PoC to integrate GitHub Advanced Security (GHAS) with DefectDojo. I tried to make it as simple as possible, so you can easily adapt it to your needs.

## Github Advanced Security (GHAS) alerts

GitHub Advanced Security (GHAS) provides three types of alerts:

- Security Updates from Dependabot
- Code Scanning Alerts
- Secret Scanning Alerts

Today, DefectDojo only supports the import of Code Scanning Alerts (using SARIF import) and Security Updates from Dependabot using the `GitHub Vulnerability Scan` import. In this repo I will show you how to import the three types of alerts using GitHub Actions.


## Import Dependabot alerts

To import Dependabot alerts, we will use the `GitHub Vulnerability Scan` import. This import is available in DefectDojo since version 2.4.0. I did some reseach using this file `requests/ghas_alerts_requests.http`to see how the query should look like and this is the result:

```
POST https://api.github.com/graphql
Content-Type: application/json
Authorization: Bearer {{ PAT }}
X-REQUEST-TYPE: GraphQL

query ($name: String!, $owner: String!) {  
  repository(owner: $owner, name: $name) {
    nameWithOwner
    url
    vulnerabilityAlerts(first: 20) {
      totalCount
      nodes {
        id
        number
        createdAt
        state
        vulnerableManifestPath
        vulnerableRequirements        
        securityVulnerability {
          package {
            name
          }
          advisory {
            severity
            summary
            description
            references{
              url
            }
            identifiers {
              type
              value
            }
            cvss {
              score     
              vectorString        
            }
            cwes(first: 5) {              
              nodes {
                cweId
                name
                description
              }
            }
          }
        }        
      }
    }
    nameWithOwner
    url
  }
}

{
    "name": "{{ REPO_NAME }}",
    "owner": "{{ OWNER }}"
}
```

With that I created a GitHub Actions workflow that will run every time the Dependabot Updates workflow is triggered. You can see the workflow in the `.github/workflows/after_dependabot_updates.yml` file.

Once we have the alert we need to use DefectDojo API to import the alert. The API endpoint is `/api/v2/import-parse/`. The request should look like this:

```
 curl -X POST "${{ env.DEFECTDOJO_URL }}/import-scan/" \
   -H "Authorization: Token ${{ secrets.DEFECTDOJO_TOKEN }}" \
   -F 'product_name=${{ env.DEFECTDOJO_PRODUCT_NAME }}' \
   -F 'engagement=${{ env.ENGAGEMENT_ID }}' \
   -F 'scan_type="Github Vulnerability Scan"' \
   -F 'file=@dependabot-security-alerts.json'
```

As you can seee the `scan_type` is `Github Vulnerability Scan`, we need the `product_name` and the `engagement` id. The `product_name` is the name of the product in DefectDojo and the `engagement` id is the id of the engagement in DefectDojo. You can get the engagement id using the `/api/v2/engagements/` endpoint.


