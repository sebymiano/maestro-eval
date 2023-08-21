FROM --platform=linux/amd64 ubuntu:jammy

# https://stackoverflow.com/questions/51023312/docker-having-issues-installing-apt-utils
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Lisbon

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# The install scripts require sudo (no need to clean apt cache, the setup script will install stuff)
RUN apt-get update && apt-get install -y sudo

# Create a user with passwordless sudo
RUN adduser --disabled-password --gecos '' docker
RUN adduser docker sudo
RUN echo '%docker ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER docker
WORKDIR /home/docker/

# Configure ssh directory
RUN mkdir /home/docker/.ssh
RUN chown -R docker:docker /home/docker/.ssh

# Install some nice to have applications
RUN sudo apt-get update --fix-missing

###########################
#  Building dependencies  #
###########################

COPY --chown=docker:docker . maestro-eval
WORKDIR /home/docker/maestro-eval

RUN setup/setup-dut.sh

# Run bash on open
SHELL ["/bin/bash", "-c"]
CMD [ "/bin/bash" ]