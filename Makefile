#
# husk-scheme
# http://github.com/justinethier/husk-scheme
#
# Written by Justin Ethier
#
# Make file used to build husk and run test cases.
#

SRC=$(wildcard hs-src/Language/Scheme/*.hs hs-src/Language/Scheme/Macro/*.hs)
HUSKC_SRC=$(wildcard hs-src/Compiler/*.hs)
HUSKI_SRC=$(wildcard hs-src/Interpreter/*.hs)

GHCOPTS=-Wall --make -package parsec -package ghc

# Currently have the FFI disabled
GHCFLAGS=-f-useffi
#GHCFLAGS=

HUSKC = huskc
HUSKI = huski
UNIT_TEST_DIR = tests

all: config build
config:
	cabal configure --prefix=$(HOME) --user $(GHCFLAGS)
build:
	cabal build
install:
	cabal install $(GHCFLAGS)
sdist:
	cabal sdist
doc:
	# Create API documentation
	cabal haddock 

# Build an RPM
rpm:
	rpmbuild -ba misc/ghc-husk-scheme.spec

# Run all unit tests
test: stdlib.scm
	$(HUSKI) $(UNIT_TEST_DIR)/r5rs_pitfall.scm
	@cd $(UNIT_TEST_DIR) ; $(HUSKI) run-tests.scm

# Run (experimental) compiler unit tests
testc: stdlib.scm
	$(HUSKC) $(UNIT_TEST_DIR)/compiler/t-basic.scm
	$(UNIT_TEST_DIR)/compiler/t-basic
	$(HUSKC) $(UNIT_TEST_DIR)/compiler/er-macro.scm
	$(UNIT_TEST_DIR)/compiler/er-macro

# Create tag files to ease souce code browsing
tags:
	hasktags $(SRC) $(HUSKI_SRC) $(HUSKC_SRC)

# Delete all temporary files generated by a build
clean:
	rm -f huski huskc tags TAGS
	rm -rf dist tests/compiler/t-basic tests/compiler/er-macro
	find . -type f -name "*.hi" -exec rm -f {} \;
	find . -type f -name "*.o" -exec rm -f {} \;


###########################################################
# Legacy directives
###########################################################


husk: huski huskc

# Run a "simple" build using GHC directly 
# ghc options for profiling: -prof -auto-all -rtsopts 
huski: $(SRC) $(HUSKI_SRC) 
	ghc -fglasgow-exts $(GHCOPTS) -o huski $(SRC) $(HUSKI_SRC) 

huskc: $(SRC) $(HUSKC_SRC)
	ghc -fglasgow-exts $(GHCOPTS) -o huskc $(SRC) $(HUSKC_SRC) 

# An experimental target to create a smaller, dynamically linked executable using GHC directly 
# See: http://stackoverflow.com/questions/699908/making-small-haskell-executables
#
husk-small: $(SRC) $(HUSKI_SRC)
	ghc $(GHCOPTS) -o huski $(SRC) $(HUSKI_SRC)
#	ghc -dynamic $(GHCOPTS) -Wall --make -package parsec -package ghc -fglasgow-exts -o huski $(SRC) $(HUSKI_SRC)
	strip -p --strip-unneeded --remove-section=.comment -o huski-small huski

# Create files for distribution
dist:
	runhaskell Setup.hs configure --prefix=$(HOME) --user && runhaskell Setup.hs build && runhaskell Setup.hs install && runhaskell Setup.hs sdist
# Note: Use --enable-shared in the configure above, if dynamic linking will be used
