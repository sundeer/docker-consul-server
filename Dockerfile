FROM alpine:3.3
MAINTAINER James Phillips <james@hashicorp.com> (@slackpad)

# This is the release of Consul to pull in.
ENV CONSUL_VERSION=0.6.3
ENV CONSUL_SHA256SUM=b0532c61fec4a4f6d130c893fd8954ec007a6ad93effbe283a39224ed237e250

# This is the release of https://github.com/hashicorp/docker-base to pull in order
# to provide HashiCorp-built versions of basic utilities like dumb-init and gosu.
ENV DOCKER_BASE_VERSION=0.0.4
ENV DOCKER_BASE_SHA256SUM=5262aa8379782d42f58afbda5af884b323ff0b08a042e7915eb1648891a8da00

# Create a consul user and group first so the IDs get set the same way, even as
# the rest of this may change over time.
RUN addgroup consul && \
    adduser -S -G consul consul

# Set up certificates, our base tools, and Consul.
RUN apk add --no-cache ca-certificates && \
    cd /tmp && \
    wget -O docker-base.zip https://releases.hashicorp.com/docker-base/${DOCKER_BASE_VERSION}/docker-base_${DOCKER_BASE_VERSION}_linux_amd64.zip && \
    echo "${DOCKER_BASE_SHA256SUM}  docker-base.zip" | sha256sum -c && \
    unzip -d / docker-base.zip && \
    rm docker-base.zip && \
    wget -O consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip && \
    echo "${CONSUL_SHA256SUM}  consul.zip" | sha256sum -c && \
    unzip -d /bin consul.zip && \
    rm consul.zip

# The /app/data dir is used by Consul to store state. The agent will be started
# with /app/config/local as the configuration directory so you can add additional
# config files in that location. There are client and server-specific locations so
# we can supply some default configs via this base image as well.
RUN mkdir -p /app/data && \
    mkdir -p /app/config/local && \
    mkdir -p /app/config/client && \
    mkdir -p /app/config/server && \
    chown -R consul:consul /app

# Expose the consul data directory as a volume since there's mutable state in there.
VOLUME /app/data

# Server RPC is used for communication between Consul clients and servers for internal
# request forwarding.
EXPOSE 8300

# Serf LAN and WAN (WAN is used only by Consul servers) are used for gossip between
# Consul agents. LAN is within the datacenter and WAN is between just the Consul
# servers in all datacenters.
EXPOSE 8301 8301/udp 8302 8302/udp

# CLI, HTTP, and DNS (both TCP and UDP) are the primary interfaces that applications
# use to interact with Consul.
EXPOSE 8400 8500 8600 8600/udp

# Consul doesn't need root privileges so we run it as the consul user from the
# entry point script. The entry point script also uses dumb-init as the top-level
# process to reap any zombie processes created by Consul sub-processes.
COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
