# Image signing keys

CI signs every image with cosign. Machines only accept bronk images signed by
one of the two public keys baked into the image:

| Key | Public key (in repo) | Private key lives in |
| --- | --- | --- |
| Active: signs every build | `cosign.pub` | GitHub secret `SIGNING_SECRET` + password manager |
| Standby: the next active key | `cosign-standby.pub` | Password manager **only**, never on GitHub |

Both public keys end up in `/etc/pki/containers/` and in one `sigstoreSigned`
entry in `/etc/containers/policy.json` via `keyPaths` (see
`build_files/build.sh`). `keyPaths` means "signed by any of these keys". Don't
split it into two entries: the entries are ANDed, so every image would need
both signatures.

Because every machine already trusts the standby key, switching to it needs no
transition period and no manual steps on machines.

## Backup

Keep both private keys as file attachments in the password manager, one entry
each, named after their role ("bronk cosign key: active" and "bronk cosign
key: standby"). That's the only backup. GitHub secrets can't be read back.

The keys have no cosign password; the password manager is the encryption.
Don't leave private keys lying around on disk after a rotation. `*.key` is
gitignored, but delete them anyway.

## When to rotate

Only when the active key leaks, or might have leaked. No fixed schedule.

If the private key is only lost (you can't find the password manager copy),
nothing is broken: CI still signs with the GitHub secret. Rotate anyway when
convenient, so you have a backup again.

## Rotate: promote the standby key

1. Save the standby private key from the password manager as
   `cosign-standby.key` in the repo root.
2. On a branch off `main`:

   ```bash
   just rotate-key
   ```

   This checks that the key matches `cosign-standby.pub`, sets
   `SIGNING_SECRET` to it with `gh`, deletes the local copy, renames
   `cosign-standby.pub` to `cosign.pub`, generates a new standby pair and
   commits.
3. In the password manager: rename the standby entry to "active", delete the
   old active entry, and save the new `cosign-standby.key` as the new standby.
   Then `rm cosign-standby.key`.
4. Open a PR and merge it.
5. Rebuild and replace any installer ISOs you keep around. They only trust the
   keys that were current when they were built.

From the moment `SIGNING_SECRET` changes, CI signs with the new key, which
machines already trust. The merged image stops trusting the old key.

**Leaked key:** someone holding the old key can sign images your machines
accept until each machine installs the rotated image. Trigger a build right
after merging and update the machines (`rpm-ostree upgrade`) instead of waiting
for the weekly run.

## Replace only the standby key

If the standby private key leaks or gets lost:

```bash
just replace-standby-key
```

Save the new `cosign-standby.key` in the password manager in place of the old
standby, `rm cosign-standby.key`, then open a PR and merge it.

## Both keys gone or leaked

Machines can't be moved to a new key through an update. Make a new key pair
for both roles (`cosign generate-key-pair`, then
`just replace-standby-key`), set `SIGNING_SECRET`, merge, and re-trust each
machine by hand using the same two-step rebase as a first install (see
[README](../README.md#using-it)).

## Machines that missed updates

A machine that missed two rotations trusts neither current key and refuses
updates. Recover it with the same two-step rebase.
