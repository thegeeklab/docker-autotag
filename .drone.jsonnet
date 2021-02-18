local PythonVersion(pyversion='3.6') = {
  name: 'python' + std.strReplace(pyversion, '.', '') + '-pytest',
  image: 'python:' + pyversion,
  environment: {
    PY_COLORS: 1,
  },
  commands: [
    'pip install poetry poetry-dynamic-versioning -qq',
    'poetry config experimental.new-installer false',
    'poetry install',
    'poetry version',
    'poetry run docker-autotag --help',
  ],
  depends_on: [
    'fetch',
  ],
};

local PipelineLint = {
  kind: 'pipeline',
  name: 'lint',
  platform: {
    os: 'linux',
    arch: 'amd64',
  },
  steps: [
    {
      name: 'yapf',
      image: 'python:3.9',
      environment: {
        PY_COLORS: 1,
      },
      commands: [
        'git fetch -tq',
        'pip install poetry poetry-dynamic-versioning -qq',
        'poetry install',
        'poetry run yapf -dr ./dockerautotag',
      ],
    },
    {
      name: 'flake8',
      image: 'python:3.9',
      environment: {
        PY_COLORS: 1,
      },
      commands: [
        'git fetch -tq',
        'pip install poetry poetry-dynamic-versioning -qq',
        'poetry install',
        'poetry run flake8 ./dockerautotag',
      ],
    },
  ],
  trigger: {
    ref: ['refs/heads/main', 'refs/tags/**', 'refs/pull/**'],
  },
};

local PipelineTest = {
  kind: 'pipeline',
  name: 'test',
  platform: {
    os: 'linux',
    arch: 'amd64',
  },
  steps: [
    {
      name: 'fetch',
      image: 'python:3.9',
      commands: [
        'git fetch -tq',
      ],
    },
    PythonVersion(pyversion='3.6'),
    PythonVersion(pyversion='3.7'),
    PythonVersion(pyversion='3.8'),
    PythonVersion(pyversion='3.9'),
  ],
  depends_on: [
    'lint',
  ],
  trigger: {
    ref: ['refs/heads/main', 'refs/tags/**', 'refs/pull/**'],
  },
};

local PipelineSecurity = {
  kind: 'pipeline',
  name: 'security',
  platform: {
    os: 'linux',
    arch: 'amd64',
  },
  steps: [
    {
      name: 'bandit',
      image: 'python:3.9',
      environment: {
        PY_COLORS: 1,
      },
      commands: [
        'git fetch -tq',
        'pip install poetry poetry-dynamic-versioning -qq',
        'poetry install',
        'poetry run bandit -r ./dockerautotag -x ./dockerautotag/test',
      ],
    },
  ],
  depends_on: [
    'test',
  ],
  trigger: {
    ref: ['refs/heads/main', 'refs/tags/**', 'refs/pull/**'],
  },
};

local PipelineBuildPackage = {
  kind: 'pipeline',
  name: 'build-package',
  platform: {
    os: 'linux',
    arch: 'amd64',
  },
  steps: [
    {
      name: 'build',
      image: 'python:3.9',
      commands: [
        'git fetch -tq',
        'pip install poetry poetry-dynamic-versioning -qq',
        'poetry build',
      ],
    },
    {
      name: 'checksum',
      image: 'alpine',
      commands: [
        'cd dist/ && sha256sum * > ../sha256sum.txt',
      ],
    },
    {
      name: 'publish-github',
      image: 'plugins/github-release',
      settings: {
        overwrite: true,
        api_key: { from_secret: 'github_token' },
        files: ['dist/*', 'sha256sum.txt'],
        title: '${DRONE_TAG}',
        note: 'CHANGELOG.md',
      },
      when: {
        ref: ['refs/tags/**'],
      },
    },
    {
      name: 'publish-pypi',
      image: 'python:3.9',
      commands: [
        'git fetch -tq',
        'pip install poetry poetry-dynamic-versioning -qq',
        'poetry publish -n',
      ],
      environment: {
        POETRY_HTTP_BASIC_PYPI_USERNAME: { from_secret: 'pypi_username' },
        POETRY_HTTP_BASIC_PYPI_PASSWORD: { from_secret: 'pypi_password' },
      },
      when: {
        ref: ['refs/tags/**'],
      },
    },
  ],
  depends_on: [
    'security',
  ],
  trigger: {
    ref: ['refs/heads/main', 'refs/tags/**', 'refs/pull/**'],
  },
};

local PipelineBuildContainer(arch='amd64') = {
  kind: 'pipeline',
  name: 'build-container-' + arch,
  platform: {
    os: 'linux',
    arch: arch,
  },
  steps: [
    {
      name: 'build',
      image: 'python:3.9-alpine',
      commands: [
        'apk --update --quiet add build-base libressl-dev libffi-dev musl-dev  python3-dev py3-cryptography git',
        'git fetch -tq',
        'pip install poetry poetry-dynamic-versioning -qq',
        'poetry config virtualenvs.create false',
        'poetry build',
      ],
    },
    {
      name: 'dryrun',
      image: 'thegeeklab/drone-docker:19',
      settings: {
        dry_run: true,
        dockerfile: 'docker/Dockerfile.' + arch,
        repo: 'thegeeklab/${DRONE_REPO_NAME}',
        username: { from_secret: 'docker_username' },
        password: { from_secret: 'docker_password' },
      },
      depends_on: ['build'],
      when: {
        ref: ['refs/pull/**'],
      },
    },
    {
      name: 'publish-dockerhub',
      image: 'thegeeklab/drone-docker:19',
      settings: {
        auto_tag: true,
        auto_tag_suffix: arch,
        dockerfile: 'docker/Dockerfile.' + arch,
        repo: 'thegeeklab/${DRONE_REPO_NAME}',
        username: { from_secret: 'docker_username' },
        password: { from_secret: 'docker_password' },
      },
      when: {
        ref: ['refs/heads/main', 'refs/tags/**'],
      },
      depends_on: ['dryrun'],
    },
    {
      name: 'publish-quay',
      image: 'thegeeklab/drone-docker:19',
      settings: {
        auto_tag: true,
        auto_tag_suffix: arch,
        dockerfile: 'docker/Dockerfile.' + arch,
        registry: 'quay.io',
        repo: 'quay.io/thegeeklab/${DRONE_REPO_NAME}',
        username: { from_secret: 'quay_username' },
        password: { from_secret: 'quay_password' },
      },
      when: {
        ref: ['refs/heads/main', 'refs/tags/**'],
      },
      depends_on: ['dryrun'],
    },
  ],
  depends_on: [
    'security',
  ],
  trigger: {
    ref: ['refs/heads/main', 'refs/tags/**', 'refs/pull/**'],
  },
};

local PipelineNotifications = {
  kind: 'pipeline',
  name: 'notifications',
  platform: {
    os: 'linux',
    arch: 'amd64',
  },
  steps: [
    {
      image: 'plugins/manifest',
      name: 'manifest-dockerhub',
      settings: {
        ignore_missing: true,
        auto_tag: true,
        username: { from_secret: 'docker_username' },
        password: { from_secret: 'docker_password' },
        spec: 'docker/manifest.tmpl',
      },
      when: {
        status: ['success'],
      },
    },
    {
      image: 'plugins/manifest',
      name: 'manifest-quay',
      settings: {
        ignore_missing: true,
        auto_tag: true,
        username: { from_secret: 'quay_username' },
        password: { from_secret: 'quay_password' },
        spec: 'docker/manifest-quay.tmpl',
      },
      when: {
        status: ['success'],
      },
    },
    {
      name: 'pushrm-dockerhub',
      pull: 'always',
      image: 'chko/docker-pushrm:1',
      environment: {
        DOCKER_PASS: {
          from_secret: 'docker_password',
        },
        DOCKER_USER: {
          from_secret: 'docker_username',
        },
        PUSHRM_FILE: 'README.md',
        PUSHRM_SHORT: 'Create docker tags from a given version string',
        PUSHRM_TARGET: 'thegeeklab/${DRONE_REPO_NAME}',
      },
      when: {
        status: ['success'],
      },
    },
    {
      name: 'pushrm-quay',
      pull: 'always',
      image: 'chko/docker-pushrm:1',
      environment: {
        APIKEY__QUAY_IO: {
          from_secret: 'quay_token',
        },
        PUSHRM_FILE: 'README.md',
        PUSHRM_TARGET: 'quay.io/thegeeklab/${DRONE_REPO_NAME}',
      },
      when: {
        status: ['success'],
      },
    },
    {
      name: 'matrix',
      image: 'plugins/matrix',
      settings: {
        homeserver: { from_secret: 'matrix_homeserver' },
        roomid: { from_secret: 'matrix_roomid' },
        template: 'Status: **{{ build.status }}**<br/> Build: [{{ repo.Owner }}/{{ repo.Name }}]({{ build.link }}) ({{ build.branch }}) by {{ build.author }}<br/> Message: {{ build.message }}',
        username: { from_secret: 'matrix_username' },
        password: { from_secret: 'matrix_password' },
      },
      when: {
        status: ['success', 'failure'],
      },
    },
  ],
  depends_on: [
    'build-package',
    'build-container-amd64',
    'build-container-arm64',
    'build-container-arm',
  ],
  trigger: {
    ref: ['refs/heads/main', 'refs/tags/**'],
    status: ['success', 'failure'],
  },
};

[
  PipelineLint,
  PipelineTest,
  PipelineSecurity,
  PipelineBuildPackage,
  PipelineBuildContainer(arch='amd64'),
  PipelineBuildContainer(arch='arm64'),
  PipelineBuildContainer(arch='arm'),
  PipelineNotifications,
]
