#!/usr/bin/env make -f
# NOTE(CONSHNS): This doesn't work well if you have spaces in your $(PWD).. so don't even think about it.

# This sets the default Python version to 3.12 which is enforced throughout this project in whole.
PYTHON_VERSION ?= 3.12
PYTHON := python$(PYTHON_VERSION)

# NOTE(CONSHNS): This needs to be updated to use something other than $(PWD) that is relative to this Makefile or
# enforces we are at the root of the repository.
VIRTUAL_ENV_PATH ?= $(PWD)/.venv
VIRTUAL_ENV_EXPORTS ?= VIRTUAL_ENV=$(VIRTUAL_ENV_PATH)

# Just make some aliases for the Python commands we are going to use.
VIRTUAL_ENV_PYTHON := $(VIRTUAL_ENV_EXPORTS) $(VIRTUAL_ENV_PATH)/bin/$(PYTHON)
VIRTUAL_ENV_PYTHON_M_BUILD := $(VIRTUAL_ENV_EXPORTS) $(PYTHON) -m build
VIRTUAL_ENV_PYTHON_M_PIP := $(VIRTUAL_ENV_EXPORTS) $(PYTHON) -m pip
VIRTUAL_ENV_PYTHON_M_PIP_TOOLS := $(VIRTUAL_ENV_EXPORTS) $(PYTHON) -m piptools
VIRTUAL_ENV_PYTHON_M_PRE_COMMIT := $(VIRTUAL_ENV_EXPORTS) $(PYTHON) -m pre_commit
VIRTUAL_ENV_PYTHON_M_TOX := $(VIRTUAL_ENV_EXPORTS) $(PYTHON) -m tox
VIRTUAL_ENV_TOML_SORT := $(VIRTUAL_ENV_EXPORTS) toml-sort

# It's just always been easier to put this up top rather than at the bottom.
all: \
	development \
	build \
	image

# Just a `noop` that is mostly used to deal with line continuations in the Makefile when referencing multiple targets.
noop:

# Virtualenv specific targets that help reduce processing when files are up to date.
virtual-env: $(VIRTUAL_ENV_PATH)/bin/activate

$(VIRTUAL_ENV_PATH)/bin/activate:
	test -d $(VIRTUAL_ENV_PATH) || $(PYTHON) -m venv $(VIRTUAL_ENV_PATH) --prompt $(notdir $(PWD))

# Update the development environment by ensuring and updating the virtualenv and then syncing (not just installing) the
# requirements using pip-tools.  Syncing will remove any packages that are no longer in the requirements files to ensure
# a clean environment.
development-upgrade-virtual-env: virtual-env
	$(VIRTUAL_ENV_PYTHON_M_PIP) install --force-reinstall --no-deps \
		-r requirements/bootstrap.txt
	$(VIRTUAL_ENV_PYTHON_M_PIP_TOOLS) sync \
		requirements/deployment.txt \
		requirements/development.txt \
		requirements/production.txt

# Install an editable package of this project into the virtual environment.  This is useful for development and testing
# and allows us to query the package metadata using libraries like `packaging` and `importlib.metadata`.
development-install-editable-package: virtual-env
	$(VIRTUAL_ENV_PYTHON_M_PIP) install --no-deps -e ./semaphore-core
	$(VIRTUAL_ENV_PYTHON_M_PIP) install --no-deps -e ./semaphore-backends-memory
	$(VIRTUAL_ENV_PYTHON_M_PIP) install --no-deps -e ./semaphore-backends-filesystem
	$(VIRTUAL_ENV_PYTHON_M_PIP) install --no-deps -e ./semaphore-backends-redis

# This will install the pre-commit hooks into the `.git/hooks` directory and will cover `pre-commit`, `commit-msg`, and
# `pre-push` events.
development-install-pre-commit: virtual-env
	$(VIRTUAL_ENV_PYTHON_M_PRE_COMMIT) install \
		--hook-type pre-commit \
		--hook-type commit-msg \
		--hook-type pre-push

# This will upgrade the pre-commit hooks to the latest version which may result in a change to the
# `.pre-commit-config.yaml` and subsequently dirty up the repository unless it is committed.  Ideally changes here would
# be committed in low-impact PRs.
development-upgrade-pre-commit: virtual-env
	$(VIRTUAL_ENV_PYTHON_M_PRE_COMMIT) autoupdate

# Running `make development` will handle all of the steps necessary to get the development environment up and running.
development: \
	development-upgrade-virtual-env \
	development-install-editable-package \
	development-install-pre-commit \
	development-upgrade-pre-commit \
	noop

# Similarly patterend after the development environment, the production environment is setup to be as minimal as
# possible by only installing the `bootstrap` and syncronozing the `production` requirements.  This is useful when you
# want to test something works locally with ONLY production dependencies or before building a production asset like a
# Docker image.
production-upgrade-virtual-env: virtual-env
	$(VIRTUAL_ENV_PYTHON_M_PIP) install --force-reinstall --no-deps \
		-r requirements/bootstrap.txt
	$(VIRTUAL_ENV_PYTHON_M_PIP_TOOLS) sync \
		requirements/production.txt

production-install-editable-package: virtual-env
	$(VIRTUAL_ENV_PYTHON_M_PIP) install --no-deps -e ./semaphore-core
	$(VIRTUAL_ENV_PYTHON_M_PIP) install --no-deps -e ./semaphore-backends-memory
	$(VIRTUAL_ENV_PYTHON_M_PIP) install --no-deps -e ./semaphore-backends-filesystem
	$(VIRTUAL_ENV_PYTHON_M_PIP) install --no-deps -e ./semaphore-backends-redis

# Running `make production` will ensure a virtualenv is set up and minimal packages are installed.  A virtualenv is
# important to use in production builds to ensure that system level packages are not being loaded and inadvertantly not
# included in any build artifacts.
production: \
	production-upgrade-virtual-env \
	production-install-editable-package \
	noop

# This target is a bit of a doozy.  It will clean requirements/*.txt and then compile `requirements/constraints.txt`
# from `requirements/*.in` files.  This reference `constraints` hashed requirements file is then used to ensure proper
# versions and hashes are supplied to the `bootstrap`, `deployment`, `development`, and `production` requirements
# files.
#
# This process allows us to maintain distinct requirements files and subsequently install/synchronize multiple
# requirements files without having to manually maintain the versions and hashes in multiple places.
requirements:
	# Clean this out so that we are always drawing from `constraints.txt`.
	rm -f requirements/bootstrap.txt
	rm -f requirements/development.txt
	rm -f requirements/production.txt
	rm -f requirements/deployment.txt

	# Compile the constraints from all of the input files.
	$(VIRTUAL_ENV_PYTHON_M_PIP_TOOLS) compile \
		--verbose \
		--allow-unsafe \
		--generate-hashes \
		--no-emit-index-url \
		--no-emit-options \
		--no-emit-trusted-host \
		--no-reuse-hashes \
		--output-file=requirements/constraints.txt \
		--resolver=backtracking \
		--strip-extras \
	    --upgrade \
		requirements/*.in

	# Fill in all the hashes.. sigh..
	$(VIRTUAL_ENV_PYTHON_M_PIP_TOOLS) compile \
		--verbose \
		--allow-unsafe \
		--generate-hashes \
		--no-emit-index-url \
		--no-emit-options \
		--no-emit-trusted-host \
		--no-reuse-hashes \
		--output-file=requirements/constraints.txt \
		--resolver=backtracking \
		--strip-extras \
		requirements/*.in

	# Compile the bootstrap requirements.
	$(VIRTUAL_ENV_PYTHON_M_PIP_TOOLS) compile \
		--verbose \
		--allow-unsafe \
		--generate-hashes \
		--no-emit-index-url \
		--no-emit-options \
		--no-emit-trusted-host \
		--no-reuse-hashes \
		--output-file=requirements/bootstrap.txt \
		--resolver=backtracking \
		--strip-extras \
		requirements/constraints.in.inc \
		requirements/bootstrap.in

	# Compile the deployment requirements.
	$(VIRTUAL_ENV_PYTHON_M_PIP_TOOLS) compile \
		--verbose \
		--allow-unsafe \
		--generate-hashes \
		--no-emit-index-url \
		--no-emit-options \
		--no-emit-trusted-host \
		--no-reuse-hashes \
		--output-file=requirements/deployment.txt \
		--resolver=backtracking \
		--strip-extras \
		requirements/constraints.in.inc \
		requirements/deployment.in

	# Compile the development requirements.
	$(VIRTUAL_ENV_PYTHON_M_PIP_TOOLS) compile \
		--verbose \
		--allow-unsafe \
		--generate-hashes \
		--no-emit-index-url \
		--no-emit-options \
		--no-emit-trusted-host \
		--no-reuse-hashes \
		--output-file=requirements/development.txt \
		--resolver=backtracking \
		--strip-extras \
		requirements/constraints.in.inc \
		requirements/development.in

	# Compile the production requirements.
	$(VIRTUAL_ENV_PYTHON_M_PIP_TOOLS) compile \
		--verbose \
		--allow-unsafe \
		--generate-hashes \
		--no-emit-index-url \
		--no-emit-options \
		--no-emit-trusted-host \
		--no-reuse-hashes \
		--output-file=requirements/production.txt \
		--resolver=backtracking \
		--strip-extras \
		requirements/constraints.in.inc \
		requirements/production.in

# Essentially a macro to run toml-sort on the pyproject.toml file to ensure proper diffability.
pyproject: pyproject.toml

pyproject.toml:
	# Sort the pyproject.toml file.
	$(VIRTUAL_ENV_TOML_SORT) \
		--in-place \
		--sort-inline-arrays \
		--sort-inline-tables \
		--sort-table-keys \
		--spaces-indent-inline-array 4 \
		--trailing-comma-inline-array \
		$@

# This just runs tox and ensures the `development` target is run.  This is actually a bit silly as well since tox
# usually runs in a matrix of isolated environments - but if tox is set to run in the current environment it will at
# least have everything it needs to complete.
test: development
	$(VIRTUAL_ENV_PYTHON_M_TOX)

# Run the `build` module.  This might want to be dockerized at some point to ensure that the build environment is always
# the same as our deployment platform, architecture, and operating system.
build:
	$(VIRTUAL_ENV_PYTHON_M_BUILD)

.PHONY: \
	build \
	development \
	development-install-editable-package \
	development-install-pre-commit \
	development-upgrade-pre-commit \
	development-upgrade-virtual-env \
	ntm-weathermap.code-workspace \
	production \
	production-upgrade-virtual-env \
	pyproject.toml \
	requirements \
	test \
	noop
