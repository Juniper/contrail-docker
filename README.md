# contrail-docker
Effort on containerizing contrail applications

# Build containers

All container image building logic is inside Dockerfile in appropriate component
directory under docker directory (e.g docker/config/Dockerfile). Build stage handle
installing all packages and to make/run any common config/tasks.

