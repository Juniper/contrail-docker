# If SKU is not defined, default to mitaka
ifdef CONTRAIL_SKU
	export CONTRAIL_SKU
else
	export CONTRAIL_SKU := mitaka
endif

# Define all containers to be built
CONTAINERS = controller analytics adb

# CONTRAIL_VERSION is requisite so fail, if not provided
ifndef CONTRAIL_VERSION
$(error CONTRAIL_VERSION is undefined)
endif

CONTAINER_TARS = $(CONTAINERS:%=contrail-%-$(CONTRAIL_VERSION).tar.gz)

CONTRAIL_INSTALL_PACKAGE = contrail-install-packages_$(CONTRAIL_VERSION)~$(CONTRAIL_SKU)_all.deb

CONTRAIL_REPO_CONTAINER_TAR = contrail-apt-repo-$(CONTRAIL_VERSION).tar.gz

# This is the default target which should build all containers
.PHONY: build

build: $(CONTAINER_TARS)
	@echo "Building containers finished"

$(CONTAINER_TARS): $(CONTRAIL_REPO_CONTAINER_TAR)
	$(eval CONTAINER := $(subst -$(CONTRAIL_VERSION).tar.gz,:$(CONTRAIL_VERSION),$@))
	@echo "Building the container $(CONTAINER)"
	touch $@

$(CONTRAIL_REPO_CONTAINER_TAR): $(CONTRAIL_INSTALL_PACKAGE)
	@echo "Doing prebuild step"
	touch $@

$(CONTRAIL_INSTALL_PACKAGE):
	@echo "Making Contrail packages"
	@echo "Copying /cs-shared/packages/$(CONTRAIL_INSTALL_PACKAGE) to build directory"
	touch $@

.PHONY: clean

clean:
	@echo "Cleaning the workspace"
	rm -f $(CONTAINER_TARS) $(CONTRAIL_INSTALL_PACKAGE) $(CONTRAIL_REPO_CONTAINER_TAR)

.PHONY: save

save: $(CONTAINER_TARS)
ifdef CONTAINER_SAVE_LOCATION
		@echo "Saving container images $(CONTAINER_TARS) in $(CONTAINER_SAVE_LOCATION)"
else
		$(error CONTAINER_SAVE_LOCATION is undefined)
endif

.PHONY: push

push: $(CONTAINER_TARS)
ifdef CONTAINER_REGISTRY
		$(eval CONTAINERS := $(CONTAINER_TARS:%-$(CONTRAIL_VERSION).tar.gz=$(CONTAINER_REGISTRY)/%:$(CONTRAIL_VERSION)))
		@echo "Tagging container images to $(CONTAINERS)"
		@echo "Pushing container images $(CONTAINERS)"
else
		$(error CONTAINER_REGISTRY is undefined)
endif
