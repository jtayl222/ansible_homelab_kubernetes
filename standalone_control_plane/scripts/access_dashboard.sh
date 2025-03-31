#!/bin/bash

DASHBOARD_URL="http://dashboard.192.168.1.85.nip.io"
TOKEN="eyJhbGciOiJSUzI1NiIsImtpZCI6Ikd5MVRSeWpoSVpsc1VmdHEwdHFLQnV5SjNrcXRLUUZna2pkNTFSOGFJT0kifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiLCJrM3MiXSwiZXhwIjoxNzQzNTMyNDUwLCJpYXQiOjE3NDM0NDYwNTAsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiMDMxYjA2ZTctZmYxYy00N2Q3LWFmZTktMDk3ZmIzZTNiOTY5Iiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJkYXNoYm9hcmQtYWRtaW4iLCJ1aWQiOiJmZGZjNjdhNS0zOTA5LTRmNGItOGJhMi02NzVlMTg1MzQ4YjEifX0sIm5iZiI6MTc0MzQ0NjA1MCwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50Omt1YmVybmV0ZXMtZGFzaGJvYXJkOmRhc2hib2FyZC1hZG1pbiJ9.ugkoRoNoAFKw-HCcsEmzJM7RAfyeF2xQT1IwAf_fMvPvmuFWwI0zEIPBC1OC9xjcQpFlYkambOHzymoKptzyOofHL1oqgs4fD7-VipwNq8vCNrxr_3gqUicjPwXZTLCcylY7eCgik6doc0kcWob7bZXkQVsdh3LU5GtlIQGxYjl5xzxVpeW23vTUVSxswfalpDz2JD_dOo8L00GnrEFW2WVdrrMnWklaOsb68iMmKgEacb4JplOtkrzRbzeRNWMuj-dXbowg6fojLOAmyLW4wS3RzAngsk4Ty8W6Tkgl9jX-N1yJx0UJi31oIIPSsCqDPKDkT6BJI8FOucLP-kqrTQ"

echo "===== Kubernetes Dashboard Access ====="
echo "Dashboard URL: ${DASHBOARD_URL}"
echo 
echo "To access the dashboard, use the following token:"
echo
echo "${TOKEN}"
echo
echo "Copy this token to use when prompted by the login screen."
echo "======================================="

# Check if the dashboard is accessible
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" ${DASHBOARD_URL})

if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "302" ]; then
    echo "Dashboard is accessible (HTTP ${HTTP_CODE})."
    echo "Opening dashboard in your browser..."
    
    # Try different methods to open browser based on OS
    if command -v xdg-open &> /dev/null; then
        xdg-open "${DASHBOARD_URL}" &
    elif command -v open &> /dev/null; then
        open "${DASHBOARD_URL}" &
    else
        echo "Could not open browser automatically."
        echo "Please navigate to ${DASHBOARD_URL} manually."
    fi
else
    echo "Dashboard appears to be unavailable (HTTP ${HTTP_CODE})."
    echo "Please check your configuration and try again."
    echo "You can manually access it at: ${DASHBOARD_URL}"
fi
