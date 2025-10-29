---
timestamp: 'Wed Oct 29 2025 10:40:38 GMT-0400 (Eastern Daylight Time)'
parent: '[[../20251029_104038.3876f1a0.md]]'
content_id: 14d8f54ce6d5b5c06568525c1f90b8ea7d35063ee417f1cad3a79119406460e4
---

# solution: Configure GCS Bucket CORS Policy

You need to tell your GCS bucket which origins, methods, and headers are allowed. You can do this by creating a simple JSON configuration file and applying it to your bucket using the `gcloud` command-line tool.

### Step 1: Create a CORS configuration file

Create a file named `cors.json` in your project's root directory. This file will define the rules.

```json
[
  {
    "origin": [
      "http://localhost:5173",
      "https://your-production-app-domain.com"
    ],
    "method": [
      "PUT",
      "GET",
      "HEAD"
    ],
    "responseHeader": [
      "Content-Type",
      "Content-Length"
    ],
    "maxAgeSeconds": 3600
  }
]
```

**Explanation of the fields:**

* **`origin`**: An array of domains that are allowed to make requests. I've included your local development server and a placeholder for your future production domain.
* **`method`**: The HTTP methods allowed. `PUT` is essential for the presigned upload URL to work. `GET` and `HEAD` are useful for downloads.
* **`responseHeader`**: A list of headers that the browser is allowed to access in the response from GCS.
* **`maxAgeSeconds`**: How long the browser can cache the result of the preflight `OPTIONS` request (in this case, 1 hour).

### Step 2: Install and Authenticate `gcloud` CLI

If you don't have the Google Cloud CLI installed, follow the instructions [here](https://cloud.google.com/sdk/docs/install).

After installation, authenticate with your Google Cloud account:

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

### Step 3: Apply the CORS Configuration to Your Bucket

Run the following command in your terminal, replacing `[BUCKET_NAME]` with the actual name of your GCS bucket (the one you set in your `.env` file).

```bash
gcloud storage buckets update gs://[BUCKET_NAME] --cors-file=cors.json
```

For example, if your bucket is named `my-awesome-file-bucket`, the command would be:

```bash
gcloud storage buckets update gs://my-awesome-file-bucket --cors-file=cors.json
```

### Step 4: Verify the Configuration (Optional)

You can check that the configuration was applied correctly by running:

```bash
gcloud storage buckets describe gs://[BUCKET_NAME] --format="json"
```

This should print the CORS configuration you just set. After applying this change, your frontend application running on `http://localhost:5173` will be able to successfully upload files to the presigned URLs.
