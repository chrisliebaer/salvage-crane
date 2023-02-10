# Basic Setup

TODO: more than just shell commands
```
docker volume create salvage-borg-data
docker volume create salvage-borg-ssh
docker run -it -v salvage-borg-data:/borg -v salvage-borg-ssh:/root/.ssh --entrypoint bash --rm ghcr.io/chrisliebaer/salvage-crane-borgbackup:master

# add host fingerprint to known_hosts by connecting once and checking connection
ssh user@host.tld
```