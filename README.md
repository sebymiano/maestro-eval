# Maestro evaluation testsuit

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