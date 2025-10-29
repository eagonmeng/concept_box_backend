[@sync-background](../tools/sync-background.md)

# Creating an Example App

I'm teaching a class on specifically how to write synchronizations, and their interesting properties. I'd like to create an example app:

- Each concept is interesting on its own and could be widely used
- Example concepts: Sessioning, Authenticating, FileUploading, etc.
- All passthrough routes are to be excluded by default
- There are interesting synchronizations that show various properties:
  - Synchronizations that explicitly model the necessary passthrough routes
  - A "composite" request with a path that is more semantic, rather than pointing at a Concept.action
  - Maybe a synchronization with an interesting join between queries of multiple concepts in the `where`

I'm thinking some sort of authenticated file uploading app, that allows easy personal file storage and file sharing could be an potential candidate. 

# response:

Of course. This is an excellent project for demonstrating the power and elegance of the concept design methodology, particularly the role of synchronizations.

### App Idea

1.  **Authenticated File Sharing ("ConceptBox")**: This is your suggestion, and it's a very strong candidate.
    *   **Concepts**: `UserAuthentication`, `Sessioning`, `FileStorage`, `Sharing`.
    *   **Interesting Syncs**:
        *   **Composite Request**: A user logs in (`UserAuthentication.login`), which upon success triggers the creation of a session (`Sessioning.create`).
        *   **Authorization Join**: To share a file, a sync must join state from three concepts: verify the requester's session (`Sessioning`), confirm they own the file (`FileStorage`), and find the user they want to share with by username (`UserAuthentication`).
        *   **Mimicked Passthrough**: A request to `/files/upload` with a valid session directly triggers `FileStorage.upload`.


### App: ConceptBox

The **Authenticated File Sharing** app is the ideal choice. It's universally understood, inherently requires authentication and authorization, and provides a natural and compelling scenario for a multi-concept join in a `where` clause.

Here are the complete specifications for the "ConceptBox" concepts.

---

# Concept Specifications

## concept: UserAuthentication [User]

*   **purpose**: To securely verify a user's identity based on credentials.
*   **principle**: If you register with a unique username and a password, and later provide the same credentials to log in, you will be successfully identified as that user.
*   **state**:
    *   a set of `User`s with
        *   a `username` String (unique)
        *   a `passwordHash` String
*   **actions**:
    *   `register (username: String, password: String): (user: User)`
        *   **requires**: no User exists with the given `username`.
        *   **effects**: creates a new User `u`; sets their `username` and a hash of their `password`; returns `u` as `user`.
    *   `register (username: String, password: String): (error: String)`
        *   **requires**: a User already exists with the given `username`.
        *   **effects**: returns an error message.
    *   `login (username: String, password: String): (user: User)`
        *   **requires**: a User exists with the given `username` and the `password` matches their `passwordHash`.
        *   **effects**: returns the matching User `u` as `user`.
    *   `login (username: String, password: String): (error: String)`
        *   **requires**: no User exists with the given `username` or the `password` does not match.
        *   **effects**: returns an error message.
*   **queries**:
    *   `_getUserByUsername (username: String): (user: User)`
        *   **requires**: a User with the given `username` exists.
        *   **effects**: returns the corresponding User.

## concept: Sessioning [User, Session]

*   **purpose**: To maintain a user's logged-in state across multiple requests without re-sending credentials.
*   **principle**: After a user is authenticated, a session is created for them. Subsequent requests using that session's ID are treated as being performed by that user, until the session is deleted (logout).
*   **state**:
    *   a set of `Session`s with
        *   a `user` User
*   **actions**:
    *   `create (user: User): (session: Session)`
        *   **requires**: true.
        *   **effects**: creates a new Session `s`; associates it with the given `user`; returns `s` as `session`.
    *   `delete (session: Session): ()`
        *   **requires**: the given `session` exists.
        *   **effects**: removes the session `s`.
*   **queries**:
    *   `_getUser (session: Session): (user: User)`
        *   **requires**: the given `session` exists.
        *   **effects**: returns the user associated with the session.

## concept: FileStorage [User, File]

*   **purpose**: To store and manage files, with a clear notion of ownership.
*   **principle**: When a user uploads a file, they become its owner. The owner can later retrieve or delete the file.
*   **state**:
    *   a set of `File`s with
        *   an `owner` User
        *   a `filename` String
        *   a `content` String (or binary data)
*   **actions**:
    *   `upload (owner: User, filename: String, content: String): (file: File)`
        *   **requires**: true.
        *   **effects**: creates a new File `f`; sets its `owner`, `filename`, and `content`; returns `f` as `file`.
    *   `delete (file: File): ()`
        *   **requires**: the given `file` exists.
        *   **effects**: removes the file `f`.
*   **queries**:
    *   `_getOwner (file: File): (owner: User)`
        *   **requires**: the given `file` exists.
        *   **effects**: returns the owner of the file.
    *   `_getFileContent (file: File): (filename: String, content: String)`
        *   **requires**: the given `file` exists.
        *   **effects**: returns the filename and content of the file.
    *   `_getFilesByOwner (owner: User): (file: File, filename: String)`
        *   **requires**: the given `owner` exists.
        *   **effects**: returns all files owned by the user, along with their filenames.

## concept: Sharing [User, File]

*   **purpose**: To allow file owners to grant access to other users.
*   **principle**: A file's owner can share it with another user, who can then access it. If the owner revokes access, the other user can no longer access it.
*   **state**:
    *   a set of `File`s with
        *   a `sharedWith` set of User
*   **actions**:
    *   `shareWithUser (file: File, user: User): ()`
        *   **requires**: `user` is not already in the `sharedWith` set for `file`.
        *   **effects**: adds the `user` to the `sharedWith` set for `file`.
    *   `revokeAccess (file: File, user: User): ()`
        *   **requires**: `user` is in the `sharedWith` set for `file`.
        *   **effects**: removes the `user` from the `sharedWith` set for `file`.
*   **queries**:
    *   `_hasAccess (file: File, user: User): (access: Boolean)`
        *   **requires**: `file` and `user` exist.
        *   **effects**: returns `true` if the `user` is the owner of the `file` (checked via `FileStorage`) OR if the `user` is in the `sharedWith` set for the `file`. *Note: This query implies a cross-concept read during implementation, which is a powerful pattern.* A pure version would require the sync to do the join. Let's make it pure for a better example.
    *   `_isSharedWith (file: File, user: User): (access: Boolean)` (Revised pure query)
        *   **requires**: `file` and `user` exist.
        *   **effects**: returns `true` if the `user` is in the `sharedWith` set for the `file`, false otherwise.

---

# update:

We will be using Google Cloud Storage for uploading files, and slightly modify the concept specification. Namely, we want the actual storage to be handled by the encapsulated GCS API inside the concept, and work primarily off presigned URLs. This will mean we'll need to split the uploading actions into some sort of action for generating and returning a presigned URL for uploading by the client, and then another action for the client to call to confirm after the file was uploaded, so that the concept knows the file is available. Update the `FileStorage` concept to the `FileUploading` concept with these changes in mind.

# response:

Excellent. Using a cloud storage provider like GCS and presigned URLs is a much more scalable and robust approach. This is a perfect example of how a concept can encapsulate complex external interactions while presenting a clean, purposeful API to the rest of the application.

This change shifts the concept's responsibility from storing the file *data* to managing file *metadata* and *access control*. The single `upload` action is now correctly split into a two-phase process: requesting permission to upload, and confirming a successful upload.

Here is the updated specification for the `FileUploading` concept.

***

## concept: FileUploading \[User, File]

*   **purpose**: To manage the lifecycle and metadata of user-owned files stored in an external cloud service.
*   **principle**: If a user requests to upload a file, they receive a unique, temporary URL. After they upload their file directly to that URL and confirm the upload with the system, the file is officially recorded as theirs and can be retrieved later via another temporary download URL.
*   **state**:
    *   a set of `File`s with
        *   an `owner` User
        *   a `filename` String
        *   a `storagePath` String (e.g., the path/key of the object in the GCS bucket)
        *   a `status` String (values: "pending", "uploaded")
*   **actions**:
    *   `requestUploadURL (owner: User, filename: String): (file: File, uploadURL: String)`
        *   **requires**: true.
        *   **effects**: creates a new File `f` with status `pending`, owner `owner`, and filename `filename`; generates a unique `storagePath` for `f`; generates a presigned GCS upload URL corresponding to that path; returns the new file's ID and the URL.
    *   `confirmUpload (file: File): ()`
        *   **requires**: a File `f` exists and its status is "pending".
        *   **effects**: sets the status of `f` to "uploaded".
    *   `confirmUpload (file: File): (error: String)`
        *   **requires**: no File `f` exists or its status is not "pending".
        *   **effects**: returns an error message.
    *   `delete (file: File): ()`
        *   **requires**: the given `file` exists.
        *   **effects**: removes the file record `f` from the state. *Additionally, it triggers the deletion of the corresponding object from the external GCS bucket.*
*   **queries**:
    *   `_getOwner (file: File): (owner: User)`
        *   **requires**: the given `file` exists.
        *   **effects**: returns the owner of the file.
    *   `_getDownloadURL (file: File): (downloadURL: String)`
        *   **requires**: the given `file` exists and its status is "uploaded".
        *   **effects**: generates a short-lived, presigned GCS download URL for the file `f` and returns it.
    *   `_getFilesByOwner (owner: User): (file: File, filename: String)`
        *   **requires**: the given `owner` exists.
        *   **effects**: returns all files owned by the user with status "uploaded", along with their filenames.

# Synchronizations

Great, now create the complete set of synchronizations that generates the app. For requests that are similar to passthrough routes, keep the path in the form of `/{Concept}/{action or query}`. Start by defining the synchronization specifications, then create the implementation.
# response:

Of course. Here are the complete synchronization specifications and their corresponding TypeScript implementations for your "ConceptBox" application. This setup fully realizes the application logic by orchestrating the independent concepts you've designed.

***

# Synchronization Specifications

These specifications describe the desired behavior of the application's API endpoints. They are grouped logically into files that handle authentication, file management, and sharing.

## file: src/syncs/auth.sync.ts

```sync
//-- User Registration --//
sync RegisterRequest
when
    Requesting.request (path: "/UserAuthentication/register", username, password): (request)
then
    UserAuthentication.register (username, password)

sync RegisterResponseSuccess
when
    Requesting.request (path: "/UserAuthentication/register"): (request)
    UserAuthentication.register (): (user)
then
    Requesting.respond (request, user)

sync RegisterResponseError
when
    Requesting.request (path: "/UserAuthentication/register"): (request)
    UserAuthentication.register (): (error)
then
    Requesting.respond (request, error)

//-- User Login & Session Creation (Composite Action) --//
sync LoginRequest
when
    Requesting.request (path: "/login", username, password): (request)
then
    UserAuthentication.login (username, password)

sync LoginSuccessCreatesSession
when
    UserAuthentication.login (): (user)
then
    Sessioning.create (user)

sync LoginResponseSuccess
when
    Requesting.request (path: "/login"): (request)
    // We match on the login success and the subsequent session creation it caused
    UserAuthentication.login (): (user)
    Sessioning.create (user): (session)
then
    Requesting.respond (request, session)

sync LoginResponseError
when
    Requesting.request (path: "/login"): (request)
    UserAuthentication.login (): (error)
then
    Requesting.respond (request, error)

//-- User Logout --//
sync LogoutRequest
when
    Requesting.request (path: "/logout", session): (request)
where
    // Authorize the request: a valid session must exist
    in Sessioning: _getUser(session) gets user
then
    Sessioning.delete (session)

sync LogoutResponse
when
    Requesting.request (path: "/logout"): (request)
    Sessioning.delete (): ()
then
    Requesting.respond (request, status: "logged_out")
```

## file: src/syncs/files.sync.ts

```sync
//-- Phase 1: Request Upload URL (Mimicked Passthrough) --//
sync RequestUploadURL
when
    Requesting.request (path: "/FileUploading/requestUploadURL", session, filename): (request)
where
    in Sessioning: _getUser(session) gets owner
then
    FileUploading.requestUploadURL (owner, filename)

sync RequestUploadURLResponse
when
    Requesting.request (path: "/FileUploading/requestUploadURL"): (request)
    FileUploading.requestUploadURL (): (file, uploadURL)
then
    Requesting.respond (request, file, uploadURL)

//-- Phase 2: Confirm Upload (Authorized) --//
sync ConfirmUploadRequest
when
    Requesting.request (path: "/FileUploading/confirmUpload", session, file): (request)
where
    // Authenticate and Authorize: user making request must own the file
    in Sessioning: _getUser(session) gets user
    in FileUploading: _getOwner(file) gets owner
    user is owner
then
    FileUploading.confirmUpload (file)

sync ConfirmUploadResponseSuccess
when
    Requesting.request (path: "/FileUploading/confirmUpload"): (request)
    FileUploading.confirmUpload (): ()
then
    Requesting.respond (request, status: "confirmed")

sync ConfirmUploadResponseError
when
    Requesting.request (path: "/FileUploading/confirmUpload"): (request)
    FileUploading.confirmUpload (): (error)
then
    Requesting.respond (request, error)

//-- List User's Files (Composite Semantic Request) --//
sync ListMyFilesRequest
when
    Requesting.request (path: "/my-files", session): (request)
where
    in Sessioning: _getUser(session) gets owner
    in FileUploading: _getFilesByOwner(owner) gets file, filename
    // Collect all file/filename pairs into a single 'results' array
    results is collection of {file, filename}
then
    Requesting.respond (request, results)

//-- Download a File (Complex Authorization) --//
sync DownloadFileRequest
when
    Requesting.request (path: "/download", session, file): (request)
where
    in Sessioning: _getUser(session) gets user
    in FileUploading: _getOwner(file) gets owner
    in Sharing: _isSharedWith(file, user) gets isShared
    // Authorization: User must be owner OR have the file shared with them
    user is owner OR isShared is true
    // If authorized, get the download URL
    in FileUploading: _getDownloadURL(file) gets downloadURL
then
    Requesting.respond (request, downloadURL)
```

## file: src/syncs/sharing.sync.ts

```sync
//-- Share a File (Multi-Concept Join) --//
sync ShareFileRequest
when
    Requesting.request (path: "/share", session, file, shareWithUsername): (request)
where
    // 1. Authenticate the requester
    in Sessioning: _getUser(session) gets requester
    // 2. Authorize: requester must own the file
    in FileUploading: _getOwner(file) gets owner
    requester is owner
    // 3. Find the target user to share with
    in UserAuthentication: _getUserByUsername(shareWithUsername) gets targetUser
then
    Sharing.shareWithUser (file, targetUser)

sync ShareFileResponse
when
    Requesting.request (path: "/share"): (request)
    Sharing.shareWithUser (): ()
then
    Requesting.respond (request, status: "shared")

//-- Revoke Access to a File --//
sync RevokeAccessRequest
when
    Requesting.request (path: "/revoke", session, file, revokeForUsername): (request)
where
    in Sessioning: _getUser(session) gets requester
    in FileUploading: _getOwner(file) gets owner
    requester is owner
    in UserAuthentication: _getUserByUsername(revokeForUsername) gets targetUser
then
    Sharing.revokeAccess (file, targetUser)

sync RevokeAccessResponse
when
    Requesting.request (path: "/revoke"): (request)
    Sharing.revokeAccess (): ()
then
    Requesting.respond (request, status: "revoked")
```

***
