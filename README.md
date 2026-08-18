# EXP Mint

EXP Mint is an x86_64 Linux Mint 22.3 XFCE remix designed for older laptops, with the Dell Latitude E5410 as its reference machine.

It keeps the standard Linux Mint installer and repositories while adding:

- an original EXP Mint wallpaper and visual identity;
- matching Plymouth and GRUB themes;
- legacy BIOS and UEFI boot support;
- conservative Intel graphics defaults;
- XFCE compositing disabled by default for lower GPU/RAM use;
- a reproducible GitHub Actions ISO build.

## Build in GitHub Actions

Open **Actions → Build EXP Mint ISO → Run workflow**. The completed workflow publishes:

- `exp-mint-22.3-xfce-amd64.iso`
- `exp-mint-22.3-xfce-amd64.iso.sha256`

as a workflow artifact. Tagged builds also attach both files to a GitHub release.

## Build locally

Use an Ubuntu 24.04 x86_64 machine with at least 15 GB free disk space:

```bash
sudo apt-get update
sudo apt-get install -y curl xorriso squashfs-tools rsync imagemagick grub-pc-bin grub-efi-amd64-bin isolinux syslinux-common mtools
sudo ./scripts/build-iso.sh
```

The output is written to `dist/`.

## E5410 notes

- Use the regular (non-HWE) base selected by the workflow.
- The ISO supports the laptop's legacy BIOS boot path.
- If the machine has only 2 GB RAM, install first and avoid running many live-session apps at once.
- Write the ISO in raw/DD mode. In Linux: `sudo dd if=exp-mint-22.3-xfce-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync`.

EXP Mint is an unofficial community remix and is not affiliated with the Linux Mint project.
