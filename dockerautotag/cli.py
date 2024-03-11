"""Main program."""

import argparse
import copy
import os
import sys
from collections import defaultdict

import semantic_version

from dockerautotag import __version__
from dockerautotag.logging import SingleLog
from dockerautotag.utils import normalize_path, to_bool, to_prerelease, trim_prefix


class Autotag:
    """Handles tag operations."""

    def __init__(self):
        self.log = SingleLog()
        self.logger = self.log.logger
        self.args = self._cli_args()
        self.config = self._config()
        self.run()

    def _cli_args(self):
        parser = argparse.ArgumentParser(
            description=("Creates a list of docker tags from a given version string.")
        )
        parser.add_argument("--version", action="version", version=f"%(prog)s {__version__}")

        return parser.parse_args()

    def _config(self):
        config = defaultdict(dict)

        output_raw = os.environ.get("DOCKER_AUTOTAG_OUTPUT_FILE", None)
        config["file"] = normalize_path(output_raw)

        config["suffix"] = os.environ.get("DOCKER_AUTOTAG_SUFFIX", None)
        config["suffix_strict"] = to_bool(os.environ.get("DOCKER_AUTOTAG_SUFFIX_STRICT", False))
        config["version"] = os.environ.get("DOCKER_AUTOTAG_VERSION", None)
        config["extra"] = os.environ.get("DOCKER_AUTOTAG_EXTRA_TAGS", None)
        config["force_latest"] = to_bool(os.environ.get("DOCKER_AUTOTAG_FORCE_LATEST", False))
        config["ignore_pre"] = to_bool(os.environ.get("DOCKER_AUTOTAG_IGNORE_PRERELEASE", False))

        return config

    @staticmethod
    def _tag_extra(tags, extra):
        e = []
        if extra:
            e = [x.strip() for x in extra.split(",")]

        return tags + e

    @staticmethod
    def _tag_suffix(tags, suffix, suffix_strict):
        if not suffix:
            return tags

        res = []
        if not suffix_strict:
            res = copy.deepcopy(tags)

        for t in tags:
            if t == "latest":
                res.append(suffix)
            else:
                res.append(f"{t}-{suffix}")

        return res

    @staticmethod
    def _default_tags(ref, ignore_pre, force_latest):
        default = ["latest"]
        tags = []

        if force_latest:
            tags.append("latest")

        if not ref:
            return default

        ref = trim_prefix(ref, "refs/tags/")
        ref = trim_prefix(ref, "v")

        try:
            version = semantic_version.Version(ref)
        except ValueError:
            try:
                version = semantic_version.Version.coerce(ref)
            except Exception:  # noqa: BLE001
                return default
        except Exception:  # noqa: BLE001
            return default

        if version.prerelease:
            tags.append(
                f"{version.major}.{version.minor}.{version.patch}-{to_prerelease(version.prerelease)}"
            )
            if not ignore_pre:
                return tags

        tags.append(f"{version.major}.{version.minor}")
        tags.append(f"{version.major}.{version.minor}.{version.patch}")

        if version.major > 0:
            tags.append(f"{version.major}")

        return tags

    def run(self):
        config = self.config

        v = self._default_tags(config["version"], config["ignore_pre"], config["force_latest"])
        v = self._tag_suffix(v, config["suffix"], config["suffix_strict"])
        v = self._tag_extra(v, config["extra"])

        try:
            if config["file"]:
                with open(config["file"], "w") as f:
                    f.write(",".join(v))
            else:
                sys.stdout.write(",".join(v))
                sys.stdout.write("\n")
        except OSError as e:
            self.logger.error(f"Unable to write file: {e!s}")


def main():
    Autotag()
