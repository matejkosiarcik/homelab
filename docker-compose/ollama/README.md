# Ollama

![diagram](../../docs/diagrams/out/apps/ollama.png)

## Docs

- DockerHub: <https://hub.docker.com/r/ollama/ollama>
- Docs:
    - Install instructions: <https://ollama.com/blog/ollama-is-now-available-as-an-official-docker-image>
    - Models: <https://ollama.com/search>

## Before initial installation

- Follow general [guide](../../docs/Checklist%20for%20new%20docker-apps.md)

## After initial installation

- \[Dev\]
  - Go to `ollama` app directory
  - Download basic models:
    ```sh
    docker run --rm --interactive --tty --entrypoint bash \
      --volume "$PWD/app-data/ollama:/root/.ollama:rw" \
      ollama/ollama -c 'ollama serve& && sleep 10 && ollama pull deepseek-r1:1.5b'
    ```
- \[Prod\] Download basic models
  ```sh
  docker run --rm --interactive --tty --entrypoint bash \
    --volume "$HOME/git/homelab/servers/.current/docker-apps/ollama/app-data/ollama:/root/.ollama:rw" \
    ollama/ollama -c 'ollama serve& && sleep 10 && ollama pull deepseek-r1:1.5b'
  ```
