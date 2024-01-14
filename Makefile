prefix      = /usr/local
dirmode     = 0755
filemode    = 0444
binmode     = 0555

sharedir    = ${prefix}/share/pagpapanatili
examplesdir = ${sharedir}/examples
profilesdir = ${sharedir}/profiles.d
bindir      = ${prefix}/bin
testdir     = /tmp/pagpapanatili

all:

mkdirs:
	install -d -m ${dirmode} "${sharedir}" "${examplesdir}" "${profilesdir}"
	test -d "${bindir}" || install -d -m ${dirmode} "${bindir}"

install-bin: mkdirs
	install -m ${binmode} pag "${bindir}"

install-share: mkdirs
	install -m ${filemode} profiles.yaml "${sharedir}"
	install -m ${binmode} restic-wrapper "${sharedir}"
	install -m ${filemode} shared.subr configure.subr "${sharedir}"

install-examples: mkdirs
	install -m ${filemode} examples/* "${examplesdir}"

install-profiles: mkdirs
	install -m ${filemode} profiles/* "${profilesdir}"

test:
	${MAKE} prefix=$(testdir) install
	env AWS_CONFIG_FILE=$(testdir)/config/aws/config \
	    AWS_SHARED_CREDENTIALS_FILE=$(testdir)/config/aws/credentials \
	    AYUSIN_USER_CONFIG_DIR=$(testdir)/config/ayusin \
	    PAGPAPANATILI_USER_CONFIG_DIR=$(testdir)/config/pagpapanatili \
	    $(testdir)/bin/pag ${command}

install: install-share install-examples install-profiles install-bin

.PHONY: all install
