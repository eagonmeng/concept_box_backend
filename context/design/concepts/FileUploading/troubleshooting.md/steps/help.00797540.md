---
timestamp: 'Wed Oct 29 2025 10:11:24 GMT-0400 (Eastern Daylight Time)'
parent: '[[../20251029_101124.e6db7220.md]]'
content_id: 0079754032e2f32fff70fa97173d5631e665b16312285e50ac41a9c6b56029ab
---

# help:

I'm getting the error:

```
[Error] Origin http://localhost:5173 is not allowed by Access-Control-Allow-Origin. Status code: 200
[Error] Fetch API cannot load https://storage.googleapis.com/6104_concept-box_file-uploading/019a304a-1ca2-79e1-b48b-fb478de58aec/Screenshot%202025-10-06%20at%209.32.38%E2%80%AFAM.png?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Credential=file-uploading-service%40context-474621.iam.gserviceaccount.com%2F20251029%2Fauto%2Fstorage%2Fgoog4_request&X-Goog-Date=20251029T140554Z&X-Goog-Expires=900&X-Goog-SignedHeaders=content-type%3Bhost&X-Goog-Signature=586073126cca9aff602f0dcb976401d7a42d46cee7480170465a20b64fa8ea136d984dd2c3b68d4be67c319076f009b3d52a0fe2559a9b07a9c20954e192649aa6354bf42fb83f8886cc401b822250d46332bacc3861a1a4545640d685b8ad21441f7faddddd276832aae8c93e6e53c849b08566d2972212f2445c6ded001ac7963a208f846d26b8db7bd041bc9995026e1484e71312bbd94522dda04a6243838bd36b074006c2b8fa757644f6bb577192e3f0d8eb9a9284cd863a894652438289a8e4d28f529c84d22e366a3d6a32dfddfd78362783f80d6e386195f2a126ca760f60976937da5fbf0d7b18a75ca7ed8de92fac7f197e81c027714fb5116fc0 due to access control checks.
```

on the frontend. Do I need to do additional configuration, or does the implementation need to be updated with CORS settings?
