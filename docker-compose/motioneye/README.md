# MotionEye

![diagram](../../docs/diagrams/out/apps/motioneye.png)

## Docs

MotionEye:

- GitHub: <https://github.com/motioneye-project/motioneye>
    - WiKi: <https://github.com/motioneye-project/motioneye/wiki>
    - Install guide: <https://github.com/motioneye-project/motioneye/wiki/Install-In-Docker#build-instructions>
- DockerHub: N/A (only on _ghcr.io_)
- HomeAssistant plugin: <https://www.home-assistant.io/integrations/motioneye>

Motion:

- Homepage: <https://motion-project.github.io>
- GitHub: <https://github.com/Motion-Project/motion>

Notes:

- Streaming only works in `stream`, not in `admin`.

## Before initial installation

- Follow general [guide](../../docs/Checklist%20for%20new%20docker-apps.md)

## After initial installation

- Setup `admin` and `stream` user passwords
    - By default there are no passwords
- Setup camera
    - Add camera according to ![](./Add%20camera.png)
    - Setup blacked out zone
