FROM ruby:3.4

WORKDIR /

ENV VERBOSE=true

RUN apt-get update --fix-missing && apt-get install -y ca-certificates openssh-client curl gnupg build-essential

# Install Podman instead of Docker
RUN apt-get update && \
    apt-get install -y podman && \
    rm -rf /var/lib/apt/lists/*

# Copy test applications and setup scripts
COPY *.sh .
COPY app/ app/

# Setup SSH to use shared volume
RUN rm -rf /root/.ssh
RUN ln -s /shared/ssh /root/.ssh

# Setup git for test apps
RUN git config --global user.email "deployer@example.com"
RUN git config --global user.name "Deployer"
RUN cd app && git init && git add . && git commit -am "Initial version"

HEALTHCHECK --interval=1s CMD pgrep sleep

CMD ["./boot.sh"]
