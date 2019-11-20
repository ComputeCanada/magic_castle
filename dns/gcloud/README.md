In order to deploy dns entries to Google Cloud you will need to
authenticate first. You have two options:
- Using Google Cloud CLI to authenticate
- Using environment variables and service account file

## Authentication with Google Cloud CLI
1. Install the [Google Cloud SDK](https://cloud.google.com/sdk/docs/downloads-interactive)
2. Login to your Google account : `gcloud auth application-default login`

## Environment variables
source a couple environment variable before running terraform.

You will need a json file that contains credentials for a service
account that had permissions to create records in your managed zone
and then run the following commands.

```
export GOOGLE_CREDENTIALS=service-account.json
export GCE_SERVICE_ACCOUNT_FILE=service-account.json
```

This will allow both the google provider and the ACME provider to
be able to commit records in your managed zone.
