#!/bin/bash
# Trust config: only accept bronk images signed with one of our cosign keys.
# cosign.pub signs today's images; cosign-standby.pub is the next key, trusted
# ahead of time so a rotation needs no transition period (docs/signing.md).
# keyPaths is "any of these keys". Two separate sigstoreSigned entries would
# instead require BOTH signatures. The matching registries.d/bronk.yaml comes
# from system_files/ (10-files.sh).

set -ouex pipefail

if cmp -s /ctx/cosign.pub /ctx/cosign-standby.pub; then
    echo "cosign.pub and cosign-standby.pub are the same key; see docs/signing.md" >&2
    exit 1
fi
install -Dm644 /ctx/cosign.pub /etc/pki/containers/bronk.pub
install -Dm644 /ctx/cosign-standby.pub /etc/pki/containers/bronk-standby.pub
# Add our entry to ublue's policy.json instead of replacing the file, so their rules stay.
jq '.transports.docker["ghcr.io/ivanbalhawan/bronk"] = [{
      "type": "sigstoreSigned",
      "keyPaths": ["/etc/pki/containers/bronk.pub", "/etc/pki/containers/bronk-standby.pub"],
      "signedIdentity": {"type": "matchRepository"}
    }]' /etc/containers/policy.json > /tmp/policy.json
mv /tmp/policy.json /etc/containers/policy.json
chmod 644 /etc/containers/policy.json
# Fail the build if the entry is missing.
jq -e '.transports.docker["ghcr.io/ivanbalhawan/bronk"][0].keyPaths | length == 2' /etc/containers/policy.json
