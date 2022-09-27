# parses help messages from Makefile targets and variables

################################################################################
# Static user variables
################################################################################

#+ target documentation marker
HELP_MARKER_TARGET ?= \#=

### TODO change var marker to something regex-friendly
#+ variable documentation marker
HELP_MARKER_VAR ?= \#+

################################################################################
# Internal variables
################################################################################
HELP_FS := $(shell printf "\034")

ifneq ($(shell type -p grep >/dev/null 2>&1; echo $$?),0)
	$(error grep not found)
endif
ifneq ($(shell type -p sed >/dev/null 2>&1; echo $$?),0)
	$(error sed not found)
endif
ifneq ($(shell type -p awk >/dev/null 2>&1; echo $$?),0)
	$(error awk not found)
endif
ifneq ($(shell type -p column >/dev/null 2>&1; echo $$?),0)
	$(error column not found)
endif

################################################################################
# Phony rules
################################################################################
help-targets: #= show target help
	@grep -hE "^\S+:.*${HELP_MARKER_TARGET}" ${MAKEFILE_LIST} |\
		sed -e 's/\\$$//' |\
		sed -e 's/:.*${HELP_MARKER_TARGET}[ ]*/${HELP_FS}/' |\
		column -c2 -t -s${HELP_FS}

help-variables: #= show variable help
	@grep -A 1 -hE "^#\+" ${MAKEFILE_LIST} |\
		awk 'BEGIN{RS="\n--\n";FS=""} \
			/.*\n.*\?=.*/ {\
				$$0 = gensub(/^#\+[ ]*([^\n]*)\n(\w+)[ ]*\?=[ ]*([^\r\n]*)/,"\\2${HELP_FS}\\1 (default \"\\3\")", "g", $$0);\
				print\
			}' |\
		column -c2 -t -s${HELP_FS}
