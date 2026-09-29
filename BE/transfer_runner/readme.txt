Runtime: Node 22. npm ci uses the pinned package-lock.
Do not persist MEGA passwords. Export an authenticated session with session.mjs.
GitHub Actions secrets hold the session; session.api.close() closes networking without invalidating it.
Storage.close() logs out MEGA and MUST NOT be called for a reusable session.
