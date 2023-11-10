"""Global utility methods and classes."""

import os


def normalize_path(path):
    if path:
        return os.path.abspath(os.path.expanduser(os.path.expandvars(path)))

    return None


def strtobool(value):
    """Convert a string representation of truth to true or false."""

    _map = {
        "y": True,
        "yes": True,
        "t": True,
        "true": True,
        "on": True,
        "1": True,
        "n": False,
        "no": False,
        "f": False,
        "false": False,
        "off": False,
        "0": False,
    }

    try:
        return _map[str(value).lower()]
    except KeyError as err:
        raise ValueError(f'"{value}" is not a valid bool value') from err


def to_bool(string):
    return bool(strtobool(str(string)))


def trim_prefix(text, prefix):
    if text.startswith(prefix):
        return text[len(prefix) :]
    return text


def to_prerelease(tup):
    return ".".join(tup)


class Singleton(type):
    """Meta singleton class."""

    _instances = {}

    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super().__call__(*args, **kwargs)
        return cls._instances[cls]
