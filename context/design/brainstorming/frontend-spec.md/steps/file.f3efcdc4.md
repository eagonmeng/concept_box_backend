---
timestamp: 'Wed Oct 29 2025 07:06:13 GMT-0400 (Eastern Daylight Time)'
parent: '[[../20251029_070613.77de349e.md]]'
content_id: f3efcdc48a8ce1f816bbdd39dcfd575fba12342cfbc63ba0a94324f4428353e2
---

# file: src/syncs/files.sync.ts

```typescript
import { actions, Sync } from "@engine";
import { Requesting, Sessioning, FileUploading, Sharing } from "@concepts";

//-- Phase 1: Request Upload URL --//
export const RequestUploadURL: Sync = ({ request, session, filename, owner }) => ({
  when: actions([Requesting.request, { path: "/FileUploading/requestUploadURL", session, filename }, { request }]),
  where: (frames) => frames.query(Sessioning._getUser, { session }, { owner }),
  then: actions([FileUploading.requestUploadURL, { owner, filename }]),
});

export const RequestUploadURLResponse: Sync = ({ request, file, uploadURL }) => ({
  when: actions(
    [Requesting.request, { path: "/FileUploading/requestUploadURL" }, { request }],
    [FileUploading.requestUploadURL, {}, { file, uploadURL }],
  ),
  then: actions([Requesting.respond, { request, file, uploadURL }]),
});

//-- Phase 2: Confirm Upload --//
export const ConfirmUploadRequest: Sync = ({ request, session, file, user, owner }) => ({
  when: actions([Requesting.request, { path: "/FileUploading/confirmUpload", session, file }, { request }]),
  where: async (frames) => {
    frames = await frames.query(Sessioning._getUser, { session }, { user });
    frames = await frames.query(FileUploading._getOwner, { file }, { owner });
    return frames.filter(($) => $[user] === $[owner]);
  },
  then: actions([FileUploading.confirmUpload, { file }]),
});

export const ConfirmUploadResponse: Sync = ({ request, error }) => ({
  when: actions(
    [Requesting.request, { path: "/FileUploading/confirmUpload" }, { request }],
    [FileUploading.confirmUpload, {}, { error }],
  ),
  then: actions([Requesting.respond, { request, status: "confirmed", error }]),
});

//-- List User's Files --//
export const ListMyFilesRequest: Sync = ({ request, session, owner, file, filename, results }) => ({
  when: actions([Requesting.request, { path: "/my-files", session }, { request }]),
  where: async (frames) => {
    frames = await frames.query(Sessioning._getUser, { session }, { owner });
    frames = await frames.query(FileUploading._getFilesByOwner, { owner }, { file, filename });
    return frames.collectAs([file, filename], results);
  },
  then: actions([Requesting.respond, { request, results }]),
});

//-- Download a File --//
export const DownloadFileRequest: Sync = ({ request, session, file, user, owner, isShared, downloadURL }) => ({
  when: actions([Requesting.request, { path: "/download", session, file }, { request }]),
  where: async (frames) => {
    frames = await frames.query(Sessioning._getUser, { session }, { user });
    frames = await frames.query(FileUploading._getOwner, { file }, { owner });
    frames = await frames.query(Sharing._isSharedWith, { file, user }, { isShared });
    // Authorization Logic: Keep frames where the user is the owner OR the file is shared.
    frames = frames.filter(($) => $[user] === $[owner] || $[isShared] === true);
    // If any authorized frames remain, get the download URL for them.
    return await frames.query(FileUploading._getDownloadURL, { file }, { downloadURL });
  },
  then: actions([Requesting.respond, { request, downloadURL }]),
});

```
