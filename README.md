## proxmox_vm_cloud-init.sh

This is simply a bash script that will allow you to create a fully customizable cloud-init image from proxmox cli.

This might also work without proxmox (using Qemu/KVM) but I have no tested it without proxmox.


## Packages Requirements

Before you try running the script install these packages:

```bash
sudo apt-get install -y ovmf cloud-image-utils
sudo apt install whois
sudo apt-get install -y cloud-utils #optional not really required
```

## Make the script executable
```bash
chmod +x ./proxmox_vm_cloud-init.sh
```

## Run the script (cd to the folder the script is in)
```bash
./proxmox_vm_cloud-init.sh -i 1011 -n ubuntu-test-vm

./proxmox_vm_cloud-init.sh -i 1011 -n ubuntu-test-vm -m bc:24:11:00:00:00 -c https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img -s local-zfs -r 4096 -p 2 -d 20 -b vmbr0 -u username_to_configure --password-hash 'AAAA...' --ssh-key 'ssh-rsa AAAA...' -a amd64 -U http://gb.archive.ubuntu.com/ubuntu
```
The script also runs fine if you are using proxmox-port on arm64 (rpi4 for example) but you'll need to install proxmox using EFI boot.

To use it with proxmox-port just change the following option 
`-a arm64 -U http://ports.ubuntu.com/ubuntu-ports`

To find out more about running proxmox on a raspbeey pi --> [proxmox-port ](https://github.com/jiangcuo/Proxmox-Port)



## Command Options

You can use --help in any part of the command to display the various commands options available

```
Usage: ./proxmox_vm_cloud-init.sh [options] [version 1.0.0]

Options:
  -i, --vmid VMID                      *Specify the VM ID
  -n, --name VMNAME                    *Specify the VM name
  -m, --mac VMMAC                      Specify the VM MAC address (Omit for random PROXMOX Mac)
  -c, --cloudimage VMCLOUDINITURL      Specify the URL to download the Cloud-Init image
  -r, --ram RAM                        Specify the amount of RAM
  -p, --cpucores CPUCORES              Specify the number of CPU cores
  -s, --storage STORAGE                Specify the storage device
  -d, --disk-size DISK_SIZE            Specify the disk size increase in GB
  -b, --bridge BRIDGE                  Specify the network bridge
  -u, --username USERNAME              Specify the username
      --password-hash PASSWORD_HASH    Specify the password hash (echo 'mypasswordhere' | mkpasswd -m sha-512 -s)
      --ssh-key SSH_KEY                Specify the SSH public key
  -a, --arch ARCH                      Specify the architecture (e.g., amd64, arm)
  -U, --packages-url PACKAGES_URL      Specify the PACKAGES_URL for package updates
  -f, --force-download                 Force download the Cloud-Init image even if it already exists
  -h, --help                           Show this help message

   * mandatory arguments to run the script

Short command: (you must define values in the STATIC VARIABLE DECLARATION section of the script)
./proxmox_vm_cloud-init.sh -i 1011 -n ubuntu-test-vm

Long command:
./proxmox_vm_cloud-init.sh -i 1011 -n ubuntu-test-vm -m bc:24:11:00:00:00 -c https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img -s local-zfs -r 4096 -p 2 -d 20 -b vmbr0 -u username_to_configure --password-hash 'AAAA...' --ssh-key 'ssh-rsa AAAA...' -a amd64 -U http://gb.archive.ubuntu.com/ubuntu

```

The script takes a minimum number of 2 arguments/option:

`-i` or `--vmid` followed by the VMID

`-n` ot `--mame` followed by the VMNAME

Most of the other parameters are still mandatory but you can set predefined values for them by editing the script section "START OF STATIC VARIABLE DECLARATION

I might move this to a config file (instead of having to change the values in the script) in a future script update, but only if I can be bothered :-)