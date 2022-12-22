import requests

vm_name = "vm1"

metadata_url = "http://169.254.169.254/metadata/instance?api-version=2020-06-01"

headers = {
    "Metadata": "true"
}

response = requests.get(metadata_url, headers=headers)

if response.status_code == 200:
    # If the request was successful, print the metadata
    metadata = response.json()
    print(metadata)
else:
    # If the request was unsuccessful, print an error message
    print(f"Error: {response.status_code}")
