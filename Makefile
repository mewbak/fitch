include Makefile.detect-coq-version
include Makefile.ml-files

ifeq (,$(filter $(COQVERSION),8.9 8.10 dev))
$(error "only compatible with Coq version 8.9 or later")
endif

COQPROJECT_EXISTS = $(wildcard _CoqProject)
ifeq "$(COQPROJECT_EXISTS)" ""
$(error "Run ./configure before running make")
endif

OCAMLBUILD = ocamlbuild -use-ocamlfind -tag safe_string -syntax camlp4o -pkgs 'camlp4.lib camlp4.extend' -cflag -g
OTT = ott
PDFLATEX = pdflatex

OTTFILES = fitch.ott
VFILES = $(OTTFILES:.ott=.v)

default: Makefile.coq
	$(MAKE) -f Makefile.coq

checker: checker.native

prolog: prolog.native

checker.native: $(FITCHML) util.ml checker.ml
	$(OCAMLBUILD) checker.native

prolog.native: $(FITCHML) util.ml prolog.ml
	$(OCAMLBUILD) prolog.native

Makefile.coq: $(VFILES)
	coq_makefile -f _CoqProject -o Makefile.coq

$(VFILES): %.v: %.ott
	$(OTT) -o $@ -coq_expand_list_types false $<

fitchScript.sml: fitch.ott
	$(OTT) -o fitchScript.sml fitch.ott

$(FITCHML): Makefile.coq
	$(MAKE) -f Makefile.coq $@

fitch_defs.tex: fitch.ott
	$(OTT) -o fitch_defs.tex -tex_wrap false fitch.ott

fitch.tex: fitch.mng fitch.ott
	$(OTT) -tex_filter fitch.mng fitch.tex fitch.ott

fitch.pdf: fitch_defs.tex fitch.tex
	$(PDFLATEX) fitch.tex
	$(PDFLATEX) fitch.tex

clean: Makefile.coq
	$(MAKE) -f Makefile.coq cleanall
	rm -f Makefile.coq Makefile.coq.conf $(VFILES)
	$(OCAMLBUILD) -clean

.PHONY: default clean checker prolog $(FITCHML)
.NOTPARALLEL: $(FITCHML)
