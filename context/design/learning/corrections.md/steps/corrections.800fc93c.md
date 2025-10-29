---
timestamp: 'Wed Oct 29 2025 08:34:21 GMT-0400 (Eastern Daylight Time)'
parent: '[[../20251029_083421.0362e93b.md]]'
content_id: 800fc93c73f66f6bfd6854b3891aae74ee4f00ca89a988141807ce6d0ca35126
---

# corrections:

Please correct the synchronizations - in particular, examples such as:

```typescript
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
```

where the output of `Sessioning._getUser` refers to an `owner` parameter that doesn't exist, as this query doesn't know about owners, and instead outputs `user`.
