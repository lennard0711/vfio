# VFIO
In this repo you can find everything about my VFIO setup. I mainly use it for gaming on a Windows VM while using a Arch Linux host system.

I mostly used the Arch Wiki to setup everything, especially this page: [PCI passthrough via OVMF](https://wiki.archlinux.org/index.php/PCI_passthrough_via_OVMF)

## TODOs
- [ ] Create QEMU hooks to disable host screen 1 after booting the VM
- [ ] Pass through USB controller for hotplugging support in the VM
- [ ] Document mainboard settings
- [ ] Isolate pinned CPUs

## Hardware

Type | Device | Info
------------ | ------------- | -------------
Mainboard | ASRock X570 Pro4
CPU | AMD Ryzen 7 3700x | 8C/16T
GPU | AMD XFX Radeon RX 580 GTS Core Aktiv | VFIO
GPU | MSI GeForce GT 1030 Aero ITX | Host
RAM | 16GB G.Skill Aegis DDR4-3200
RAM | 16GB G.Skill Aegis DDR4-3200
SSD | 500 GB Crucial P1 NVMe | /dev/nvme0n1
SSD | 500 GB Crucial MX500 SATA | /dev/sdb
HDD | 1000 GB Seagate BarraCuda ST1000DM010 | /dev/sda
HDD | 1000 GB Seagate BarraCuda ST1000DM010 | /dev/sdc

## Mainboard Settings
tba

## Installation

### Arch Linux
#### Packages
* `libvirt`
* `qemu`
* `edk2-ovmf`
* `ebtables`
* `dnsmasq`
* `bridge-utils`
* `openbsd-netcat`
* `virt-manager`

Install all packages via pacman:

`sudo pacman -S libvirt qemu edk2-ovmf ebtables dnsmasq bridge-utils openbsd-netcat virt-manager`

Start/Enable the libvirt service:

`sudo systemctl start libvirtd.service`

`sudo systemctl enable libvirtd.service`

#### User Group
Add yourself to the `libvirt` group to get passwordless access to the QEMU system socket.

## Partition Setup
All devices are luks2 encrypted.

All hard drives have at least one lvm volume which is passed through to the VM.

`/dev/sda` is used as a HDD to store all games on.

`/dev/sdb` is used as the SSD to run the OS and most programs.

`/dev/sdc` is used to store my other VMs.
```
sda                            8:0    0 931,5G  0 disk  
└─win10-hdd                  254:5    0 931,5G  0 crypt 
  └─win10--hdd-games         254:6    0 931,5G  0 lvm   
sdb                            8:16   0 465,8G  0 disk  
└─win10-ssd                  254:3    0 465,7G  0 crypt 
  └─win10--ssd-root          254:4    0 465,7G  0 lvm   
sdc                            8:32   0 931,5G  0 disk  
└─sdc1                         8:33   0 931,5G  0 part  
  └─libvirt                  254:7    0 931,5G  0 crypt 
    ├─libvirt-gentoo         254:8    0    50G  0 lvm   
    ├─libvirt-fedora         254:9    0   100G  0 lvm   
    ├─libvirt-ubuntu         254:10   0   100G  0 lvm   
    ├─libvirt-rhel           254:11   0   100G  0 lvm   
    └─libvirt-RDPWindows     254:12   0    80G  0 lvm   
nvme0n1                      259:0    0 465,8G  0 disk  
├─nvme0n1p1                  259:1    0   512M  0 part  /boot
└─nvme0n1p2                  259:2    0 465,3G  0 part  
  └─cryptroot                254:0    0 465,2G  0 crypt 
    ├─arch-swap              254:1    0    32G  0 lvm   [SWAP]
    └─arch-root              254:2    0 433,2G  0 lvm   /
```

## VM config

### Hypervisor Details

Type | Info 
------------ | -------------
Hypervisor | KVM
Architecture | x86_64
Emulator | /usr/bin/qemu-system-x86_64
Chipset | i440FX
Firmware | UEFI x86_64: /usr/share/edk2-ovmf/x64/OVMF_CODE.fd


### CPU
#### Cores
Use 1 Socket with 6 cores and 2 threads = 12 threads

To use the nested virtualisation feature on Windows with an AMD Chipset, you'll need to use the Windows insider builds!

I don't use it for my Windows VM but for others (RHEL), that's why I have it enabled in the `/etc/modprode.d/kvm.conf` config.

So unless you want to play Valorant which needs Hyper-V enabled and working nested virtualisation in order to work, you can skip the `/etc/modprode.d/kvm.conf` part.

`/etc/libvirt/qemu/win10.xml`
```xml
<cpu mode="host-passthrough" check="none" migratable="on">
  <topology sockets="1" dies="1" cores="6" threads="2"/>
  <feature policy="require" name="topoext"/>
</cpu>
```

`/etc/modprobe.d/kvm.conf`
```
options kvm_amd nested=1
options kvm ignore_msrs=1
```
#### CPU pinning
This currently enables CPU pinning but it doesn't stop processes from the host machine to use these cores.

`/etc/libvirt/qemu/win10.xml`
```xml
<vcpu placement="static">12</vcpu>
<cputune>
  <vcpupin vcpu="0" cpuset="2"/>
  <vcpupin vcpu="1" cpuset="10"/>
  <vcpupin vcpu="2" cpuset="3"/>
  <vcpupin vcpu="3" cpuset="11"/>
  <vcpupin vcpu="4" cpuset="4"/>
  <vcpupin vcpu="5" cpuset="12"/>
  <vcpupin vcpu="6" cpuset="5"/>
  <vcpupin vcpu="7" cpuset="13"/>
  <vcpupin vcpu="8" cpuset="6"/>
  <vcpupin vcpu="9" cpuset="14"/>
  <vcpupin vcpu="10" cpuset="7"/>
  <vcpupin vcpu="11" cpuset="15"/>
  <emulatorpin cpuset="0,8"/>
</cputune>
```

### Disks
#### Boot Disk / SSD
`/etc/libvirt/qemu/win10.xml`
```xml
<disk type="block" device="disk">
  <driver name="qemu" type="raw" cache="none" io="native"/>
  <source dev="/dev/win10-ssd/root"/>
  <target dev="vda" bus="virtio"/>
  <boot order="1"/>
  <address type="pci" domain="0x0000" bus="0x00" slot="0x07" function="0x0"/>
</disk>
```

#### HDD
`/etc/libvirt/qemu/win10.xml`
```xml
<disk type="block" device="disk">
  <driver name="qemu" type="raw" cache="none" io="native"/>
  <source dev="/dev/win10-hdd/games"/>
  <target dev="vdb" bus="virtio"/>
  <address type="pci" domain="0x0000" bus="0x00" slot="0x08" function="0x0"/>
</disk>
```

### Audio
I pass my audio directly to my pulseaudio server (provided by pipewire).

`/etc/libvirt/qemu.conf`
```
user = "lennard0711"
```

`/etc/libvirt/qemu/win10.xml`
```xml
<domain xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0" type="kvm">
  <qemu:commandline>
    <qemu:arg value="-audiodev"/>
    <qemu:arg value="pa,id=snd0,server=/run/user/1000/pulse/native"/>
  </qemu:commandline>
</domain>
```