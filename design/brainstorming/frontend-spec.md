[@concept-box](concept-box.md)

# Final Synchronizations:

[@auth.sync.ts](/src/syncs/auth.sync.ts)

[@files.sync.ts](/src/syncs/files.sync.ts)

[@sharing.sync.ts](/src/syncs/sharing.sync.ts)

# Frontend specification

Given this application and the current set of synchronizations, follow up by outputting a comprehensive, stand-alone document for an entirely different frontend team who will build the frontend application. 

- Describe briefly the concept and synchronization architecture
- Describe comprehensively the API - from only using POST, to the base URL and paths available, and the shape of each route available through Requesting.
- Encourage anyone/agent reading the document to suggest changes necessary to the backend (e.g. additional concept queries, additional routes, etc.), and to output those suggestions as markdown
- Ensure that anyone reading the document has full context to build a usable application
# response:

Of course. This is a perfect use case for demonstrating the separation of concerns between the backend logic (encapsulated in concepts and syncs) and the public-facing contract for a client application.

Here is a comprehensive, stand-alone API specification document for the "ConceptBox" application, designed for a separate frontend team.

***

# ConceptBox Frontend API Specification

**Version:** 1.0
**Date:** 2023-10-27

## 1. Introduction

Welcome to the ConceptBox project! This document provides all the necessary information for the frontend team to build the client application for ConceptBox, a secure file storage and sharing service.

### 1.1. Application Overview

ConceptBox allows users to:
*   Register for an account and log in.
*   Upload files to secure personal storage.
*   View and manage their uploaded files.
*   Download their files.
*   Share files with other registered users, granting them download access.
*   Revoke sharing access.

### 1.2. Backend Architecture at a Glance

The backend is built using an architecture called **Concept Design**. For the frontend team, you can think of this as a set of highly focused, independent microservices (we call them "Concepts") that each manage one piece of functionality (e.g., `UserAuthentication`, `FileUploading`, `Sharing`).

The API endpoints you will use are the public gateways to the coordinated behavior of these services. This design means the API is highly consistent, but may have a few conventions that differ from a traditional REST API, which are outlined below.

## 2. Global API Conventions

Please read this section carefully, as it applies to **every single API call** you will make.

### 2.1. HTTP Method

**All API endpoints accept only the `POST` method.**

This is a strict architectural convention. Even for operations that semantically feel like a `GET` (e.g., fetching a list of files), you must use `POST`.

### 2.2. Base URL

All API routes are prefixed with the following base URL:
`/api`

### 2.3. Data Format

All request and response bodies are `application/json`. Ensure your requests include the header:
`Content-Type: application/json`

### 2.4. Authentication

ConceptBox uses a session-based authentication model.
1.  A user logs in via the `/api/login` endpoint.
2.  A successful login returns a unique `session` ID (string).
3.  This `session` ID must be stored on the client and included in the request body for all subsequent authenticated endpoints.

### 2.5. Responses

*   **Success (200 OK):** The response body will be a JSON object containing the requested data.
*   **Error:** The response body will be a JSON object with a single key, `error`, containing a descriptive message string. The HTTP status code may vary (e.g., 400, 401, 500), but the shape of the error body is consistent.
    ```json
    {
      "error": "A user with that username already exists."
    }
    ```

## 3. API Endpoints

### 3.1. Authentication

These endpoints manage user accounts and sessions.

#### **Register a New User**
*   **Endpoint:** `POST /api/UserAuthentication/register`
*   **Description:** Creates a new user account.
*   **Authentication:** Not required.
*   **Request Body:**
    ```json
    {
      "username": "alice",
      "password": "secure_password_123"
    }
    ```
*   **Success Response:**
    ```json
    {
      "user": "019a2e14-145c-7002-b3b0-0b81669e9185" // The new user's unique ID
    }
    ```
*   **Error Response Example:**
    ```json
    {
      "error": "A user with the name 'alice' already exists."
    }
    ```

#### **Log In**
*   **Endpoint:** `POST /api/login`
*   **Description:** Authenticates a user and creates a new session for them.
*   **Authentication:** Not required.
*   **Request Body:**
    ```json
    {
      "username": "alice",
      "password": "secure_password_123"
    }
    ```
*   **Success Response:**
    ```json
    {
      "session": "c4a9a2c1-2f0f-4e1d-8f1b-1e7a6b2c8a7d" // The session ID to use for subsequent requests
    }
    ```
*   **Error Response Example:**
    ```json
    {
      "error": "Invalid username or password."
    }
    ```

#### **Log Out**
*   **Endpoint:** `POST /api/logout`
*   **Description:** Invalidates an active session.
*   **Authentication:** Required.
*   **Request Body:**
    ```json
    {
      "session": "c4a9a2c1-2f0f-4e1d-8f1b-1e7a6b2c8a7d"
    }
    ```
*   **Success Response:**
    ```json
    {
      "status": "logged_out"
    }
    ```

### 3.2. File Management

These endpoints handle the file lifecycle.

#### **List My Files**
*   **Endpoint:** `POST /api/my-files`
*   **Description:** Retrieves a list of all files owned by the currently logged-in user.
*   **Authentication:** Required.
*   **Request Body:**
    ```json
    {
      "session": "c4a9a2c1-2f0f-4e1d-8f1b-1e7a6b2c8a7d"
    }
    ```
*   **Success Response:**
    ```json
    {
      "results": [
        {
          "file": "f1a2e14b-c45c-e002-a3b0-f1b8166e9185",
          "filename": "document.pdf"
        },
        {
          "file": "f2b3c4d5-e678-f901-g2h3-i4j5k6l7m8n9",
          "filename": "image.png"
        }
      ]
    }
    ```

#### **Upload a File (Two-Step Process)**

Uploading a file is a two-step process to accommodate direct-to-cloud storage.

**Step 1: Request an Upload URL**
*   **Endpoint:** `POST /api/FileUploading/requestUploadURL`
*   **Description:** Informs the server of an impending upload and receives a temporary, secure URL to upload the file to.
*   **Authentication:** Required.
*   **Request Body:**
    ```json
    {
      "session": "c4a9a2c1-2f0f-4e1d-8f1b-1e7a6b2c8a7d",
      "filename": "vacation_photo.jpg"
    }
    ```
*   **Success Response:**
    ```json
    {
      "file": "f3cde45f-6789-0123-b4c5-d6e7f8a9b0c1", // The new file's ID. Save this!
      "uploadURL": "https://storage.googleapis.com/..." // The presigned URL
    }
    ```

**Step 2: Upload the File Data**
*   This is **not** a call to our API.
*   You must perform an HTTP `PUT` request directly to the `uploadURL` received in Step 1.
*   The body of the `PUT` request should be the raw file data.
*   The `Content-Type` header should match the file's MIME type (e.g., `image/jpeg`).

**Step 3: Confirm the Upload**
*   **Endpoint:** `POST /api/FileUploading/confirmUpload`
*   **Description:** Notifies the server that the file data has been successfully uploaded to the cloud, finalizing the process.
*   **Authentication:** Required.
*   **Request Body:**
    ```json
    {
      "session": "c4a9a2c1-2f0f-4e1d-8f1b-1e7a6b2c8a7d",
      "file": "f3cde45f-6789-0123-b4c5-d6e7f8a9b0c1" // The file ID from Step 1
    }
    ```
*   **Success Response:**
    ```json
    {
      "status": "confirmed"
    }
    ```

#### **Download a File**
*   **Endpoint:** `POST /api/download`
*   **Description:** Gets a temporary, secure URL to download a file's content. This applies to files the user owns or files that have been shared with them.
*   **Authentication:** Required.
*   **Request Body:**
    ```json
    {
      "session": "c4a9a2c1-2f0f-4e1d-8f1b-1e7a6b2c8a7d",
      "file": "f1a2e14b-c45c-e002-a3b0-f1b8166e9185" // The ID of the file to download
    }
    ```
*   **Success Response:**
    ```json
    {
      "downloadURL": "https://storage.googleapis.com/..." // The presigned download URL
    }
    ```

### 3.3. Sharing

These endpoints manage file access for other users.

#### **Share a File**
*   **Endpoint:** `POST /api/share`
*   **Description:** Grants another user permission to download one of your files.
*   **Authentication:** Required.
*   **Request Body:**
    ```json
    {
      "session": "c4a9a2c1-2f0f-4e1d-8f1b-1e7a6b2c8a7d",
      "file": "f1a2e14b-c45c-e002-a3b0-f1b8166e9185", // The ID of the file you own
      "shareWithUsername": "bob" // The username of the user to share with
    }
    ```
*   **Success Response:**
    ```json
    {
      "status": "shared"
    }
    ```
*   **Error Response Example:**
    ```json
    { "error": "User 'bob' not found." }
    // or
    { "error": "Authorization failed: you do not own this file." }
    ```

#### **Revoke Access to a File**
*   **Endpoint:** `POST /api/revoke`
*   **Description:** Removes a user's permission to download one of your files.
*   **Authentication:** Required.
*   **Request Body:**
    ```json
    {
      "session": "c4a9a2c1-2f0f-4e1d-8f1b-1e7a6b2c8a7d",
      "file": "f1a2e14b-c45c-e002-a3b0-f1b8166e9185",
      "revokeForUsername": "bob"
    }
    ```
*   **Success Response:**
    ```json
    {
      "status": "revoked"
    }
    ```

## 4. Call for Feedback

This document is intended to be the single source of truth for the ConceptBox API. As you begin development, you are in the best position to identify gaps or areas for improvement. We encourage and welcome your feedback.

If you believe the API is missing functionality, or if the shape of a request/response could be improved to simplify your work, please let us know.

#### How to Provide Feedback

Please provide suggestions in a markdown document with the following format:

---

### New Endpoint Suggestion: `POST /api/my-shares`

*   **Description:** It would be very helpful to have an endpoint that shows me all the files that other people have shared with me. Currently, I have no way of discovering these files.
*   **Proposed Request Body:**
    ```json
    { "session": "..." }
    ```
*   **Proposed Response Body:**
    ```json
    {
      "shared_files": [
        {
          "file": "...",
          "filename": "project-plan.docx",
          "ownerUsername": "charlie"
        }
      ]
    }
    ```

---

### Change Request: Batch Sharing

*   **Endpoint:** `POST /api/share`
*   **Description:** The current endpoint only allows sharing a file with one user at a time. A common use case would be sharing with multiple team members.
*   **Proposed Change:** Allow `shareWithUsername` to be a string or an array of strings.
    ```json
    {
      "session": "...",
      "file": "...",
      "shareWithUsername": ["bob", "charlie", "diana"]
    }
    ```

---

We look forward to collaborating with you to build a fantastic application