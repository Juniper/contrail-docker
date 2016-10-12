# Contrail-docker image build process

## High level requirements and design proposals and decisions

* All the containers should be built as part of nightly build
* Build process should be as generic as possible to be used in in Juniper contrail build as well as public opencontrail
  build process
    * Actual container build process should assume to use publically available build mechanism/artifacts - e.g,
    contrail-install-packages tar/deb/rpm are only available in juniper contrail, so we should not use it.
* This should be completely self-contained with minimal assumptions
    * You may provide existing artifacts as input to the build process, but if they are not available, it
    should be able to create those artifacts from publically available sources. E.g Contrail packages or package
    repository may be provided, but if not found, it should be able to build them from the source.
* The build workflow should be implemented as make targets
* The end-to-end build workflow should be as much simple as possible in user perspective, so people (even public users)
 should be able to build contrail system from scratch without digging much into its technical implementations for both
 opencontrail as well juniper contrail.

## More into the implementation

* Complete workflow should be implemented as make targets without minimal external scripts.
* **package-build:** This step is mostly be an optional one and only run automatically if **contrail-repo** fail to
find out the packages or packages tar file. This will build the contrail specific packages from publically available
sources. The idea here is to make the entire build as easy as possible so that one should be able to build juniper
contrail/opencontrail containers with single (or may be couple of) make command[s].
* **prep:** This step is a preparation step for actual build process
    * **contrail-repo:** This step to build a contrail-repo container to be used by rest of the build process
        * Moved any juniper contrail specific requirements such as to use contrail-install-packages tar file to a "prep" target
        * Create a contrail-repo container[s] in the prep step, which will have all contrail specific packages for a version
          and it should be used by further build process to get the packages from instead of making each local package repos.
          This should help to make the build process generic to use it by public users for opencontrail build.
        * After creating the repo container, prep step should start that container in tbe build node so that it can be used as 
         local network repo for further container build process.
        * All contrail component container build process should use above mentioned container based repo to get the packages.
          This repo should have highest priority so that in case of conflicting packages between contrail-repo and other repos,
          packages should be selected from contrail-repo
        * This step have a dependency on package tar (or packages directory). In case it is not provided or dont have
          access to them, it should call a **package-build** step
    * **contrail-ansible:** This target will check for any existing artifact provided for contrail-ansible, and if not
     provided or not accessible, will create that artifact from git repo and reference provided. Here is the process
     of creating this artifact from git repo
        * Code will be pulled from provided git repo and checked out to provided reference - reference can be a commit
          id, a branch name, or tag. By default it consider master of https://github.com/juniper/contrail-ansible.git
        * It will run ansible-galaxy to pull all dependency ansible code which are mentioned in requirements.yml inside
          contrail-ansible. Note that It will help to recursively pull all dependency tree and not only the dependencies
          provided in the requirements.yml, but the complete dependency tree.
        * Then it will create a tar of it and name it after contrail-version (e.g contrail-ansible-3.1.1.0-29.tar.gz)
* **all**: This is the default target and this target will build all contrail container images and make it available
    to save it in a tar file or to push it to a docker registry. This is dependent on **prep** so if it did not find
    prep is not done already, it will run that step.
* **save**: This is to save the containers to specified archive location. This can either save already built containers
    and if it did not find any containers built, it will build them by calling container building targets which will
    intern call other targets like **prep** and all if required and then save it in the location provided
* **push**: This one is to push the containers to provided docker registry, it will act same way as **save**
* **clean**: This will cleanup the workspace by doing:
    * Remove contrail-repo container
    * Remove all temporary files and temporary artifacts created
    * Remove all container images created locally - this should be optional, one may choose to keep them locally, so
      further image build can be incremental to those images.


## Related repositories
https://github.com/Juniper/contrail-docker: This repository will have all container building and supporting code.

https://github.com/Juniper/contrail-ansible: This repo will have all ansible code to support build, configure and
orchestrate the containers built and overall system setup.

Note that there could be bunch of repositories to be added here which are related to package build, which are TBD.
