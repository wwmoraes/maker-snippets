# maker-snippets

> Collection of GNU Make snippets manageable by Maker

![Status](https://img.shields.io/badge/status-active-success.svg)
[![GitHub Issues](https://img.shields.io/github/issues/wwmoraes/maker-snippets.svg)](https://github.com/wwmoraes/maker-snippets/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/wwmoraes/maker-snippets.svg)](https://github.com/wwmoraes/maker-snippets/pulls)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](/LICENSE)

---

## 📝 Table of Contents

- [About](#-about)
- [Getting Started](#-getting-started)
- [Usage](#-usage)
- [TODO](./TODO.md)
- [Contributing](./CONTRIBUTING.md)
- [Authors](#-authors)
- [Acknowledgments](#-acknowledgements)

## 🧐 About

Generic GNU Make snippets that can be included and composed into final targets.

## 🏁 Getting Started

The snippets here add support for tools and technologies beyond the implicit
rules that ship with GNU Make. This enables working with multiple technologies
using a single build utility.

Snippets on this repository are compatible with GNU Make version 3 onwards.

### Installing

Use [`maker`][maker] to manage these snippets within your projects. If you don't
want yet another tool, then you can either clone this repository and or download
the desired snippets individually.

## 🔧 Running the tests

Use `make` with the dry-run flag to validate the snippet syntax:

```shell
make -n -f path/to/snippet.mk [target]
```

There's no integration tests for now, due to the lack of proper tooling and
practice on doing so for make files.

## 🎈 Usage

Follow the [`maker`][maker] up-to-date instructions on how to change your make
file to use the snippets. If you're managing the snippets manually, then include
them directly. A general structure for the main Makefile is:

```makefile
### Disable built-in rules, variables and suffixes to prevent any conflicts.
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables
.SUFFIXES:

### Define the target to be executed if none is given.
.DEFAULT_GOAL := all

### Pre-include variables
### This is the preferred way to configure snippets. The variables that can be
### set here are available in the snippets file head, and are lazily set using
### the ?= operator to fallback to sensible defaults.
GO := go # example of a binary path variable
DEBUG := 1 # example of a flag variable

#### include snippets
include .make/*.mk

### Post-include variables
### This should only be used as a last-resort. It is useful to set variables
### that aren't settable by default, or to replace undesired expanded values
### Note: overriding variables may break functionality, so you're on your own!
# override B_VAR += value

### Chains common rule names to execute the snippet ones
.PHONY: all
all: build lint test coverage

.PHONY: build
build: golang-build

.PHONY: clean
clean: golang-clean

.PHONY: test
test: golang-test

.PHONY: coverage
coverage: golang-coverage golang-coverage-html

.PHONY: lint
lint: golang-lint

### You can still have your own custom rules
custom-target:
  @echo "$@ ran!"
```

You can then use `make all`, `make build`, etc as usual.

## 🧑‍💻 Authors

- [@wwmoraes](https://github.com/wwmoraes) - Idea & Initial work

## 🎉 Acknowledgements

- GNU Project for creating and maintaining the Make tool

[maker]: https://github.com/wwmoraes/maker
