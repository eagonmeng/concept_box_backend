---
timestamp: 'Tue Oct 28 2025 15:23:26 GMT-0400 (Eastern Daylight Time)'
parent: '[[../20251028_152326.90d0fa6a.md]]'
content_id: eefde8c686a6c99eb89d7f9bb53a6f6fc2512906c47eee9c68b564b9b9e0e44d
---

# concept: UserAuthentication \[User]

* **purpose**: To securely verify a user's identity based on credentials.
* **principle**: If you register with a unique username and a password, and later provide the same credentials to log in, you will be successfully identified as that user.
* **state**:
  * a set of `User`s with
    * a `username` String (unique)
    * a `passwordHash` String
* **actions**:
  * `register (username: String, password: String): (user: User)`
    * **requires**: no User exists with the given `username`.
    * **effects**: creates a new User `u`; sets their `username` and a hash of their `password`; returns `u` as `user`.
  * `register (username: String, password: String): (error: String)`
    * **requires**: a User already exists with the given `username`.
    * **effects**: returns an error message.
  * `login (username: String, password: String): (user: User)`
    * **requires**: a User exists with the given `username` and the `password` matches their `passwordHash`.
    * **effects**: returns the matching User `u` as `user`.
  * `login (username: String, password: String): (error: String)`
    * **requires**: no User exists with the given `username` or the `password` does not match.
    * **effects**: returns an error message.
* **queries**:
  * `_getUserByUsername (username: String): (user: User)`
    * **requires**: a User with the given `username` exists.
    * **effects**: returns the corresponding User.
