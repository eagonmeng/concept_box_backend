---
timestamp: 'Wed Oct 29 2025 07:06:13 GMT-0400 (Eastern Daylight Time)'
parent: '[[../20251029_070613.77de349e.md]]'
content_id: 937338b77169775dd5295897f2aeb2608cc06c0fa71aa216b6c8fce8ca115358
---

# file: src/syncs/auth.sync.ts

```typescript
import { actions, Sync } from "@engine";
import { Requesting, UserAuthentication, Sessioning } from "@concepts";

//-- User Registration --//
export const RegisterRequest: Sync = ({ request, username, password }) => ({
  when: actions([Requesting.request, { path: "/UserAuthentication/register", username, password }, { request }]),
  then: actions([UserAuthentication.register, { username, password }]),
});

export const RegisterResponse: Sync = ({ request, user, error }) => ({
  when: actions(
    [Requesting.request, { path: "/UserAuthentication/register" }, { request }],
    [UserAuthentication.register, {}, { user, error }],
  ),
  then: actions([Requesting.respond, { request, user, error }]),
});

//-- User Login & Session Creation --//
export const LoginRequest: Sync = ({ request, username, password }) => ({
  when: actions([Requesting.request, { path: "/login", username, password }, { request }]),
  then: actions([UserAuthentication.login, { username, password }]),
});

export const LoginSuccessCreatesSession: Sync = ({ user }) => ({
  when: actions([UserAuthentication.login, {}, { user }]),
  then: actions([Sessioning.create, { user }]),
});

export const LoginResponse: Sync = ({ request, user, session, error }) => ({
  when: actions(
    [Requesting.request, { path: "/login" }, { request }],
    [UserAuthentication.login, {}, { user, error }],
    [Sessioning.create, { user }, { session }],
  ),
  then: actions([Requesting.respond, { request, session, error }]),
});

//-- User Logout --//
export const LogoutRequest: Sync = ({ request, session, user }) => ({
  when: actions([Requesting.request, { path: "/logout", session }, { request }]),
  where: (frames) => frames.query(Sessioning._getUser, { session }, { user }),
  then: actions([Sessioning.delete, { session }]),
});

export const LogoutResponse: Sync = ({ request }) => ({
  when: actions(
    [Requesting.request, { path: "/logout" }, { request }],
    [Sessioning.delete, {}, {}],
  ),
  then: actions([Requesting.respond, { request, status: "logged_out" }]),
});

```
