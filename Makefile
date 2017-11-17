# Makefile for regpg

.POSIX:

prefix =	${HOME}
bindir =	${prefix}/bin
mandir =	${prefix}/share/man
man1dir=	${mandir}/man1

bindest=	${DESTDIR}${bindir}
man1dest=	${DESTDIR}${man1dir}

PROGS=		regpg

markdown=	doc/contributing.md	\
		doc/rationale.md	\
		doc/secrets.md		\
		doc/threat-model.md	\
		doc/tutorial.md		\
		README.md

htmlfiles=	regpg.html ${markdown:.md=.html}
man1files=	regpg.1

DOCS=		${htmlfiles} ${man1files}

all: ${DOCS}

install: all
	install -m 755 -d ${bindest}
	install -m 755 ${PROGS} ${bindest}/
	install -m 755 -d ${man1dest}
	install -m 644 ${man1files} ${man1dest}/

uninstall:
	for f in ${PROGS}; do rm -f ${bindest}/$$f; done
	for f in ${man1files}; do rm -f ${man1dest}/$$f; done

clean:
	rm -f ${DOCS} index.html
	rm -rf t/gnupg t/work

test:
	perlcritic regpg
	prove

regpg.1: regpg
	pod2man regpg regpg.1

regpg.html: regpg
	pod2html --noindex --css=doc/style.css \
		--title 'regpg reference manual' \
		regpg >regpg.html
	rm -f pod2htm?.tmp

index.html: README.html logo/iframe.pl
	logo/iframe.pl <README.html >index.html

.SUFFIXES: .md .html

.md.html:
	util/markdown.pl $< $@

release: ${DOCS}
	util/release.sh ${DOCS}

upload: ${DOCS} index.html
	util/upload.sh
