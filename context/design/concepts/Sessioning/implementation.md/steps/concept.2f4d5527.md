---
timestamp: 'Tue Oct 28 2025 15:24:29 GMT-0400 (Eastern Daylight Time)'
parent: '[[../20251028_152429.14a0394e.md]]'
content_id: 2f4d55274ba8c486664576886cb3132f5d803a6d523beb4283632424af7bb31c
---

# concept: Sessioning \[User, Session]

* **purpose**: To maintain a user's logged-in state across multiple requests without re-sending credentials.
* **principle**: After a user is authenticated, a session is created for them. Subsequent requests using that session's ID are treated as being performed by that user, until the session is deleted (logout).
* **state**:
  * a set of `Session`s with
    * a `user` User
* **actions**:
  * `create (user: User): (session: Session)`
    * **requires**: true.
    * **effects**: creates a new Session `s`; associates it with the given `user`; returns `s` as `session`.
  * `delete (session: Session): ()`
    * **requires**: the given `session` exists.
    * **effects**: removes the session `s`.
* **queries**:
  * `_getUser (session: Session): (user: User)`
    * **requires**: the given `session` exists.
    * **effects**: returns the user associated with the session.
