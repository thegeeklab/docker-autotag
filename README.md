# docker-autotag

docker-autotag - Create docker tags from a given version string

[![Build Status](https://img.shields.io/drone/build/xoxys/docker-autotag?logo=drone)](https://cloud.drone.io/xoxys/docker-autotag)
[![Docker Hub](https://img.shields.io/badge/dockerhub-latest-blue.svg?logo=docker&logoColor=white)](https://hub.docker.com/r/xoxys/docker-autotag)
[![Quay.io](https://img.shields.io/badge/quay-latest-blue.svg?logo=docker&logoColor=white)](https://quay.io/repository/thegeeklab/docker-autotag)
[![Python Version](https://img.shields.io/pypi/pyversions/docker-autotag.svg)](https://pypi.org/project/docker-autotag/)
[![PyPi Status](https://img.shields.io/pypi/status/docker-autotag.svg)](https://pypi.org/project/docker-autotag/)
[![PyPi Release](https://img.shields.io/pypi/v/docker-autotag.svg)](https://pypi.org/project/docker-autotag/)
[![Source: GitHub](https://img.shields.io/badge/source-github-blue.svg?logo=github&logoColor=white)](https://github.com/xoxys/docker-autotag)
[![License: MIT](https://img.shields.io/github/license/xoxys/docker-autotag)](LICENSE)

Simple tool to create a list of docker tags from a given version string.

## Environment variables

```Shell
# if not set a comma-separated list will be printed to stdout
DOCKER_AUTOTAG_OUTPUT_FILE=
# adds a given suffix to every determined tag
DOCKER_AUTOTAG_SUFFIX=
# version string to use; returns 'latest' if nothing is specified
DOCKER_AUTOTAG_VERSION=
# comma-seprated list of static tags to add to the result set
DOCKER_AUTOTAG_EXTRA_TAGS=
# 'latest' tag would only be used if determined tag list is empty; adds always 'latest' to the result
DOCKER_AUTOTAG_FORCE_LATEST=False
# if the given version string contains a prerelease, no other tags will be returned
DOCKER_AUTOTAG_IGNORE_PRERELEASE=False
```

## Examples

```Shell
DOCKER_AUTOTAG_VERSION=1.0.1 docker-autotag
# 1.0.1,1.0,1

DOCKER_AUTOTAG_VERSION=0.1.0 docker-autotag
# 0.1.0, 0.1

## 'v' prefixes e.g. from git tags will be removed
DOCKER_AUTOTAG_VERSION=v1.0.1 docker-autotag
# 1.0.1,1.0,1

## unsufficient semver version strings will be tried to convert automatically
## if conversion doesn't work return 'latest'
DOCKER_AUTOTAG_VERSION=1.0 docker-autotag
# 1.0.0,1.0,1

DOCKER_AUTOTAG_VERSION=1.0.0-beta docker-autotag
# 1.0.0-beta

## ignore prerelease to always get a full list of tags
DOCKER_AUTOTAG_IGNORE_PRERELEASE=True DOCKER_AUTOTAG_VERSION=1.0.0-beta docker-autotag
# 1.0.0-beta,1.0.0,1.0,1

DOCKER_AUTOTAG_SUFFIX=amd64 DOCKER_AUTOTAG_VERSION=1.0.0 docker-autotag
# 1.0.0,1.0,1,1.0.0-amd64,1.0-amd64,1-amd64

DOCKER_AUTOTAG_EXTRA_TAGS=extra1,extra2 DOCKER_AUTOTAG_VERSION=1.0.0 docker-autotag
# 1.0.0,1.0,1,extra1,extra2
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Maintainers and Contributors

[Robert Kaussow](https://github.com/xoxys)
