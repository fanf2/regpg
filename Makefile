# Makefile for regpg

.POSIX:

prefix =	${HOME}
bindir =	${prefix}/bin
mandir =	${prefix}/share/man
man1dir=	${mandir}/man1

bindest=	${DESTDIR}${bindir}
man1dest=	${DESTDIR}${man1dir}

PROGS=		regpg

markdown=	2017-04-03-rationale.md

htmlfiles=	regpg.html README.html ${markdown:.md=.html}
man1files=	regpg.1

DOCS=		${htmlfiles} ${man1files}

all: ${DOCS}

install: all
	install -m 755 -d ${bindest}
	install -m 755 ${PROGS} ${bindest}/
	install -m 755 -d ${man1dest}
	install -m 644 ${man1files} ${man1dest}/

clean:
	rm -f ${DOCS}

regpg.1: regpg
	pod2man regpg regpg.1

regpg.html: regpg util/fixhtml.sed
	pod2html regpg | sed -f util/fixhtml.sed >regpg.html
	rm -f pod2htm?.tmp

.SUFFIXES: .md .html

.md.html:
	markdown <$< >$@

release: ${DOCS}
	util/release.sh ${DOCS}

upload: all
	git push --tags github master
	git push --tags dotat master
	git push --tags uis master
	ln -sf README.html index.html
	rsync -ilrt ${PROGS} ${htmlfiles} \
		index.html dist \
		chiark:public-html/prog/regpg/
	rm -f index.html
