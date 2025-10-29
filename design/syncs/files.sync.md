# Files Synchronizations

**concepts:** `Requesting`, `Sessioning`, `FileUploading`, `Sharing`

These synchronizations describe the heart of the application, and involve basic file upload/download flows as well as authorization for these operations.

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

# file: src/syncs/files.sync.ts

This file handles the multi-phase file upload process, listing files, and downloading files with authorization.

```typescript
import { actions, Sync } from "@engine";
import { FileUploading, Requesting, Sessioning, Sharing } from "@concepts";

//-- Phase 1: Request Upload URL --//
export const RequestUploadURL: Sync = ({ request, session, filename, user }) => ({
  when: actions([
    Requesting.request,
    { path: "/FileUploading/requestUploadURL", session, filename },
    { request },
  ]),
  where: (frames) => {
    // Authenticate: Get the user from the session.
    return frames.query(Sessioning._getUser, { session }, { user });
  },
  then: actions([
    // The 'requestUploadURL' action requires an 'owner'. We provide the 'user'
    // variable for that parameter.
    FileUploading.requestUploadURL,
    { owner: user, filename },
  ]),
});

export const RequestUploadURLResponse: Sync = (
  { request, file, uploadURL },
) => ({
  when: actions(
    [Requesting.request, { path: "/FileUploading/requestUploadURL" }, { request }],
    [FileUploading.requestUploadURL, {}, { file, uploadURL }],
  ),
  then: actions([Requesting.respond, { request, file, uploadURL }]),
});

//-- Phase 2: Confirm Upload --//
export const ConfirmUploadRequest: Sync = ({ request, session, file, user, owner }) => ({
  when: actions([
    Requesting.request,
    { path: "/FileUploading/confirmUpload", session, file },
    { request },
  ]),
  where: async (frames) => {
    // 1. Authenticate: Get the user making the request from the session.
    frames = await frames.query(Sessioning._getUser, { session }, { user });
    // 2. Authorize: Get the owner of the file being confirmed.
    frames = await frames.query(FileUploading._getOwner, { file }, { owner });
    // 3. Filter: Only proceed if the requester is the owner.
    return frames.filter(($) => $[user] === $[owner]);
  },
  then: actions([FileUploading.confirmUpload, { file }]),
});

export const ConfirmUploadResponseSuccess: Sync = ({ request }) => ({
  when: actions(
    [Requesting.request, { path: "/FileUploading/confirmUpload" }, { request }],
    [FileUploading.confirmUpload, {}, {}],
  ),
  then: actions([Requesting.respond, { request, status: "confirmed" }]),
});

export const ConfirmUploadResponseError: Sync = ({ request, error }) => ({
  when: actions(
    [Requesting.request, { path: "/FileUploading/confirmUpload" }, { request }],
    [FileUploading.confirmUpload, {}, { error }],
  ),
  then: actions([Requesting.respond, { request, error }]),
});

//-- List User's Files --//
export const ListMyFilesRequest: Sync = ({ request, session, user, file, filename, results }) => ({
  when: actions([Requesting.request, { path: "/my-files", session }, { request }]),
  where: async (frames) => {
    // 1. Authenticate: get the 'user' from the 'session'.
    frames = await frames.query(Sessioning._getUser, { session }, { user });
    // 2. Query: get all files where the 'owner' is the authenticated 'user'.
    frames = await frames.query(FileUploading._getFilesByOwner, { owner: user }, { file, filename });
    // 3. Collect: group all results into a single array for the response.
    return frames.collectAs([file, filename], results);
  },
  then: actions([Requesting.respond, { request, results }]),
});

//-- Download a File --//
export const DownloadFileRequest: Sync = ({ request, session, file, user, owner, isShared, downloadURL }) => ({
  when: actions([
    Requesting.request,
    { path: "/download", session, file },
    { request },
  ]),
  where: async (frames) => {
    // 1. Authenticate the requester.
    frames = await frames.query(Sessioning._getUser, { session }, { user });
    // 2. Get the file's owner.
    frames = await frames.query(FileUploading._getOwner, { file }, { owner });
    // 3. Check if the file is explicitly shared with the requester.
    frames = await frames.query(Sharing._isSharedWith, { file, user }, { access: isShared });
    // 4. Authorize: Keep frames where the requester is the owner OR the file is shared.
    frames = frames.filter(($) => $[user] === $[owner] || $[isShared] === true);
    // 5. For authorized frames, get the download URL.
    return await frames.query(FileUploading._getDownloadURL, { file }, { downloadURL });
  },
  then: actions([Requesting.respond, { request, downloadURL }]),
});
```