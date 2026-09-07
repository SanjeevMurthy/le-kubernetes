# Q27. Fix two issues in the Dockerfile and two in the manifest

Two files are waiting in `/opt/course/27/` (or `$COURSE_DIR/27/` on this lab):

- `Dockerfile`, which builds the image for the `web` application
- `deploy.yaml`, the Deployment that runs it

Each file has exactly **two** security problems.

1. In `Dockerfile`, fix the two problems. The image must not be built from an end-of-life base image, and the container must not end up running as root.

2. In `deploy.yaml`, fix the two problems. The container must not be privileged, and it must not run as UID 0.

Change **only** what is needed. Do not rewrite the files, do not reorder them, do not add commentary, and do not change anything that is already correct. Keep the base image on the same distribution and keep the application working.

Nothing is applied to a cluster. Both files are graded as text.
