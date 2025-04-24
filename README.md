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

Follow [installation instructions](https://github.com/gevulotnetwork/gvltctl?tab=readme-ov-file#installation)
of `gvltctl` tool. Pay attention to "Runtime dependencies" section.

### Verify installation

```sh
gvltctl --version
```

> **_NOTE:_** This manual is written for `gvltctl 0.2.1`.

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
podman build -t risc0-template . && podman run --device nvidia.com/gpu=all risc0-template:latest
```

> **_NOTE:_** It's always nice to get as small image size as possible. That's
> the purpose of `stage 3` in `Containerfile` - we will get only 437MB image
> from it.

## 3. Build VM image

```sh
gvltctl build -c risc0-template:latest -o risc0-template.img --nvidia-drivers
```

This will produce `risc0-template.img` file, which is a self-contained bootable VM image.
Option `--nvidia-drivers` includes NVIDIA drivers into VM image. Since this Containerfile
builds RISC0 with CUDA enabled, this option is required.

> **_NOTE:_** This will build latest Linux kernel from sources. It may take some
> time dependings on your resources.

Check out `gvltctl build --help` for more options.

## 4. Task specification

To specify a task you can use YAML files. This repository contains example task
specification in `task.yaml`. In this file you will specify resources needed for
your task alongside with some additional metadata.

For more info see [Tasks documentation](https://docs.gevulot.com/gevulot-docs/firestarter/run-workloads/tasks).

## 4.1 (Optional) Run VM locally

You can run your VM locally using `gvltctl local-run` command. You will need
[QEMU](https://www.qemu.org/) installed for this. However this may be a bit tricky,
because in order to run this image you will need to [passthrough your GPU](https://documentation.ubuntu.com/server/how-to/graphics/gpu-virtualization-with-qemu-kvm/).
Here some tools like [driverctl](https://gitlab.com/driverctl/driverctl) may help you.
But keep in mind that you will need a second GPU (e.g. CPU-integrated), because you
will be detaching the GPU from host system. If you succeeded with that and have GPU
available at address `0000:01:00.0`, you can run your image:

```sh
gvltctl local-run -f task.yaml --gpu 0000:01:00.0 risc0-template.img
```

> **_NOTE:_** This Containerfile produces build for NVIDIA Compute Capability 8.9, which
> corresponds to NVIDIA GeForce RTX 4090 cards installed on Firestarter worker nodes.
> If you have a different model of NVIDIA GPU, you need to change that compilation
> flags to match your architecture. See [NVIDIA docs](https://developer.nvidia.com/cuda-gpus).

Any CLI options provided to `gvltctl local-run` will override parameters in
`task.yaml`. E.g. you can provide more CPU cores and memory to the VM and enable stdout
printing:

```sh
gvltctl local-run -f task.yaml -s 32 -m 32000 --stdout risc0-template.img
```

Your output will be stored in `output/` directory:

```sh
ls output/
```

Now let's run our image on the real network.

## 5. Create an account and purchase tokens

See [Get Started](https://docs.gevulot.com/gevulot-docs/firestarter/get-started)
section to learn how to create an account and purchase tokens.

## 6. Upload VM image

Gevulot workers will download your VM image from any public HTTP(S) URL.
You can use any storage you want. Upload created `risc0-template.img` and get its URL.

E.g. if you used Google Cloud, you will get a public URL like this:

```plaintext
https://storage.googleapis.com/gevulot-static-assets/risc0-template.img
```

Put your URL into `task.yaml` file replacing `<YOUR IMAGE URL>`.

## 7. Create task

Now you are ready to upload your task to the network.

```sh
gvltctl task create \
    --endpoint https://grpc.firestarter.gevulot.com \
    --mnemonic YOUR_MNEMONIC \
    --file task.yaml
```

If the task was successfully created, this will print your task ID, which you
can use to track the status of your task.

```sh
gvltctl task get \
    --endpoint https://grpc.firestarter.gevulot.com \
    TASK_ID
```

> **_NOTE:_** Instead of specifying endpoint and mnemonic for every command
> you can export them as environment variables `GEVULOT_ENDPOINT` and
> `GEVULOT_MNEMONIC`.

When the state of your task becomes `Done`, you can collect your outputs. Outputs are stored on
Firestarter IPFS network and can be fetched from its gateway:

```sh
curl https://ipfs.firestarter.gevulot.com/download/YOUR_OUTPUT_CID
```

Visit [Firestarter documentation](https://docs.gevulot.com/gevulot-docs/firestarter)
for more information.
