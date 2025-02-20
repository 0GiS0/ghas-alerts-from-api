# 1. Read the input file and store it as a JSON
FILE_NAME=Response-1740058048142.http

# 2. The fields DefectDojo needs to add a finding are:
#    - title
#    - description
#    - severity
#    - numerical_severity
#    - cwe
#    - cwe_id
#    - references
#    - tags
#    - static_finding
#    - dynamic_finding
#    - false_p
#    - duplicate
#    - active
#    - verified
#    - unique_id_from_tool
#    - component_name
#    - component_version
#    - file_path
#    - line_number

# 3. We have to map the fields from the input file to the fields DefectDojo needs. This should be:
# - title: secret_type_display_name + the first 15 characteres of the secret field
# - description: hardcoded text for now
# - severity: "Critical"

JSON=$(cat $FILE_NAME | jq -r 'map({title: (.secret_type_display_name + " " + .secret[0:15]), description: "hardcoded text", severity: "Critical"})')

# 4. Iterate over the JSON and send every finding to DefectDojo
DEFECT_DOJO_API_KEY=2126ab9137fba34eeb7cc3e48509db52fbca911d
DEFECT_DOJO_API_URL=http://localhost:8080

for row in $(echo "${JSON}" | jq -r '.[] | @base64'); do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }

    TITLE=$(_jq '.title')
    DESCRIPTION=$(_jq '.description')
    SEVERITY=$(_jq '.severity')

    # 5. Send the finding to DefectDojo
    curl -X POST \
        -H "Authorization: Token $DEFECT_DOJO_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{
            "title": "'"$TITLE"'",
            "description": "'"$DESCRIPTION"'",
            "severity": "'"$SEVERITY"'"
        }' \
        "$DEFECT_DOJO_API_URL/api/v2/findings/"
done


