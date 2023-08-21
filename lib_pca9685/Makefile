VESC_TOOL ?= vesc_tool

all: pca9685.vescpkg

pca9685.vescpkg:
	$(VESC_TOOL) --buildPkg "pca9685.vescpkg:pca9685.lisp::0:README.md:PCA9685"

clean:
	rm -f pca9685.vescpkg README.md

.PHONY: all clean
