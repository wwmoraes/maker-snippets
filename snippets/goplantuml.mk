# generate PlantUML diagrams from golang source code using goplantuml

################################################################################
# Static user variables
################################################################################

### binaries
#+ go binary path
GO ?= go
#+ goplantuml binary path
GOPLANTUML ?= goplantuml

GOPLANTUML_TARGET_DIR ?= diagrams

################################################################################
# Dynamic user variables
################################################################################

GOPLANTUML_TARGET_FILENAME ?= $(shell basename ${PWD})_gen.puml

################################################################################
# Internal settings
################################################################################

ifneq ($(shell type -p ${GO} >/dev/null 2>&1; echo $$?),0)
	$(error ${GO} not found)
endif

ifneq ($(shell type -p ${GOPLANTUML} >/dev/null 2>&1; echo $$?),0)
	$(error ${GOPLANTUML} not found)
endif

GOPLANTUML_SOURCE_DIRS = $(shell ${GO} list -f '{{ .Dir }}' ./...)

GOPLANTUML_TARGET_FILE := ${GOPLANTUML_TARGET_DIR}/${GOPLANTUML_TARGET_FILENAME}

################################################################################
### phony rules
################################################################################

.PHONY: goplantuml-run #= generates the diagrams
goplantuml-run: ${GOPLANTUML_TARGET_FILE}

################################################################################
### pattern rules
################################################################################

# set as phony to force regeneration, otherwise source file changes won't trigger it
.PHONY: ${GOPLANTUML_TARGET_FILE}
${GOPLANTUML_TARGET_FILE}: ${GOPLANTUML_SOURCE_DIRS}
	@mkdir -p $(dir $@)
	@${GOPLANTUML} -recursive $^ > $@
