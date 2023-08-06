VESC_TOOL ?= vesc_tool

all: gitlit.vescpkg

gitlit.vescpkg:
	$(VESC_TOOL) --buildPkg "gitlit.vescpkg:pn532.lisp::0:README.md:GITLIT"

clean:
	rm -f gitlit.vescpkg

.PHONY: all clean
