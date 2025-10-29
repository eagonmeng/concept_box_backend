---
timestamp: 'Wed Oct 29 2025 08:34:21 GMT-0400 (Eastern Daylight Time)'
parent: '[[../20251029_083421.0362e93b.md]]'
content_id: 3cbe147fcc1a6dfe2c9e9ea58e9fd7d2676146dbcd614bbb46be73436a18bee2
---

# update:

We will be using Google Cloud Storage for uploading files, and slightly modify the concept specification. Namely, we want the actual storage to be handled by the encapsulated GCS API inside the concept, and work primarily off presigned URLs. This will mean we'll need to split the uploading actions into some sort of action for generating and returning a presigned URL for uploading by the client, and then another action for the client to call to confirm after the file was uploaded, so that the concept knows the file is available. Update the `FileStorage` concept to the `FileUploading` concept with these changes in mind.
