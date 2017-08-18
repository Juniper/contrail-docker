# Simple Makefile to parallelize the "docker save | gzip" operations
# The kolla-* targets in docker/Makefile should migrate to this
# Makefile

ifndef TARFILE
    $(error TARFILE is undefined, set to tgz to build)
endif

SHELL:=/bin/bash
TEMPDIR:=$(shell mktemp -d $(PWD)/kolla-dockers-XXXX)
KOLLA_IMGS:=$(shell source venv/bin/activate && \
	kolla-build --list-images --base $(DISTRO) --config-file kolla-build.conf | grep -v ^INFO | sed -e 's/.* : //')

TARGETS=$(patsubst %,$(TEMPDIR)/ubuntu-binary-%.tar.gz,$(KOLLA_IMGS))

%.tar.gz:
	docker save $(shell docker images -q kolla/$(notdir $*)) | gzip > $@

$(TARFILE): $(TARGETS)
	@echo "docker images from kolla-build to be packaged:"
	@(cd $(TEMPDIR) && ls -l)
	(cd $(TEMPDIR) && tar -czf $(TARFILE) $(notdir $(TARGETS)))
	rm -rf $(TEMPDIR)
