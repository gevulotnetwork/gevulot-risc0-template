# Gevulot RISC Zero Rust Starter Template

This repository is an example on how generate RISC0 proofs on Gevulot Network.
It consists of project created by `cargo risczero new` with added
`Containerfile` and these instructions.

Below you will find all steps needed to compose & deploy a task for this program
onto Gevulot Network.

## 1. `gvltctl`

`gvltctl` (Gevulot Control) is a tool used to do all the job related to Gevulot
Network including building and pinning images, creating tasks etc.

### Install

```sh
cargo install --git https://github.com/gevulotnetwork/gvltctl
```

To use `gvltctl build` command you will need some extra binary dependencies:

- [`podman`](https://podman.io/)
- [`skopeo`](https://github.com/containers/skopeo)
- [`extlinux`](https://wiki.syslinux.org/wiki/index.php?title=EXTLINUX)
- [`gcc`](https://gcc.gnu.org/)

You can probably install them from your native package manager. Ubuntu example:

```sh
apt-get install podman skopeo extlinux gcc
```

### Verify installation

```sh
gvltctl --version
```

## 2. Container for your program

Gevulot Network operates on Linux VM images. To run your workload you need to
pack it into bootable disk image. There are different ways how you can do it,
but the recommended (and hopefully the simplest one) is to use `gvltctl build`.

`gvltctl build` command builds Gevulot-compatible VM image from container.
Thus to use it, you will need to wrap your program into container.

In this repository there is an example of Containerfile for RISC0 template.
It exposes proof generator with CUDA support as entrypoint. You can try it out:

(You will need [NVIDIA container runtime](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html))

```sh
podman build -t my_image . && podman run --device nvidia.com/gpu=all my_image
```

> **_NOTE:_** It's always nice to get as small image size as possible. That's
> the purpose of `stage 3` in `Containerfile` - we will get only 300MB image
> from it.

## 3. Build VM image

```sh
gvltctl build -f Containerfile -s 700M --nvidia-drivers
```

This will produce `disk.img` file, which is a self-contained bootable VM image.

> **_NOTE:_** This will build latest Linux kernel from sources. It may take some
> time dependings on your resources.

Check out `gvltctl build --help` for more options.

> **_NOTE:_** Right now the final size of the image is defined manually using
> `-s`/`--size` option. Thus if you are getting any write errors when building,
> try increasing the size.

Kernel and other stuff usually takes around 250MB - so just add up it to your
container size. With NVIDIA drivers it takes around 400MB.

## 3.1 (Optional) Run VM locally

Running this VM locally may be tricky, because you will need to passthrough your
GPU to QEMU.

```sh
qemu-system-x86_64 \
  -machine q35 \
  -enable-kvm \
  -m 1G \
  -nographic \
  -device vfio-pci,rombar=0,host=0000:01:00.0 \
  --hda disk.img
```

## 4. Pin VM image

TODO

## 5. Create task

TODO
