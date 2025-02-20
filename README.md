# GitHub Advanced Security (GHAS) - DefectDojo Integration

¡Hi developer 👋🏻!

This repo is a PoC to integrate GitHub Advanced Security (GHAS) with DefectDojo. I tried to make it as simple as possible, so you can easily adapt it to your needs.

## Github Advanced Security (GHAS) alerts

GitHub Advanced Security (GHAS) provides three types of alerts:

- Security Updates from Dependabot
- Code Scanning Alerts
- Secret Scanning Alerts

Today, DefectDojo only supports the import of Code Scanning Alerts (using SARIF import) and Security Updates from Dependabot using the `GitHub Vulnerability Scan` import. In this repo I will show you how to import the three types of alerts using GitHub Actions.


## Pre-requisites

For this PoC I clone DefectDojo and I expose it using some tunnel like ngrok or localtunnel. You can use any other method to expose your DefectDojo instance. And then I added a secret to my repo called `DEFECTDOJO_URL`with the URL that the tunnel exposes. I also added a secret
called `DEFECTDOJO_TOKEN` with the DefectDojo API token. You can create a DefectDojo API token in your user profile.

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

Once we have the alert we need to use DefectDojo API to import the alert. The API endpoint is `/api/v2/import-scan/`. The request should look like this:

```
 curl -X POST "${{ env.DEFECTDOJO_URL }}/import-scan/" \
   -H "Authorization: Token ${{ secrets.DEFECTDOJO_TOKEN }}" \
   -F 'product_name=${{ env.DEFECTDOJO_PRODUCT_NAME }}' \
   -F 'engagement=${{ env.ENGAGEMENT_ID }}' \
   -F 'scan_type="Github Vulnerability Scan"' \
   -F 'file=@dependabot-security-alerts.json'
```

As you can seee the `scan_type` is `Github Vulnerability Scan`, we need the `product_name` and the `engagement` id. The `product_name` is the name of the product in DefectDojo and the `engagement` id is the id of the engagement in DefectDojo. You can get the engagement id using the `/api/v2/engagements/` endpoint.


# Import Code Scanning Alerts

Although there is no an specific import for Code Scanning Alerts, we can use the `SARIF` import. In this repo, everytime the CodeQL workflow is triggered, we upload the SARIF file to DefectDojo. The workflow is in the `.github/workflows/codeql_and_defectdojo.yml` file. The upload is done using the `/api/v2/import-scan/` endpoint. The request should look like this:

```
    - name: Upload Results to DefectDojo
      run: |
        curl -X POST "${{ env.DEFECTDOJO_URL }}/import-scan/" \
        -H "Authorization: Token ${{ secrets.DEFECTDOJO_TOKEN }}" \
        -F 'product_name=${{ env.DEFECTDOJO_PRODUCT_NAME }}' \
        -F 'engagement=${{ env.ENGAGEMENT_ID }}' \
        -F 'scan_type="SARIF"' \
        -F 'file=@/home/runner/work/${{ env.REPO_NAME }}/results/${{matrix.language}}.sarif'

``` 

In this case the `scan_type` is `SARIF`, we need the `product_name` and the `engagement` id. The `product_name` is the name of the product in DefectDojo and the `engagement` id is the id of the engagement in DefectDojo. You can get the engagement id using the `/api/v2/engagements/` endpoint.

# Import Secret Scanning Alerts

To import Secret Scanning Alerts, we cannot use an import but we can create the finding directly. The workflow is in the `.github/workflows/codeql_and_defectdojo.yml` file. What I am doing is getting the secrets alerts using the REST API:

```
      - name: Get secrets
        run: |
          curl  \
          --url https://api.github.com/repos/0gis0/import-ghas-to-defectdojo/secret-scanning/alerts \
          --header "Authorization: Bearer ${{ steps.generate-token.outputs.token }}" \
          --header 'content-type: application/json' > secrets.json
```

And then I format the alerts to the DefectDojo format using jq:

```
      - name: Convert secrets to a valid json
        run: |
          JSON=$(cat secrets.json | jq -c --arg TEST_ID "$TEST_ID" --arg TEST_TYPE_ID "$TEST_TYPE_ID_FOR_SECRET_SCANNING" 'map({title: (.secret_type_display_name + " " + .secret[0:15]), description: (.secret + "\nValidity: " + .validity + "\nPublicly leaked: " + (.publicly_leaked | tostring)), severity: "Critical", found_by: [($TEST_TYPE_ID | tonumber)], test: ($TEST_ID | tonumber), active: .publicly_leaked, verified: false, numerical_severity: 3})')
          echo $JSON > secrets-to-defectdojo.json

```


and then we send them to DefectDojo:

```

      - name: Send them to DefectDojo
        run: |

          # Iterate for each secret

          for secret in $(jq -r '. | keys | .[]' secrets-to-defectdojo.json); do

            echo "Sending secret # $secret"
            echo "$(jq -c ".[$secret]" secrets-to-defectdojo.json)"
            DATA=$(jq -c ".[$secret]" secrets-to-defectdojo.json)

            curl --request POST --url ${{ env.DEFECTDOJO_URL }}/findings/ \
            --header "authorization: Token ${{ secrets.DEFECTDOJO_TOKEN }}" \
            --header 'content-type: application/json' \
            --data "$DATA"

          done
```

Happy hacking! 🐱‍👤