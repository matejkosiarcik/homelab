#!/usr/bin/env python3

import os
import re

# pylint: disable=E0401
import requests  # type: ignore

if __name__ == "__main__":
    response = requests.get(
        "http://localhost:8000/api/v3/status/",
        timeout=1000,
        headers={"Host": re.sub(r"^https?://", "", os.environ["SITE_ROOT"])},
    )
    assert response.status_code == 200
    assert response.text == "OK"
