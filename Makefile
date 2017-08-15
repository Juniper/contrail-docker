## Variables accepted
#
# KEEP_IMAGES - to avoid cleaning up container images locally
#
##

# If SKU is not defined, default to mitaka
ifndef CONTRAIL_SKU
	export CONTRAIL_SKU := mitaka
endif

ifndef CONTRAIL_REPO_IP
	export CONTRAIL_REPO_IP := $(shell ip a l docker0 | awk '/inet / {print $$2}' | cut -f1 -d'/')
endif

export SSHUSER ?= root

# Kolla Repo Path
ifndef KOLLA_DIR
	export KOLLA_DIR := $(PWD)/../kolla/
endif

ifdef docker_http_proxy
	export http_proxy_build_arg :=  --build-arg http_proxy=$(docker_http_proxy) --build-arg https_proxy=$(docker_http_proxy) --build-arg no_proxy=$(CONTRAIL_REPO_IP)
else
	export http_proxy_build_arg :=
endif

ifdef CONTRAIL_REPO_MIRROR_SNAPSHOT
	export repo_snapshot_build_arg := --build-arg CONTRAIL_REPO_MIRROR_SNAPSHOT=$(CONTRAIL_REPO_MIRROR_SNAPSHOT)
endif

# OS - operaing system release code
# ubuntu 14.04 - ubuntu14.04, ubuntu 16.04 - ubuntu16.04, centos 7.x - centos7
ifndef OS
$(warning OS is undefined, default to u14.04)
	export OS := ubuntu14.04
endif


# CONTRAIL_VERSION is requisite so fail, if not provided
ifndef CONTRAIL_VERSION
$(error CONTRAIL_VERSION is undefined)
endif

CONTRAIL_INSTALL_PACKAGE_TAR = contrail-install-packages_$(CONTRAIL_VERSION)-$(CONTRAIL_SKU).tgz
CONTRAIL_BASE_TAR = contrail-base-$(OS)-$(CONTRAIL_VERSION).tar.gz
CONTRAIL_REPO_INTERNAL_PORT=1567

ifndef CONTRAIL_REPO_PORT
	export CONTRAIL_REPO_PORT := 1567
endif

ifndef CONTRAIL_REPO_URL
	export CONTRAIL_REPO_URL := http://$(CONTRAIL_REPO_IP):$(CONTRAIL_REPO_PORT)
endif

ifndef CONTRAIL_REPO_CONTAINER
	export CONTRAIL_REPO_CONTAINER = contrail-repo-$(OS)
	export CONTRAIL_REPO_CONTAINER_TAR = $(CONTRAIL_REPO_CONTAINER)-$(CONTRAIL_VERSION).tar.gz
endif

ifneq (,$(filter ubuntu14.04 ubuntu16.04,$(OS)))
	export DISTRO = ubuntu
ifndef CONTAINERS
	export CONTAINERS = controller analytics agent analyticsdb lb kube-manager mesos-manager ceph-controller kubernetes-agent
endif
endif

ifneq (,$(filter centos7,$(OS)))
	export DISTRO = centos
ifndef CONTAINERS
	export CONTAINERS = controller analytics agent analyticsdb lb vrouter-compiler
endif
endif

ifneq (,$(filter redhat7,$(OS)))
ifndef CONTAINERS
	export CONTAINERS = controller analytics agent analyticsdb lb
endif
endif

CONTAINER_TARS = $(CONTAINERS:%=contrail-%-$(OS)-$(CONTRAIL_VERSION).tar.gz)

CONTRAIL_ANSIBLE_TAR = contrail-ansible-internal-$(CONTRAIL_VERSION).tar.gz
CONTRAIL_ANSIBLE_REPO = "git@github.com:Juniper/contrail-ansible-internal.git"
CONTRAIL_ANSIBLE_REF = "master"
CONTRAIL_ANSIBLE = contrail-ansible-internal

# This is the default target which should build all containers
.PHONY: all

all: $(CONTAINER_TARS)

contrail-%: contrail-%-$(OS)-$(CONTRAIL_VERSION).tar.gz
	@touch $@

kolla-prep:
	@echo "Preparing Kolla build env"
	cp -a kolla-patches/. $(KOLLA_DIR)

kolla-ubuntu-patches: SHELL:=/bin/bash
kolla-ubuntu-prep: kolla-prep
	@echo "Applying Ubuntu replated Kolla patches"
	echo "deb [arch=amd64] $(CONTRAIL_REPO_URL) ./" > $(KOLLA_DIR)/contrail.list
	# Due to LP #1706549; Remove once fixed
	grep "deb \[arch=amd64\] http:\/\/$(CONTRAIL_REPO_IP):$(CONTRAIL_REPO_PORT) .\/" $(KOLLA_DIR)docker/base/sources.list.ubuntu || \
	  sed -i '1 i\deb [arch=amd64] $(CONTRAIL_REPO_URL) ./' $(KOLLA_DIR)docker/base/sources.list.ubuntu
	cp -af $(KOLLA_DIR)/99contrail $(KOLLA_DIR)/docker/openstack-base/99contrail

kolla-centos-prep: kolla-prep
	@echo "Applying Centos related Kolla patches"
	echo -e "[contrail-repo]\nname = contrail-repo\nbaseurl = $(CONTRAIL_REPO_URL)\nenabled = 1\ngpgcheck = 0\n" > $(KOLLA_DIR)/docker/base/contrail.repo ;\

kolla-patches: kolla-$(DISTRO)-prep
	cp -af $(KOLLA_DIR)../../controller/src/vnsw/agent/port_ipc/vrouter-port-control \
	       $(KOLLA_DIR)/docker/nova/nova-compute/vrouter-port-control

kolla: SHELL:=/bin/bash
kolla: prep kolla-prep kolla-$(DISTRO)-prep kolla-patches
	@echo "Building Kolla Docker containers at $(KOLLA_DIR)"
	cd $(KOLLA_DIR) && \
	    python setup.py install && \
	    kolla-build --config-file kolla-build.conf \
	                --tag $(CONTRAIL_VERSION) \
	                -b $(DISTRO) \
	                --template-override template-overrides.j2

kolla-archive: SHELL:=/bin/bash
kolla-archive: kolla
	@echo "Bundle generated openstack containers"
	source $(PWD)/make_utils.sh && \
	create_kolla_container_tar \
	    "contrail_version=$(CONTRAIL_VERSION);tar_name=$(PWD)/openstack-docker-images_$(CONTRAIL_VERSION)_$(DISTRO).tgz"

kolla-clean: SHELL:=/bin/bash
kolla-clean:
	@echo "Local changes at $(KOLLA_DIR) will removed"
	@echo "Restore $(KOLLA_DIR)"
	(cd $(KOLLA_DIR) && git clean -fd)
	(cd $(KOLLA_DIR) && git stash)
	@echo "Remove all kolla docker containers..."
	docker images |grep kolla | grep $(CONTRAIL_VERSION) | awk '{print $3}' | xargs docker rmi -f || \
	    echo "NO DOCKER IMAGES TO CLEAN. Skipping..."

kolla-build: kolla-archive kolla-clean

$(CONTAINER_TARS): prep contrail-base
	$(eval TEMP := $(shell mktemp -d))
	$(eval CONTAINER := $(subst -$(CONTRAIL_VERSION).tar.gz,,$@))
	$(eval CONTAINER_NAME := $(subst contrail-,,$(subst -$(OS)-$(CONTRAIL_VERSION).tar.gz,,$@)))
	@echo "Building the container $(CONTAINER):$(CONTRAIL_VERSION)"
	cp -rf  docker/pyj2.py docker/$(CONTAINER_NAME)/* $(TEMP)
	if [ -d $(TEMP)/$(OS) ]; then \
		cp -rf $(TEMP)/$(OS)/* $(TEMP)/; \
	fi
	cd $(TEMP); \
	if [ -f Dockerfile.j2 ]; then \
	    python pyj2.py -t Dockerfile.j2 -o Dockerfile -v contrail_version=$(CONTRAIL_VERSION); \
	fi; \
	docker build  -t $(CONTAINER):$(CONTRAIL_VERSION) .

ifndef NO_CACHE
	docker save $(CONTAINER):$(CONTRAIL_VERSION) | gzip -c > $@
endif
	rm -fr $(TEMP)

prep: contrail-repo ansible-internal
	@touch prep

contrail-base: $(CONTRAIL_BASE_TAR)
	@touch contrail-base

ansible-internal: $(CONTRAIL_ANSIBLE_TAR)
	@touch ansible-internal

contrail-repo:  $(CONTRAIL_REPO_CONTAINER_TAR)
	@touch contrail-repo

$(CONTRAIL_BASE_TAR): ansible-internal contrail-repo
	$(eval CONTRAIL_BUILD_ARGS := )
	$(eval CONTRAIL_BUILD_ARGS +=  --build-arg CONTRAIL_ANSIBLE_TAR=$(CONTRAIL_ANSIBLE_TAR) )
	$(eval CONTRAIL_BUILD_ARGS +=  --build-arg CONTRAIL_VERSION=$(CONTRAIL_VERSION) )
	$(eval CONTRAIL_BUILD_ARGS +=  --build-arg OS=$(OS) )
	$(eval CONTRAIL_BUILD_ARGS += $(http_proxy_build_arg))
	$(eval CONTRAIL_BUILD_ARGS += $(repo_snapshot_build_arg))
	$(eval TEMP := $(shell mktemp -d))
	@echo "Building the container contrail-base:$(CONTRAIL_VERSION)"
	cp -rf tools/python-contrailctl $(CONTRAIL_ANSIBLE_TAR) docker/*.sh docker/*.py docker/*.key docker/contrail-base/* $(TEMP)
	if [ -d $(TEMP)/$(OS) ]; then \
		cp -rf $(TEMP)/$(OS)/* $(TEMP)/; \
	fi
	cd $(TEMP); \
	docker build $(CONTRAIL_BUILD_ARGS) --build-arg CONTRAIL_REPO_URL=$(CONTRAIL_REPO_URL)  -t contrail-base-$(OS):$(CONTRAIL_VERSION) .
	rm -fr $(TEMP)
	@touch $@

$(CONTRAIL_ANSIBLE_TAR):
ifdef CONTRAIL_ANSIBLE_ARTIFACT
	if [ -f $(CONTRAIL_ANSIBLE_ARTIFACT) ]; then  \
		cp -f $(CONTRAIL_ANSIBLE_ARTIFACT) $(CONTRAIL_ANSIBLE_TAR) ;\
	else \
		@echo "ERROR: ansible artifact not found: $(CONTRAIL_ANSIBLE_ARTIFACT)" ; \
		@exit 1; \
	fi
else
	$(eval BUILD_CONTRAIL_ANSIBLE_TAR := yes)
endif

	if [ -n "$(BUILD_CONTRAIL_ANSIBLE_TAR)" ]; then \
		echo "Building from repo $(CONTRAIL_ANSIBLE_REPO) ref: $(CONTRAIL_ANSIBLE_REF)"; \
		git clone $(CONTRAIL_ANSIBLE_REPO) $(CONTRAIL_ANSIBLE) ;\
		cd $(CONTRAIL_ANSIBLE) ;\
		git checkout $(CONTRAIL_ANSIBLE_REF) ;\
		git reset --hard; \
		rm -fr .git* ;\
		cd .. ; \
		echo "Saving to $(CONTRAIL_ANSIBLE_TAR)";\
		tar zcf $(CONTRAIL_ANSIBLE_TAR) $(CONTRAIL_ANSIBLE); \
		rm -fr $(CONTRAIL_ANSIBLE);\
	fi

$(CONTRAIL_REPO_CONTAINER_TAR): $(CONTRAIL_INSTALL_PACKAGE)
ifndef CONTRAIL_INSTALL_PACKAGE_TAR_URL
	$(error CONTRAIL_INSTALL_PACKAGE_TAR_URL is undefined)
endif

	$(eval CONTRAIL_REPO_BUILD_ARGS := --build-arg CONTRAIL_INSTALL_PACKAGE_TAR_URL=$(CONTRAIL_INSTALL_PACKAGE_TAR_URL))
	$(eval CONTRAIL_REPO_BUILD_ARGS +=  $(http_proxy_build_arg))
	$(eval CONTRAIL_REPO_BUILD_ARGS +=  --build-arg CONTRAIL_VERSION=$(CONTRAIL_VERSION) )
	$(eval CONTRAIL_REPO_BUILD_ARGS +=  --build-arg CONTRAIL_REPO_PORT=$(CONTRAIL_REPO_PORT) )
	$(eval CONTRAIL_REPO_BUILD_ARGS +=  --build-arg OS=$(OS) )

ifdef SSHPASS
	$(eval CONTRAIL_REPO_BUILD_ARGS += --build-arg SSHPASS=$(SSHPASS) )
endif

ifdef SSHUSER
	$(eval CONTRAIL_REPO_BUILD_ARGS += --build-arg SSHUSER=$(SSHUSER))
endif
	$(eval TEMP := $(shell mktemp -d))
	@echo "Building the container $(CONTRAIL_REPO_CONTAINER):$(CONTRAIL_VERSION)"
	@echo "Temp Dir == $(TEMP)"
	cp -rf docker/*.sh docker/*.key docker/contrail-repo/* $(TEMP)
	if [ -d $(TEMP)/$(OS) ]; then \
		cp -rf $(TEMP)/$(OS)/* $(TEMP)/; \
	fi
	# Create a repo in build machine and copy it to repo docker container
	@echo "OS == $(OS)"
	mkdir -p $(TEMP)/contrail_install_repo
	$(eval REPO_TEMP_DIR := $(TEMP)/contrail_install_repo)
	if [ "$(OS)" = "centos7" ]; then \
	    source ./create_repo.sh ; \
	    create_pkg_repo package_urls=$(CONTRAIL_INSTALL_PACKAGE_TAR_URL) \
	                    repo_dir=$(REPO_TEMP_DIR) \
	                    sshuser=$(SSHUSER) \
	                    sshpass=$(SSHPASS); \
	fi
	$(eval CONTRAIL_REPO_BUILD_ARGS += --build-arg CONTRAIL_REPO_DIR=contrail_install_repo)
	cd $(TEMP); \
	docker build $(CONTRAIL_REPO_BUILD_ARGS) \
		-t $(CONTRAIL_REPO_CONTAINER):$(CONTRAIL_VERSION) .
	@echo "Starting contrail repo container"
	docker run -d -p $(CONTRAIL_REPO_PORT):$(CONTRAIL_REPO_INTERNAL_PORT) --name $(CONTRAIL_REPO_CONTAINER)_$(CONTRAIL_REPO_PORT) $(CONTRAIL_REPO_CONTAINER):$(CONTRAIL_VERSION)
	@echo "Saving the container $(CONTRAIL_REPO_CONTAINER):$(CONTRAIL_VERSION)"
	docker save $(CONTRAIL_REPO_CONTAINER):$(CONTRAIL_VERSION) | gzip -c > $@

$(CONTRAIL_INSTALL_PACKAGE):
	@echo "Making Contrail packages"
	@echo "Copying /cs-shared/packages/$(CONTRAIL_INSTALL_PACKAGE) to build directory"
	touch $@

.PHONY: clean

clean:
	@echo "Cleaning the workspace"
	docker rm -f $(CONTRAIL_REPO_CONTAINER)_$(CONTRAIL_REPO_PORT) || true
ifndef KEEP_IMAGES
	$(foreach i,$(CONTAINERS) repo, \
		docker rmi -f $(CONTAINER_REGISTRY)/contrail-$(i)-$(OS):$(CONTRAIL_VERSION) || true;\
		docker rmi -f contrail-$(i)-$(OS):$(CONTRAIL_VERSION) || true;)
	docker rmi -f contrail-base-$(OS):$(CONTRAIL_VERSION) || true
endif
	rm -f $(CONTAINER_TARS) $(CONTRAIL_INSTALL_PACKAGE) $(CONTRAIL_REPO_CONTAINER_TAR) $(CONTRAIL_ANSIBLE_TAR) prep contrail-repo ansible-internal contrail-base $(CONTRAIL_BASE_TAR)

.PHONY: save

save: $(CONTRAIL_REPO_CONTAINER_TAR) $(CONTAINER_TARS)
ifndef CONTAINER_SAVE_LOCATION
	$(error CONTAINER_SAVE_LOCATION is undefined)
endif
	@echo "Saving container images in $(CONTAINER_SAVE_LOCATION)"
	install --mode 0644 -t $(CONTAINER_SAVE_LOCATION) $(CONTRAIL_REPO_CONTAINER_TAR) $(CONTAINER_TARS)

.PHONY: push

push: $(CONTRAIL_REPO_CONTAINER_TAR) $(CONTAINER_TARS)
ifdef CONTAINER_REGISTRY
		@for i in repo $(CONTAINERS); do\
			CONTAINER_NAME=contrail-$$i;\
			CONTAINER_TAG=$$(docker images | grep "^$$CONTAINER_NAME-$$OS " | awk '{print $$3}');\
			CONTAINER_REG_NAME=$$CONTAINER_REGISTRY/$$CONTAINER_NAME-$$OS:$$CONTRAIL_VERSION;\
			echo "Tagging container: docker tag $$CONTAINER_TAG $$CONTAINER_REG_NAME";\
			docker tag $$CONTAINER_TAG $$CONTAINER_REG_NAME;\
			echo "Pushing container: docker push $$CONTAINER_REG_NAME";\
			docker push $$CONTAINER_REG_NAME;\
		done
else
		$(error CONTAINER_REGISTRY is undefined)
endif
