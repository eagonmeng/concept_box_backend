---
timestamp: 'Wed Oct 29 2025 10:11:24 GMT-0400 (Eastern Daylight Time)'
parent: '[[../20251029_101124.e6db7220.md]]'
content_id: f1b8ebe90e0af1db79760a9009a9ef2e19c65b1eb439389b7f64738ef0523f56
---

# implement: FileUploading

Utilize the GCS library:

```
import { Storage } from "npm:@google-cloud/storage";
```

Prefix any environment variables needed with `FILE_UPLOADING_` to make it clear that they pertain to this concept: these can be the bucket name, any credentials needed, etc. Please also describe at the end how to set these up, particularly around credentials.
