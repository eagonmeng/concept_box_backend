---
timestamp: 'Wed Oct 29 2025 11:33:00 GMT-0400 (Eastern Daylight Time)'
parent: '[[../20251029_113300.03aaff9b.md]]'
content_id: 407a02a886ec713d58a7ff4d7beb026e5e89be91daa26c40542d6b7a996e7e34
---

# concept: Sharing \[User, File]

* **purpose**: To allow file owners to grant access to other users.
* **principle**: A file's owner can share it with another user, who can then access it. If the owner revokes access, the other user can no longer access it.
* **state**:
  * a set of `File`s with
    * a `sharedWith` set of User
* **actions**:
  * `shareWithUser (file: File, user: User): ()`
    * **requires**: `user` is not already in the `sharedWith` set for `file`.
    * **effects**: adds the `user` to the `sharedWith` set for `file`.
  * `revokeAccess (file: File, user: User): ()`
    * **requires**: `user` is in the `sharedWith` set for `file`.
    * **effects**: removes the `user` from the `sharedWith` set for `file`.
* **queries**:
  * `_isSharedWith (file: File, user: User): (access: Boolean)` (Revised pure query)
    * **requires**: `file` and `user` exist.
    * **effects**: returns `true` if the `user` is in the `sharedWith` set for the `file`, false otherwise.
