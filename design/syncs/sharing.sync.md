# Sharing Synchronizations

**concepts:** `Requesting`, `Sessioning`, `FileUploading`, `Sharing`

These synchronizations implement the ability to share files with other users.

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

# file: src/syncs/sharing.sync.ts

This file manages the logic for sharing a file with another user and revoking that access.

```typescript
import { actions, Sync } from "@engine";
import {
  FileUploading,
  Requesting,
  Sessioning,
  Sharing,
  UserAuthentication,
} from "@concepts";

//-- Share a File --//
export const ShareFileRequest: Sync = (
  { request, session, file, shareWithUsername, requester, owner, targetUser },
) => ({
  when: actions([
    Requesting.request,
    { path: "/share", session, file, shareWithUsername },
    { request },
  ]),
  where: async (frames) => {
    // 1. Authenticate: get the requesting user, aliased as 'requester'.
    frames = await frames.query(Sessioning._getUser, { session }, { user: requester });
    // 2. Authorize: get the file owner and ensure it's the requester.
    frames = await frames.query(FileUploading._getOwner, { file }, { owner });
    frames = frames.filter(($) => $[requester] === $[owner]);
    // 3. Find target: get the user to share with, aliased as 'targetUser'.
    return await frames.query(
      UserAuthentication._getUserByUsername,
      { username: shareWithUsername },
      { user: targetUser },
    );
  },
  then: actions([
    // The 'shareWithUser' action expects a 'user'. We provide the 'targetUser' variable.
    Sharing.shareWithUser,
    { file, user: targetUser },
  ]),
});

export const ShareFileResponse: Sync = ({ request }) => ({
  when: actions(
    [Requesting.request, { path: "/share" }, { request }],
    [Sharing.shareWithUser, {}, {}],
  ),
  then: actions([Requesting.respond, { request, status: "shared" }]),
});

//-- Revoke Access to a File --//
export const RevokeAccessRequest: Sync = (
  { request, session, file, revokeForUsername, requester, owner, targetUser },
) => ({
  when: actions([
    Requesting.request,
    { path: "/revoke", session, file, revokeForUsername },
    { request },
  ]),
  where: async (frames) => {
    // Logic is identical to sharing, just for a different final action.
    frames = await frames.query(Sessioning._getUser, { session }, { user: requester });
    frames = await frames.query(FileUploading._getOwner, { file }, { owner });
    frames = frames.filter(($) => $[requester] === $[owner]);
    return await frames.query(
      UserAuthentication._getUserByUsername,
      { username: revokeForUsername },
      { user: targetUser },
    );
  },
  then: actions([
    Sharing.revokeAccess,
    { file, user: targetUser },
  ]),
});

export const RevokeAccessResponse: Sync = ({ request }) => ({
  when: actions(
    [Requesting.request, { path: "/revoke" }, { request }],
    [Sharing.revokeAccess, {}, {}],
  ),
  then: actions([Requesting.respond, { request, status: "revoked" }]),
});
```