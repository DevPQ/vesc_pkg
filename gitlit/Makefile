VESC_TOOL ?= vesc_tool

all: gitlit.vescpkg

gitlit.vescpkg:
	$(VESC_TOOL) --buildPkg "gitlit.vescpkg:gitlit.lisp:ui.qml:0:README.md:GitLit"

clean:
	rm -f gitlit.vescpkg

.PHONY: all clean
