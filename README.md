# EXP Mint

EXP Mint is an x86_64 Linux Mint 22.3 remix with **XFCE, MATE, and Cinnamon** editions. XFCE is recommended for the Dell Latitude E5410 and other older laptops.

It adds an original wallpaper, animated Plymouth branding, matching GRUB and legacy boot artwork, a custom Calamares installer, and automated GitHub Actions builds.

## Download

GitHub Actions publishes one ZIP artifact per desktop:

- `exp-mint-22.3-xfce-amd64.zip`
- `exp-mint-22.3-mate-amd64.zip`
- `exp-mint-22.3-cinnamon-amd64.zip`

Each artifact ZIP contains the ISO and SHA-256 checksum. The download site points to the newest successful artifacts from the `main` branch.

## Build in GitHub Actions

Open **Actions → Build EXP Mint editions → Run workflow**. All three editions build independently and appear as separate workflow artifacts.

## Build one edition locally

On Ubuntu 24.04 x86_64 with at least 15 GB free:

```bash
sudo apt-get update
sudo apt-get install -y curl xorriso squashfs-tools rsync imagemagick librsvg2-bin grub-pc-bin grub-efi-amd64-bin isolinux syslinux-common mtools zip
sudo MINT_EDITION=xfce ./scripts/build-iso.sh
```

Use `mate` or `cinnamon` for the other editions. Output is written to `dist/`.

## Dell Latitude E5410

Use XFCE for the lowest resource use. The ISO supports legacy BIOS and UEFI boot. Test Wi-Fi, audio, graphics, and sleep in the live session before installing, and write the ISO in raw/DD mode.

EXP Mint is an unofficial community remix and is not affiliated with the Linux Mint project.
