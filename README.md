# ConceptBox: Concept Design Starter Kit

This repository demonstrates a pattern for software centered around [**concept design**](design/background/concept-design-overview.md), and a structure with an emphasis on legibility. The repository is divided in importance between the `design` and the `src` repositories, where the design documentation drives the development process. Most of the code is generated using an LLM through an approach called Context: a simple structure for composing immutable prompts through an openly-accessible history available in the `context` directory. The application is then entirely constructed out of these two building blocks:

1.  [**Concepts**](design/background/concept-specifications.md): Independent, reusable modules of functionality. Each is associated with a particular concern, and defined by a clear purpose (e.g., authenticating a user, storing a file).
2.  [**Synchronizations**](design/background/implementing-synchronizations.md): Simple rules that define how concepts interact. This is where the application's unique logic lives, orchestrating the concepts to work together (e.g., "when a user successfully logs in, create a session for them").

Concepts are capable of encapsulating concerns such as persistence, the entire network stack, as well as the idea of building on top of a narrow entrypoint like a router: this example application is synthesized out of a flat list of 5 concepts and a set of declarative rules in the form of synchronizations.

## Architecture

This repository is structured into three main partitions:

- **src/:** all source code (TypeScript) and configuration
- **design/:** all design documents (Markdown) used both as documentation and prompts
- **context/:** an immutable history as a mirrored and nested directory of the rest of the repository, with the property that any generated block of text can be linked back to its causal history in terms of context window 

Within the `src/` directory, application code resides entirely within either `src/concepts/` or `src/syncs/`.

More details: [**architecture.md**](design/background/architecture.md)

## What is ConceptBox?

ConceptBox is a backend for a cloud file storage service akin to a mini-Dropbox. It provides API endpoints for:

*   User registration and login.
*   Session-based authentication.
*   Uploading files to a secure cloud backend (Google Cloud Storage).
*   Listing and downloading your own files.
*   Sharing files with other registered users and revoking access.

The key point is that ConceptBox is not a single monolithic application. It is one particular configuration that arises from combining these generic, widely-usable concepts:

*   [`UserAuthentication`](design/concepts/UserAuthentication/UserAuthentication.md): Handles user registration and password verification.
*   [`Sessioning`](design/concepts/Sessioning/Sessioning.md): Manages user login sessions.
*   [`FileUploading`](design/concepts/FileUploading/FileUploading.md): Manages file metadata and interacts with Google Cloud Storage for the actual storage.
*   [`Sharing`](design/concepts/Sharing/Sharing.md): Manages permissions for which users can access which files.

The logic that makes these pieces work together *as ConceptBox* is defined entirely within the synchronization files found in `src/syncs/`.

## Setup and Deployment

Follow these steps to get your own instance of ConceptBox running.

### Prerequisites

*   **Deno**: The application runs on the Deno runtime. [Installation Guide](https://deno.land/manual/getting_started/installation).
*   **MongoDB**: You need a running MongoDB instance and its connection URI. A free cluster on [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) is a great option.

### 1. Clone and Configure

First, clone the repository and create an environment file.

```bash
git clone <repository-url>
cd <repository-name>
cp .env.template .env
```

Now, open the `.env` file and fill in the required values. The configuration is partitioned by the concept that requires it.

### 2. General Application Configuration

These variables are required for the application to connect to the database and run the server.

```dotenv
# .env

# Your MongoDB connection string
MONGODB_URL="mongodb+srv://..."

# The shared concept database name
DB_NAME="MyDB"

# The port the server will listen on
PORT=8000
```

### 3. `FileUploading` Concept Configuration (Google Cloud Storage)

This concept requires a Google Cloud Storage bucket to store files.

**A. Create a GCS Bucket and Service Account**

1.  **Create a Project & Bucket**: In the [Google Cloud Console](https://console.cloud.google.com/), create a new project (or use an existing one) and create a Cloud Storage bucket. Note the **bucket name**.
2.  **Create a Service Account**: In your project, go to **IAM & Admin > Service Accounts** and create a new service account.
3.  **Grant Permissions**: Grant the service account the **"Storage Object Admin"** role.
4.  **Generate a Key**: Create a JSON key for the service account and download it. You will need the values from this file for the variables below.

**Warning:** Treat the downloaded JSON key file as a secret.

**B. Set Environment Variables**

Copy the values from your GCP setup and the downloaded JSON key file into your `.env` file.

```dotenv
# .env

# The name of the GCS bucket you created
FILE_UPLOADING_GCS_BUCKET_NAME="your-bucket-name-here"

# Your Google Cloud project ID
FILE_UPLOADING_GCS_PROJECT_ID="your-gcp-project-id"

# The "client_email" value from the downloaded JSON key file
FILE_UPLOADING_GCS_CLIENT_EMAIL="your-service-account@your-project.iam.gserviceaccount.com"

# The "private_key" value from the downloaded JSON key file.
# It must be enclosed in double quotes to preserve formatting.
FILE_UPLOADING_GCS_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYourPrivateKeyContentHere\n-----END PRIVATE KEY-----\n"
```

**C. Configure CORS**

If you don't have the Google Cloud CLI installed, follow the instructions [here](https://cloud.google.com/sdk/docs/install).

After installation, initialize your Google Cloud account:
```bash
gcloud init
```

Run the following command in your terminal, replacing `[BUCKET_NAME]` with the actual name of your GCS bucket (the one you set in your `.env` file).

```bash
gcloud storage buckets update gs://[BUCKET_NAME] --cors-file=cors.json
```

For example, if your bucket is named `my-awesome-file-bucket`, the command would be:

```bash
gcloud storage buckets update gs://my-awesome-file-bucket --cors-file=cors.json
```

You can check that the configuration was applied correctly by running:

```bash
gcloud storage buckets describe gs://[BUCKET_NAME] --format="json"
```

If you know your stable deployed frontend URL, you should update `cors.json` and scope down the origin.

### 4. Run the Application

Once your `.env` file is configured, you can build the imports and start the server:

```bash
deno run build
deno run start
```

Your ConceptBox API is now live and running on the configured port!

## Requesting: Automatic API Endpoints

The application logic is exposed via a set of API endpoints created by the synchronizations against the `Requesting` concept. 

All requests are `POST` and expect a JSON body.

| Endpoint                                      | Description                                              | Example Body                                            |
| --------------------------------------------- | -------------------------------------------------------- | ------------------------------------------------------- |
| `/api/UserAuthentication/register`            | Create a new user account.                               | `{ "username": "alice", "password": "..." }`            |
| `/api/login`                                  | Log in to get a session ID.                              | `{ "username": "alice", "password": "..." }`            |
| `/api/logout`                                 | Log out and invalidate a session.                        | `{ "session": "..." }`                                  |
| `/api/my-files`                               | List all files owned by the user.                        | `{ "session": "..." }`                                  |
| `/api/FileUploading/requestUploadURL`         | Get a temporary, secure URL to upload a file to.         | `{ "session": "...", "filename": "mydoc.pdf" }`         |
| `/api/FileUploading/confirmUpload`            | Confirm that the file upload to the URL was successful.  | `{ "session": "...", "file": "..." }`                   |
| `/api/download`                               | Get a temporary URL to download a file you have access to. | `{ "session": "...", "file": "..." }`                   |
| `/api/share`                                  | Share one of your files with another user.               | `{ "session": "...", "file": "...", "shareWithUsername": "bob" }` |
| `/api/revoke`                                 | Revoke another user's access to one of your files.       | `{ "session": "...", "file": "...", "revokeForUsername": "bob" }` |

## Exploring the Code

The `design/` documents provide extensive `background/` material on both the overall approach of concept design, as well as example `brainstorming/` sessions and usage of Context to build the application. For every file in the repository proper, there exists a directory of the same name under `context`, with a timestamped history of the evolution of the file. 

**Understanding the Entrypoint:** to understand what drives the server, check out the [**Requesting README**](src/concepts/Requesting/README.md)

**Understanding Concepts:** to understand the broad picture behind concepts, checkout the [**Concept Overview**](design/background/concept-design-overview.md)

**Understanding Synchronizations:** to understand the composition mechanism, checkout [**Implementing Synchronizations**](design/background/implementing-synchronizations.md)

**ConceptBox Implementation:**

*   **`src/concepts/`**: Browse this directory to see how each independent piece of functionality (`Sessioning`, `FileUploading`, etc.) is implemented. Notice how they have no knowledge of each other: conceps strictly cannot import one another.
*   **`src/syncs/`**: The application specific configuration of generic concepts. Open `auth.sync.ts`, `files.sync.ts`, and `sharing.sync.ts` to see declarative rules that connect the concepts and define the API logic. Pay special attention to the `where` clauses, which perform powerful queries and authorization checks across multiple concepts.
