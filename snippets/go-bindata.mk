# manage generated golang asset files using go-bindata/go-bindata package

################################################################################
# Static user variables
################################################################################

GO_BINDATA ?= go-bindata
GO_BINDATA_DIR ?= assets
GO_BINDATA_PKG ?= assets
GO_BINDATA_FILENAME ?= assets.go

################################################################################
# Internal settings
################################################################################

ifneq ($(shell type -p ${GO_BINDATA} >/dev/null 2>&1; echo $$?),0)
	$(error ${GO_BINDATA} not found)
endif

GO_BINDATA_TARGET_FILE := ${GO_BINDATA_DIR}/${GO_BINDATA_FILENAME}
GO_BINDATA_SRC_FILES := $(filter-out ${GO_BINDATA_TARGET_FILE},$(wildcard ${GO_BINDATA_DIR}/*))

################################################################################
### phony rules
################################################################################

.PHONY: go-bindata-build
go-bindata-build: ${GO_BINDATA_TARGET_FILE}

.PHONY: go-bindata-clean
go-bindata-clean:
	${RM} ${GO_BINDATA_TARGET_FILE}

################################################################################
### chain rules
################################################################################

${GO_BINDATA_TARGET_FILE}: ${GO_BINDATA_SRC_FILES}
	${GO_BINDATA} -o $@ -pkg ${GO_BINDATA_PKG} -nometadata -mode 0664 -nomemcopy ${GO_BINDATA_DIR}
