# Maestro evaluation testsuit

## Traffic Generator

1. Install the dependencies: `installers/install-deps-tg.sh`.
2. Activate the python env `source build/env/bin/activate`.
3. Get the RX and TX PCIe names (we can, for example, use DPDK for this: `build/dpdk/usertools/dpdk-devbind --status-dev net`).
4. Modify the `vars.sh` file with the correct data.
5. Generate the pcaps: `pcaps/generate.sh`.
6. Setup the environment: `util/setup-tg.sh`.
7. Run the experiments on the `bench` directory (don't forget to also setup the DUT).

## Device Under Test (DUT)

1. Install the dependencies: `installers/install-deps-dut.sh` (**note:** this requires `docker` to be installed and acessible by users without sudo).
2. Get the RX and TX PCIe names (we can, for example, use DPDK for this: `build/dpdk/usertools/dpdk-devbind --status-dev net`).
3. Modify the `vars.sh` file with the correct data.
4. Setup the environment: `util/setup-dut.sh`.
5. Generate all the pcaps (`pcaps/generate.sh`) **OR** copy them from the TG.

## Transactional Memory

Double check that transactional memory is working on the machine:

```
$ util/check-tsx.sh
RTM: Yes
HLE: Yes
```

⚠️ **WARNING**: running the Maestro TM solutions without having RTM enabled will not actually result in an error, but in a significant drop in performance, as all transactions always abort.

### Transactional Memory not working

Add `tsx=on` to the kernel arguments by modifying the `GRUB_CMDLINE_LINUX` field in the `/etc/default/grub` file:

```
[...]
GRUB_CMDLINE_LINUX="tsx=on isolcpus=16-31 intel_pstate=disable"
[...]
```

Persist the changes:

```
$ sudo update-grub
```

And reboot.