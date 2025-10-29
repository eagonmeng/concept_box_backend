[@frontend-spec](../brainstorming/frontend-spec.md)

# add:

I'd like to actually be able to see the files shared with me. Add one sync to files.sync.ts, and:

- Write the specification
- Write the TypeScript implementation
- Write a blurb to tell the frontend team how this integration should be done
# response:

Of course. This is an excellent and necessary feature for the application, and it serves as a perfect example of a read-only endpoint that performs a complex join across multiple concepts.

Here are the required additions.

***

### 1. Synchronization Specification

This new synchronization defines the logic for fetching files shared with a user. It requires new queries on several concepts (`Sharing`, `FileUploading`, and `UserAuthentication`) to gather all the necessary information.

```sync
// file: src/syncs/files.sync.ts

//-- List files shared with the current user --//
sync ListSharedFilesRequest
when
    Requesting.request (path: "/my-shares", session): (request)
where
    // 1. Authenticate the user from their session
    in Sessioning: _getUser(session) gets user
    // 2. Find all file IDs shared with this user
    in Sharing: _getFilesSharedWithUser(user) gets file
    // 3. For each shared file, get its filename and its owner's ID
    in FileUploading: _getFilename(file) gets filename
    in FileUploading: _getOwner(file) gets owner
    // 4. Get the owner's username from their ID
    in UserAuthentication: _getUsername(owner) gets ownerUsername
    // 5. Collect the enriched data into a single results array
    results is collection of {file, filename, ownerUsername}
then
    Requesting.respond (request, results)
```

***

### 2. TypeScript Implementation

Add the following code to the end of the `src/syncs/files.sync.ts` file. Note that it requires adding `UserAuthentication` to the import statement at the top of the file.

```typescript
// Add UserAuthentication to the import line at the top of src/syncs/files.sync.ts
// e.g. import { Requesting, Sessioning, FileUploading, Sharing, UserAuthentication } from "@concepts";

export const ListSharedFilesRequest: Sync = ({ request, session, user, file, filename, owner, ownerUsername, results }) => ({
  when: actions([Requesting.request, { path: "/my-shares", session }, { request }]),
  where: async (frames) => {
    const originalFrame = frames[0];
    
    // 1. Authenticate user
    frames = await frames.query(Sessioning._getUser, { session }, { user });
    
    // If the session is invalid, return an empty list immediately.
    if (frames.length === 0) {
      return new Frames({...originalFrame, [results]: []});
    }
    
    // 2. Find files shared with the user
    frames = await frames.query(Sharing._getFilesSharedWithUser, { user }, { file });
    
    // If no files are shared, return an empty list.
    if (frames.length === 0) {
      return new Frames({...originalFrame, [results]: []});
    }

    // 3. & 4. Enrich each file with its details
    frames = await frames.query(FileUploading._getFilename, { file }, { filename });
    frames = await frames.query(FileUploading._getOwner, { file }, { owner });
    frames = await frames.query(UserAuthentication._getUsername, { user: owner }, { username: ownerUsername });

    // 5. Collect into final response structure
    return frames.collectAs([file, filename, ownerUsername], results);
  },
  then: actions([Requesting.respond, { request, results }]),
});
```

***

### 3. Frontend Team Documentation Update

Here is a stand-alone section to be added to the `ConceptBox Frontend API Specification` document.

---

### **Endpoint Addition:** List Files Shared With Me

Based on feedback during development, we have added a new endpoint to allow users to see which files have been shared *with them* by other users. This is crucial for discovering content and complements the existing `/api/my-files` endpoint.

#### **List Files Shared With Me**

*   **Endpoint:** `POST /api/my-shares`
*   **Description:** Retrieves a list of all files that other users have explicitly shared with the currently logged-in user.
*   **Authentication:** Required.
*   **Request Body:**
    ```json
    {
      "session": "c4a9a2c1-2f0f-4e1d-8f1b-1e7a6b2c8a7d"
    }
    ```
*   **Success Response:** The response is a JSON object containing a `results` array. Each object in the array represents a shared file and includes the file's ID, its name, and the username of the person who owns and shared it.
    ```json
    {
      "results": [
        {
          "file": "a1b2c3d4-e5f6-a7b8-c9d0-e1f2a3b4c5d6",
          "filename": "Project Brief Q4.docx",
          "ownerUsername": "bob"
        },
        {
          "file": "f9e8d7c6-b5a4-f3e2-d1c0-b9a8f7e6d5c4",
          "filename": "team_photo.png",
          "ownerUsername": "charlie"
        }
      ]
    }
    ```