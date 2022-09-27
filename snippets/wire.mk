# manage generated golang code using google/wire dependency injection package

################################################################################
# Static user variables
################################################################################

### binaries
#+ wire binary path
WIRE ?= wire
ifneq ($(shell type -p ${WIRE} >/dev/null 2>&1; echo $$?),0)
	$(error ${WIRE} not found)
endif

GOLANG_TAGS ?=

################################################################################
# Dynamic user variables
################################################################################

################################################################################
# Internal settings
################################################################################

WIRE_SRC_FILES := $(shell go list -tags "!wireinject ${GOLANG_TAGS}" -f '{{ range .IgnoredGoFiles }}{{ printf "%s/%s\n" $$.Dir . }}{{ end }}' ./... | grep -v _gen.go)
WIRE_GEN_FILES := $(patsubst %.go,%_gen.go,${WIRE_SRC_FILES})

################################################################################
### phony rules
################################################################################

.PHONY: wire-build
wire-build: ${WIRE_GEN_FILES}

.PHONY: wire-clean
wire-clean:
	${RM} ${WIRE_GEN_FILES}

################################################################################
### pattern rules
################################################################################

%_gen.go: %.go
	${WIRE} ./...
