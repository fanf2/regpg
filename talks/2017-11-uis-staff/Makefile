.POSIX:

BIBTEX= bibtex
PDFLATEX= pdflatex

talk: slides.pdf notes.pdf

rebib:
	${PDFLATEX} notes.tex
	${BIBTEX} notes
	${PDFLATEX} notes.tex
	${PDFLATEX} notes.tex

handout.ps: slides.ps
	psnup -W12.6cm -H9.6cm -pa4 -r -2 slides.ps |\
		sed '/BoundingBox:/d' |\
		psnup -b1cm -2 >handout.ps

slides.ps slides.pdf slides.dvi: talk.tex slides.tex

notes.ps  notes.pdf  notes.dvi:  talk.tex notes.tex

clean:
	rm -f *.aux *.bbl *.blg *.log *.nav *.out *.snm *.toc *.vrb

realclean: clean
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
