#!/usr/bin/env python3

# pylint: disable=E0401
import requests  # type: ignore

if __name__ == "__main__":
    response = requests.get("http://localhost:8000", timeout=1000)
    assert response.status_code == 200
