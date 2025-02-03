# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""
This is a simple local public key server implementation for demo purpose only.
It's expected to run inside a Docker container with a public key in hex format
at /public_key, which will be served as key ID 0x40.
"""

import base64
from quart import Quart, jsonify

app = Quart(__name__)

public_key = ""
with open("/public_key") as f:
    public_key = f.read().strip()
    result = bytes.fromhex(public_key)
    public_key = base64.b64encode(result).decode("ascii")


@app.route("/")
async def hello():
    content = {"keys": [{"id": "40", "key": public_key}]}
    response = jsonify(content)
    response.headers["age"] = 267099
    response.headers["cache-control"] = "public,max-age=589778"
    return response


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=9999, server="hypercorn")
