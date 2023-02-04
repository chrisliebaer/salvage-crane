FROM alpine
COPY binary.sh /bin/binary.sh

RUN apk add --no-cache bash \
	borgbackup \
	openssh \
	&& mkdir -m 700 /root/.ssh

ENTRYPOINT ["/bin/bash"]
CMD ["/bin/binary.sh"]
