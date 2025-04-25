# Gevulot RISC Zero Rust Starter Template

This repository is an example on how to generate RISC0 proofs on ZkCloud Firestarter network (prev. Gevulot Firestarter).
It consists of a project created by `cargo risczero new` with added
`Containerfile` and these instructions.

Below you will find all the steps needed to compose & deploy a task for this program
onto the ZkCloud Firestarter network.

## 1. `gvltctl`

`gvltctl` (Gevulot Control) is a tool used to do all the jobs related to the
network, including building and pinning images, creating tasks, etc.

### Install

Follow [installation instructions](https://github.com/gevulotnetwork/gvltctl?tab=readme-ov-file#installation)
of the `gvltctl` tool. Pay attention to the "Runtime dependencies" section.

### Verify installation

```sh
gvltctl --version
```

> **_NOTE:_** This manual is written for `gvltctl 0.2.1`.

## 2. Container for your program

ZkCloud Firestarter network operates on Linux VM images. To run your workload, you need to
pack it into a bootable disk image. There are different ways you can do it,
but the recommended (and probably the simplest one) is to use `gvltctl build`.

The `gvltctl build` command builds a ZkCloud-compatible VM image from a container.
Thus, to use it, you will need to wrap your program into a container.

In this repository, there is an example of a Containerfile for RISC0 template.
It exposes a proof generator with CUDA support as entry point. You can try it out:

(You will need [NVIDIA container runtime](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html))

```sh
podman build -t risc0-template . && podman run --device nvidia.com/gpu=all risc0-template:latest
```

> **_NOTE:_** It's always nice to get as small an image size as possible. That's
> the purpose of `stage 3` in `Containerfile` - we will get only 437MB image
> from it.

## 3. Build VM image

```sh
gvltctl build -c risc0-template:latest -o risc0-template.img --nvidia-drivers
```

This will produce the `risc0-template.img` file, which is a self-contained bootable VM image.
Option `--nvidia-drivers` includes NVIDIA drivers in the VM image. Since this Containerfile
builds RISC0 with CUDA enabled, this option is a requirement.

> **_NOTE:_** This will build the latest Linux kernel from sources. It may take some
> time depending on your resources.

Check out `gvltctl build --help` for more options.

## 4. Task specification

To specify a task, you can use YAML files. This repository contains an example task
specification in `task.yaml`. In this file, you will specify resources to be allocated to
your task alongside additional metadata.

For more info, see [Tasks documentation](https://docs.gevulot.com/gevulot-docs/firestarter/run-workloads/tasks).

## 4.1 (Optional) Run VM locally

You can run your VM locally using the `gvltctl local-run` command. You will need
[QEMU](https://www.qemu.org/) installed for this. However, to run this image locally, you will need to [passthrough your GPU](https://documentation.ubuntu.com/server/how-to/graphics/gpu-virtualization-with-qemu-kvm/).
Here, some tools like [driverctl](https://gitlab.com/driverctl/driverctl) may help you.
But keep in mind that you will need a second GPU (e.g. CPU-integrated), because you
will be detaching the GPU from host system. If you succeeded with that, and have GPU
available at address `0000:01:00.0`, you can run your image:

```sh
gvltctl local-run -f task.yaml --gpu 0000:01:00.0 risc0-template.img
```

> **_NOTE:_** This Containerfile produces a build for NVIDIA Compute Capability 8.9, which
> corresponds to NVIDIA GeForce RTX 4090 cards installed on Firestarter worker nodes.
> If you have a different model of NVIDIA GPU, you need to change the compilation
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

## 5. Create an account and purchase Credits for ZkCloud Firestarter

See [Get Started](https://docs.gevulot.com/gevulot-docs/firestarter/get-started)
section to learn how to create an account and purchase credits. 1 Credit == 1 USD. The hourly compute cost of a dual-4090 GPU node on Firestarter is 0.84 Credits ($0.84). Users are charged on a pay-per-proof basis, proportionally to the hardware resources allocated and the compute time.

## 6. Upload VM image

Upload your `risc0-template.img` to any public storage and copy the URL. ZkCloud prover nodes will download your VM image from the public HTTP(S) URL.

E.g. if you used Google Cloud, you will get a public URL like this:

```plaintext
https://storage.googleapis.com/gevulot-static-assets/risc0-template.img
```

Copy your URL into `task.yaml` file, replacing `<YOUR IMAGE URL>`.

## 7. Create task

Now you are ready to upload your task to the ZkCloud Firestarter network.

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

> **_NOTE:_** Instead of specifying the endpoint and mnemonic for every command
> you can export them as environment variables `GEVULOT_ENDPOINT` and
> `GEVULOT_MNEMONIC`.

When the state of your task becomes `Done`, you can collect your outputs. Outputs are stored on
Firestarter's private IPFS network, and can be fetched from its gateway:

```sh
curl https://ipfs.firestarter.gevulot.com/download/YOUR_OUTPUT_CID
```

Visit [ZkCloud Firestarter documentation](https://docs.gevulot.com/gevulot-docs/firestarter)
for more information.
