---
timestamp: 'Wed Oct 29 2025 10:45:49 GMT-0400 (Eastern Daylight Time)'
parent: '[[../20251029_104549.94960795.md]]'
content_id: 70087cf3ff89ae176fb4a546da2f6310add0fcce47204e1689dc06c523def3ca
---

# response:

Of course! Your diagnosis is spot on. A `403 Forbidden` error when using a Google Cloud Storage presigned URL is very often caused by a mismatch between the headers used to *generate* the URL and the headers sent by the client in the actual `PUT` request.

By hardcoding `application/octet-stream` on the backend, you forced the frontend to *also* use that exact `Content-Type` header, regardless of the file's actual type. When the browser or client library automatically sets a more specific `Content-Type` (like `image/png`), GCS sees the mismatch and rejects the request.

The solution is to infer the correct MIME type from the filename on the backend when generating the URL. This ensures the URL is signed with the same `Content-Type` that the client will naturally send.

Here is the updated implementation.

***
