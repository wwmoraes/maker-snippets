# generate SVG and PNG from PlantUML diagram source files

################################################################################
# Static user variables
################################################################################

### binaries
#+ java binary path
JAVA ?= java
ifneq ($(shell type -p $(JAVA) >/dev/null 2>&1; echo $$?),0)
	$(error $(JAVA) not found)
endif

PLANTUML_DIR ?= diagrams
PLANTUML_FLAGS ?=

################################################################################
# Dynamic user variables
################################################################################

#+ plantuml jar file path
PLANTUML_JAR_PATH ?= ${HOME}/.local/bin/plantuml.jar
ifeq ($(wildcard $(PLANTUML_JAR_PATH)),)
	$(error $(PLANTUML_JAR_PATH) not found)
endif

################################################################################
# Internal settings
################################################################################

PLANTUML := ${JAVA} -Djava.awt.headless=true ${PLANTUML_FLAGS} -jar ${PLANTUML_JAR_PATH}
PLANTUML_SRC_FILES := ${PLANTUML_DIR}/${PLANTUML_GENERATED_FILE} $(wildcard ${PLANTUML_DIR}/*.puml)
PLANTUML_SVGS := $(patsubst %.puml,%.svg,${PLANTUML_SRC_FILES})
PLANTUML_PNGS := $(patsubst %.puml,%.png,${PLANTUML_SRC_FILES})
PLANTUML_IMAGES := ${PLANTUML_SVGS} ${PLANTUML_PNGS}

################################################################################
### phony rules
################################################################################

.PHONY: plantuml-render
plantuml-render: plantuml-render-pngs plantuml-render-svgs

.PHONY: plantuml-render-pngs
plantuml-render-pngs: ${PLANTUML_PNGS}

.PHONY: plantuml-render-svgs
plantuml-render-svgs: ${PLANTUML_SVGS}

.PHONY: plantuml-clean
plantuml-clean: plantuml-clean-pngs plantuml-clean-svgs

.PHONY: plantuml-clean-pngs
plantuml-clean-pngs:
	$(RM) ${PLANTUML_PNGS}

.PHONY: plantuml-clean-svgs
plantuml-clean-svgs:
	$(RM) ${PLANTUML_SVGS}

################################################################################
### pattern rules
################################################################################

${PLANTUML_DIR}/%.svg: ${PLANTUML_DIR}/%.puml
	@${PLANTUML} -p -tsvg $< > $@

${PLANTUML_DIR}/%.png: ${PLANTUML_DIR}/%.puml
	@${PLANTUML} -p -tpng $< > $@
