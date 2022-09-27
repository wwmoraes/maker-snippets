# build, push and interact with docker images

################################################################################
# Static user variables
################################################################################

### common
#+ image file path
DOCKER_DOCKERFILE ?= Dockerfile
#+ context directory
DOCKER_CONTEXT ?= .
#+ space-separated variable names to expand as build args
DOCKER_BUILD_ARGS ?=

### tags
#+ edge tag (applied to all builds)
DOCKER_EDGE_TAG ?= edge
#+ latest tag (applied to all builds)
DOCKER_LATEST_TAG ?= latest
#+ tag prefix (applied to non-multiplatform builds)
DOCKER_TAG_PREFIX ?= single-

### buildkit settings
#+ enables multiplatform builds using buildx
DOCKER_MULTIPLATFORM ?= 0
#+ builder name used by buildx
DOCKER_BUILDER_NAME ?= default
#+ target platforms that buildx will build to
DOCKER_PLATFORMS ?= linux/amd64,linux/arm/v7,linux/arm64

### cache
#+ type of cache to use (local, registry or inline)
DOCKER_CACHE ?= local
#+ tag used to build and push the cache (DOCKER_CACHE=registry only)
DOCKER_CACHE_TAG ?= cache

### misc
#+ export directory used by docker-export
DOCKER_EXPORT_DIR ?= tmp/export
#+ container-structure-test configuration file used by docker-test
DOCKER_TEST_FILE ?= docker-test.yaml
#+ shell used by docker-sh
DOCKER_SHELL ?= ash
#+ tag used by the image generated through docker-context
DOCKER_CONTEXT_TAG ?= build-context

### binaries
#+ docker binary path
DOCKER ?= docker
#+ git binary path
GIT ?= git

################################################################################
# Dynamic user variables
################################################################################

### uses UNIX/POSIX TMPDIR, otherwise falls back to mktemp
TMPDIR ?= $(or ${TMPDIR},$(shell dirname $(shell mktemp -u)))

DOCKER_GIT_USERNAME ?= $(or ${GIT_USERNAME},$(shell ${GIT} config user.name 2>/dev/null),unknown)
DOCKER_GIT_USEREMAIL ?= $(or ${GIT_USEREMAIL},$(shell ${GIT} config user.email 2>/dev/null),unknown)
DOCKER_GIT_SHA ?= $(or ${GIT_SHA},$(shell ${GIT} rev-parse --short HEAD 2>/dev/null),unknown)
DOCKER_GIT_DEFAULT_BRANCH ?= $(or ${GIT_DEFAULT_BRANCH},$(basename $(shell ${GIT} symbolic-ref refs/remotes/${DOCKER_GIT_REMOTE_NAME}/HEAD 2>/dev/null)),master)
DOCKER_GIT_BRANCH ?= $(or ${GIT_BRANCH},$(shell ${GIT} rev-parse --abbrev-ref HEAD),${DOCKER_GIT_DEFAULT_BRANCH})
DOCKER_GIT_REMOTE_NAME ?= $(or ${GIT_REMOTE_NAME},$(shell ${GIT} remote 2>/dev/null),origin)
DOCKER_GIT_REV ?= $(or ${GIT_REV},$(shell ${GIT} log -n 1 --format="%H" 2>/dev/null),unknown)
DOCKER_GIT_REMOTE_URL ?= $(or ${GIT_REMOTE_URL},$(shell ${GIT} remote get-url ${DOCKER_GIT_REMOTE_NAME} 2>/dev/null),unknown)
DOCKER_GIT_REPO ?= $(or ${GIT_REPO},${shell echo ${DOCKER_GIT_REMOTE_URL} | sed -E "s%([a-z]+@.*:|https?://[^/]+/)?(.*)\.git%\2%"})

DOCKER_GIT_LAST_TAG ?= $(patsubst v%,%,$(shell ${GIT} describe --tags --abbrev=0 2>/dev/null))
DOCKER_GIT_CURRENT_TAG ?= $(patsubst v%,%,$(shell ${GIT} describe --tags --exact-match 2>/dev/null))
DOCKER_TARGET_VERSION ?= $(or ${DOCKER_GIT_CURRENT_TAG},${DOCKER_GIT_LAST_TAG}+${DOCKER_GIT_SHA})

DOCKER_OCI_TITLE ?= $(or ${OCI_TITLE},${DOCKER_GIT_REPO})
DOCKER_OCI_DESCRIPTION ?= $(or ${OCI_DESCRIPTION},$(shell cat .git/description 2>/dev/null),unknown)
DOCKER_OCI_URL ?= $(or ${OCI_URL},unknown)
DOCKER_OCI_SOURCE ?= $(or ${OCI_SOURCE},unknown)
DOCKER_OCI_VERSION ?= $(or ${OCI_VERSION},${DOCKER_TARGET_VERSION})
DOCKER_OCI_CREATED ?= $(or ${OCI_CREATED},${DATE},$(shell date -u +"%Y-%m-%dT%TZ"))
DOCKER_OCI_REVISION ?= $(or ${OCI_REVISION},${DOCKER_GIT_REV})
DOCKER_OCI_LICENSES ?= $(or ${OCI_LICENSES},unknown)
DOCKER_OCI_AUTHORS ?= $(or ${OCI_AUTHORS},${DOCKER_GIT_USERNAME} <${DOCKER_GIT_USEREMAIL}>)
DOCKER_OCI_DOCUMENTATION ?= $(or ${OCI_DOCUMENTATION},unknown)
DOCKER_OCI_VENDOR ?= $(or ${OCI_VENDOR},${DOCKER_GIT_USERNAME} <${DOCKER_GIT_USEREMAIL}>)

DOCKER_TAGS ?= ${DOCKER_GIT_SHA} ${DOCKER_GIT_BRANCH} ${DOCKER_EDGE_TAG} ${DOCKER_LATEST_TAG}
DOCKER_CACHE_FROM_TAGS ?= ${DOCKER_TAGS} ${DOCKER_GIT_DEFAULT_BRANCH}
DOCKER_CACHE_TO_TAGS ?= ${DOCKER_TAGS}

################################################################################
# Internal settings
################################################################################

ifneq ($(shell type -p ${DOCKER} >/dev/null 2>&1; echo $$?),0)
	$(error ${DOCKER} not found)
endif

# static build context Dockerfile definition
define DOCKER_BUILD_CONTEXT_DOCKERFILE
FROM busybox
WORKDIR /build-context
COPY . .
CMD find .
endef
export DOCKER_BUILD_CONTEXT_DOCKERFILE

# uniq filters out duplicated strings
uniq = $(if $1,$(firstword $1) $(call uniq,$(filter-out $(firstword $1),$1)))

# checks if the Dockerfile contains a LABEL instruction for the label $1
dockerFileContainsLabel = $(shell grep -qE "^LABEL $1=" ${DOCKER_DOCKERFILE}; echo $$?)

# expands a label flag with value $2 if the Dockerfile does not contain a
# LABEL instruction for the label $1
dockerLabelFlag = $(if $(filter-out 0,$(call dockerFileContainsLabel,$1)),--label $1="$($2)")

# expands --label flags, if there's no LABEL instruction for each of them
# (check dockerLabelFlag and dockerFileContainsLabel)
define dockerLabelFlags
	$(call dockerLabelFlag,org.opencontainers.image.title,DOCKER_OCI_TITLE) \
	$(call dockerLabelFlag,org.opencontainers.image.description,DOCKER_OCI_DESCRIPTION) \
	$(call dockerLabelFlag,org.opencontainers.image.url,DOCKER_OCI_URL) \
	$(call dockerLabelFlag,org.opencontainers.image.source,DOCKER_OCI_SOURCE) \
	$(call dockerLabelFlag,org.opencontainers.image.version,DOCKER_OCI_VERSION) \
	$(call dockerLabelFlag,org.opencontainers.image.created,DOCKER_OCI_CREATED) \
	$(call dockerLabelFlag,org.opencontainers.image.revision,DOCKER_OCI_REVISION) \
	$(call dockerLabelFlag,org.opencontainers.image.licenses,DOCKER_OCI_LICENSES) \
	$(call dockerLabelFlag,org.opencontainers.image.authors,DOCKER_OCI_AUTHORS) \
	$(call dockerLabelFlag,org.opencontainers.image.documentation,DOCKER_OCI_DOCUMENTATION) \
	$(call dockerLabelFlag,org.opencontainers.image.vendor,DOCKER_OCI_VENDOR)
endef

# expands --build-arg flags with OCI_* variables used by opencontainer labels,
# and any variables defined on DOCKER_BUILD_ARGS
define dockerBuildArgFlags
	--build-arg OCI_TITLE="${DOCKER_OCI_TITLE}" \
	--build-arg OCI_DESCRIPTION="${DOCKER_OCI_DESCRIPTION}" \
	--build-arg OCI_URL="${DOCKER_OCI_URL}" \
	--build-arg OCI_SOURCE="${DOCKER_OCI_SOURCE}" \
	--build-arg OCI_VERSION="${DOCKER_OCI_VERSION}" \
	--build-arg OCI_CREATED="${DOCKER_OCI_CREATED}" \
	--build-arg OCI_REVISION="${DOCKER_OCI_REVISION}" \
	--build-arg OCI_LICENSES="${DOCKER_OCI_LICENSES}" \
	--build-arg OCI_AUTHORS="${DOCKER_OCI_AUTHORS}" \
	--build-arg OCI_DOCUMENTATION="${DOCKER_OCI_DOCUMENTATION}" \
	--build-arg OCI_VENDOR="${DOCKER_OCI_VENDOR}" \
	$(foreach ARG,${DOCKER_BUILD_ARGS},--build-arg ${ARG}="$(${ARG})")
endef

# expands --tag flags, with optionals prefix $1 and suffix $2
define dockerTagFlags
	$(addprefix --tag ${DOCKER_GIT_REPO}:$1,$(call uniq,${DOCKER_TAGS}))
endef

# expands --cache-from flags, with optionals prefix $1 and suffix $2
define dockerCacheFromCommonFlags
	$(addprefix --cache-from ${DOCKER_GIT_REPO}:$1,$(call uniq,${DOCKER_CACHE_FROM_TAGS}))
endef

# defines the cache functions once
ifeq (${DOCKER_CACHE},local)
define dockerCacheFromFlags
	--cache-from type=local,src=${TMPDIR}/.buildx-cache/${REPO} \
	$(call dockerCacheFromCommonFlags,$1)
endef
define dockerCacheToFlags
	--cache-to type=local,mode=max,dest=${TMPDIR}/.buildx-cache/${REPO}
endef
else ifeq (${DOCKER_CACHE},registry)
define dockerCacheFromFlags
	--cache-from type=registry,ref=${DOCKER_GIT_REPO}:$1${DOCKER_CACHE_TAG} \
	$(call dockerCacheFromCommonFlags,$1)
endef
define dockerCacheToFlags
	--cache-to type=registry,mode=max,ref=${DOCKER_GIT_REPO}:$1,${DOCKER_CACHE_TAG}
endef
else
define dockerCacheFromFlags
	$(call dockerCacheFromCommonFlags,$1)
endef
define dockerCacheToFlags
	--cache-to type=inline
endef
endif

ifneq ($(filter-out local registry inline,${DOCKER_CACHE}),)
	$(error DOCKER_CACHE must be either local, registry or inline)
endif

################################################################################
### phony rules
################################################################################

.PHONY: docker-build
docker-build: ${DOCKER_DOCKERFILE} #= builds and tags the image
ifeq (${DOCKER_MULTIPLATFORM},1)
	-@${DOCKER} buildx inspect --builder ${DOCKER_BUILDER_NAME} 2> /dev/null 2>&1 ||\
		${DOCKER} buildx create --name ${DOCKER_BUILDER_NAME} --use > /dev/null
	@${DOCKER} buildx build --builder ${DOCKER_BUILDER_NAME} \
		--platform ${DOCKER_PLATFORMS} \
		$(call dockerBuildArgFlags) \
		$(call dockerLabelFlags) \
		$(call dockerCacheFromFlags) \
		$(call dockerCacheToFlags) \
		$(call dockerTagFlags) \
		--file $< \
		--load ${DOCKER_CONTEXT}
else
	@${DOCKER} build \
		$(call dockerBuildArgFlags) \
		$(call dockerLabelFlags) \
		$(call dockerCacheFromFlags,${DOCKER_TAG_PREFIX}) \
		$(call dockerCacheToFlags,${DOCKER_TAG_PREFIX}) \
		$(call dockerTagFlags,${DOCKER_TAG_PREFIX}) \
		--file ${DOCKER_DOCKERFILE} ${DOCKER_CONTEXT}
endif

.PHONY: docker-clean
docker-clean: #= removes all local image builds related to this project
	@${DOCKER} image ls --format '{{ .Repository }}:{{ .Tag }}' ${DOCKER_GIT_REPO} |\
	ifne xargs ${DOCKER} image rm -f

.PHONY: docker-sh
docker-sh: docker-build #= executes DOCKER_SHELL within the current edge-tagged image
	${DOCKER} run --rm -it --entrypoint=${DOCKER_SHELL} ${DOCKER_GIT_REPO}:${DOCKER_TAG_PREFIX}${DOCKER_EDGE_TAG}

.PHONY: docker-test
docker-test: docker-build ${DOCKER_TEST_FILE} #= tests the current edge-tagged image with container-structure-test
	@docker run --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v ${PWD}/${DOCKER_TEST_FILE}:/config.yaml \
		gcr.io/gcp-runtimes/container-structure-test:latest test \
		--image ${DOCKER_GIT_REPO}:${DOCKER_TAG_PREFIX}${DOCKER_EDGE_TAG} \
		--config config.yaml

.PHONY: docker-scan
docker-scan: docker-build ${DOCKER_DOCKERFILE} #= scans the current edge-tagged image for vulnerabilities
	docker scan \
		--accept-license \
		--file ${DOCKER_DOCKERFILE} \
		${DOCKER_GIT_REPO}:${DOCKER_TAG_PREFIX}${DOCKER_EDGE_TAG}

.PHONY: docker-export
docker-export: docker-build #= exports the current edge-tagged image contents to DOCKER_EXPORT_DIR
	@${RM} -r ${DOCKER_EXPORT_DIR}
	@mkdir -p ${DOCKER_EXPORT_DIR}
	$(info creating temporary container...)
	@${DOCKER} create --name=tmp_$$PPID ${DOCKER_GIT_REPO}:${DOCKER_TAG_PREFIX}${DOCKER_EDGE_TAG} > /dev/null
	$(info exporting to ${DOCKER_EXPORT_DIR}...)
	@${DOCKER} export tmp_$$PPID | tar xf - -C ${DOCKER_EXPORT_DIR}
	$(info removing temporary container...)
	@${DOCKER} rm tmp_$$PPID > /dev/null

.PHONY: docker-context
docker-context: #= outputs the context available during builds
	@echo "$$DOCKER_BUILD_CONTEXT_DOCKERFILE" | ${DOCKER} build -t ${DOCKER_GIT_REPO}:${DOCKER_CONTEXT_TAG} -f - .
	-@${DOCKER} run --rm ${DOCKER_GIT_REPO}:${DOCKER_CONTEXT_TAG}
	@${DOCKER} image rm ${DOCKER_GIT_REPO}:${DOCKER_CONTEXT_TAG}
