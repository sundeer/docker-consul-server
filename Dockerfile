FROM gliderlabs/consul-agent:0.6

COPY entry.sh /entry.sh

ENTRYPOINT ["/entry.sh"]
