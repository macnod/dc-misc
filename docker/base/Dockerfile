
#
# Donnie's Base Dockerfile
#

# Pull base image
FROM ubuntu:15.10

# Update system and install necessary software
RUN apt-get update --fix-missing && apt-get dist-upgrade -yq --fix-missing
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --fix-missing \
    emacs24-nox ssh git git-doc man man-db inetutils-ping ack-grep curl \
    wget sudo screen build-essential 
RUN locale-gen en_US en_US.UTF-8

# Add user 'ubuntu'
RUN addgroup admin
RUN adduser --disabled-password --gecos "" ubuntu
RUN adduser ubuntu admin
RUN echo "ubuntu:eagle" | chpasswd
USER ubuntu
ADD .screenrc /home/ubuntu/.screenrc

# Get code
USER ubuntu
RUN touch /home/ubuntu/.ssh/known_hosts
RUN ssh-keyscan github.com >> /home/ubuntu/.ssh/known_hosts
RUN git config --global user.email "macnod@gmail.com"
RUN git config --global user.name "Donnie Cameron"
RUN git config --global push.default simple
RUN git config --global pull.rebase true

# Configure startup
ADD start.sh /start.sh

# Container ports
EXPOSE 22

# Default command
CMD ["/start.sh"]
