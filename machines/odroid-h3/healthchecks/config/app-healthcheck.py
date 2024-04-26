#!/usr/bin/env python3

import requests


if __name__ == "__main__":
    response = requests.get('http://localhost:8000')
    assert response.status_code == 200
