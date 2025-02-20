jq .
Response-1740058048142.json

jq map({title: (.secret_type_display_name + " " + .secret[0:15]), description: (.secret + "\nValidity: " + .validity + "\nPublicly leaked: " + (.publicly_leaked | tostring)), severity: "Critical", found_by: [208], test: 73, active: .publicly_leaked, verified: false,numerical_severity: 3})
Response-1740058048142.json

