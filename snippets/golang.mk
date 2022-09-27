# vendor dependencies, build, run, test, lint and cover golang source code

################################################################################
# Static user variables
################################################################################

GOLANG_BUILD_DIR ?= ./bin

GOLANG_TAGS ?=

GOLANG_FLAGS ?= -race

GOLANG_RUN_FLAGS ?=

GOLANG_TEST_FLAGS ?=

GOLANG_COVER_FLAGS ?= -cover

GOLANG_COVERPROFILE ?= coverage/go.out

GOLANG_COVERPROFILE_HTML := coverage/go.html

GOLANG_VENDOR_DIR ?= vendor/

GOLANG_VENDOR ?= 0

### binaries
#+ go binary path
GO ?= go
#+ golang lint command
GOLANG_LINT ?= golangci-lint run

################################################################################
# Dynamic user variables
################################################################################

### misc
#+ disables build optimizations for debugging
GOLANG_DEBUG ?= $(or ${DEBUG},0)

GOLANG_PACKAGE ?= $(shell ${GO} list 2> /dev/null)

GOLANG_BIN ?= $(shell ${GO} list -f '{{ .Name }}' 2> /dev/null)

ifeq (${GOLANG_DEBUG},1)
GOLANG_GCFLAGS ?= "-l -N -L"
GOLANG_LDFLAGS ?= ""
else
GOLANG_GCFLAGS ?= ""
GOLANG_LDFLAGS ?= "-w -s"
endif
GOLANG_BUILD_FLAGS ?= -gcflags ${GOLANG_GCFLAGS} -ldflags ${GOLANG_LDFLAGS}

ifneq ($(wildcard main.go),)
GOLANG_RUN ?= main.go
else ifneq ($(wildcard cmd),)
GOLANG_RUN ?= ./cmd/...
else
GOLANG_RUN ?= .
endif

################################################################################
# Internal settings
################################################################################

ifneq ($(shell type -p ${GO} > /dev/null 2>&1; echo $$?),0)
	$(error ${GO} not found)
endif

ifneq ($(shell type -p ${GOLANG_LINT} > /dev/null 2>&1; echo $$?),0)
	$(error ${GOLANG_LINT} not found)
endif

GOLANG_SOURCE_DIRS := $(shell ${GO} list -f '{{ .Dir }}' ./...)
GOLANG_SOURCE_FILES := $(shell ${GO} list -f '{{ range .GoFiles }}{{ printf "%s/%s\n" $$.Dir . }}{{ end }}' ./...)
GOLANG_SOURCE_TEST_FILES := $(shell ${GO} list -f '{{ range .TestGoFiles }}{{ printf "%s/%s\n" $$.Dir . }}{{ end }}' ./...)
GOLANG_SOURCE_XTEST_FILES := $(shell ${GO} list -f '{{ range .XTestGoFiles }}{{ printf "%s/%s\n" $$.Dir . }}{{ end }}' ./...)

ifeq (${GOLANG_VENDOR},1)
golang-run: ${GOLANG_VENDOR_DIR}
endif

################################################################################
### phony rules
################################################################################

.PHONY: golang-build
golang-build: ${GOLANG_BUILD_DIR}/${GOLANG_BIN}

.PHONY: golang-clean
golang-clean:
	${RM} ${GOLANG_BUILD_DIR}/${GOLANG_BIN}
	${RM} ${GOLANG_COVERPROFILE}
	${RM} ${GOLANG_COVERPROFILE_HTML}
	${GO} clean -i -cache -testcache ./...

.PHONY: golang-coverage
golang-coverage: ${GOLANG_COVERPROFILE}
	@${GO} tool cover -func=$<

.PHONY: golang-coverage-html
golang-coverage-html: ${GOLANG_COVERPROFILE_HTML}

.PHONY: golang-lint
golang-lint:
	${GOLANG_LINT}

.PHONY: golang-test
golang-test:
	${GO} test ${GOLANG_FLAGS} -tags "${GOLANG_TAGS}" ${GOLANG_TEST_FLAGS} ./...

.PHONY: golang-run
golang-run: ${GOLANG_SOURCE_FILES}
	${GO} run ${GOLANG_FLAGS} -tags "${GOLANG_TAGS}" ${GOLANG_RUN_FLAGS} ${GOLANG_RUN} ${GOLANG_RUN_ARGS}

.PHONY: golang-vendor
golang-vendor: ${GOLANG_VENDOR_DIR}

################################################################################
### chain rules
################################################################################

${GOLANG_VENDOR_DIR}: go.sum
	${GO} mod vendor
	@mkdir -p ${GOLANG_VENDOR_DIR}

go.sum: go.mod
	${GO} mod download
	@touch go.sum

go.mod: ${GOLANG_SOURCE_FILES} ${GOLANG_SOURCE_TEST_FILES} ${GOLANG_SOURCE_XTEST_FILES}
	${GO} mod tidy

# TODO change bin strategy to support multi-cmd repositories OoB
${GOLANG_BUILD_DIR}/${GOLANG_BIN}: ${GOLANG_SOURCE_FILES} ${GOLANG_VENDOR_DIR}
	${GO} build ${GOLANG_FLAGS} -tags "${GOLANG_TAGS}" ${GOLANG_BUILD_FLAGS} -o ${GOLANG_BUILD_DIR}/ ./...

################################################################################
### pattern rules
################################################################################

.PRECIOUS: ${GOLANG_COVERPROFILE}
${GOLANG_COVERPROFILE_HTML}: ${GOLANG_COVERPROFILE}
	@mkdir -p $(dir $@)
	${GO} tool cover -html=$< -o $@

${GOLANG_COVERPROFILE}: ${GOLANG_SOURCE_FILES} ${GOLANG_SOURCE_TEST_FILES} ${GOLANG_SOURCE_XTEST_FILES}
	@mkdir -p $(dir $@)
	-${GO} test ${GOLANG_FLAGS} -tags "${GOLANG_TAGS}" ${GOLANG_TEST_FLAGS} ${GOLANG_COVER_FLAGS} -coverprofile=$@ ./...
