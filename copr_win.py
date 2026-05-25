import sys
import os

# Monkey patch to fix Copr CLI Windows path bug (where os.path.join uses \ in URLs)
import copr.v3.requests

def safe_endpoint_url(self, endpoint, params=None):
    params = params or {}
    endpoint = endpoint.strip("/").format(**params)
    base = self.api_base_url.rstrip("/")
    path = endpoint.lstrip("/")
    url = f"{base}/{path}".replace("\\", "/")
    return url

copr.v3.requests.Request.endpoint_url = safe_endpoint_url

import copr_cli.main
if __name__ == "__main__":
    copr_cli.main.main()
