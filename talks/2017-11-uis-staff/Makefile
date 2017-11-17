.POSIX:

BIBTEX= bibtex
PDFLATEX= pdflatex

all: slides.pdf notes.pdf

rebib:
	${PDFLATEX} notes.tex
	${BIBTEX} notes
	${PDFLATEX} notes.tex
	${PDFLATEX} notes.tex

slides.ps slides.pdf slides.dvi: talk.tex slides.tex

notes.ps  notes.pdf  notes.dvi:  talk.tex notes.tex

tidy:
	rm -f *.aux *.bbl *.blg *.log *.nav *.out *.snm *.toc *.vrb

clean: tidy
	rm -f *.pdf *.ps *.dvi *.html
	rm -f core *.core '#'*'#' *~

.SUFFIXES: .tex .dvi .pdf .ps .md .html

.pdf.ps:
	pdf2ps $<

.tex.pdf:
	${PDFLATEX} $<

.tex.dvi:
	${DVILATEX} $<

.md.html:
	markdown <$< >$@
