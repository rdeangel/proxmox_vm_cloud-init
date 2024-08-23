#!/bin/bash

#### SOFTWARE PACKAGE REQUIREMENTS TO RUN THIS SCRIPT ON PROXMOX ####
# sudo apt-get install -y ovmf cloud-image-utils
# sudo apt install whois (contains mkpasswd utility used to generate password sha-512 password hash)
# sudo apt-get install -y cloud-utils #optional not required
#### SOFTWARE PACKAGE REQUIREMENTS TO RUN THIS SCRIPT ON PROXMOX ####

# Display help information
show_help() {
  echo ""
  echo "Usage: $0 [options] [version 1.0.0]"
  echo ""
  echo "Options:"
  echo "  -i, --vmid VMID                      *Specify the VM ID"
  echo "  -n, --name VMNAME                    *Specify the VM name"
  echo "  -m, --mac VMMAC                      Specify the VM MAC address (Omit for random PROXMOX Mac)"
  echo "  -c, --cloudimage VMCLOUDINITURL      Specify the URL to download the Cloud-Init image"
  echo "  -r, --ram RAM                        Specify the amount of RAM"
  echo "  -p, --cpucores CPUCORES              Specify the number of CPU cores"
  echo "  -s, --storage STORAGE                Specify the storage device"
  echo "  -d, --disk-size DISK_SIZE            Specify the disk size increase in GB"
  echo "  -b, --bridge BRIDGE                  Specify the network bridge"
  echo "  -u, --username USERNAME              Specify the username"
  echo "      --password-hash PASSWORD_HASH    Specify the password hash (echo 'mypasswordhere' | mkpasswd -m sha-512 -s)"
  echo "      --ssh-key SSH_KEY                Specify the SSH public key"
  echo "  -a, --arch ARCH                      Specify the architecture (e.g., amd64, arm)"
  echo "  -U, --packages-url PACKAGES_URL      Specify the PACKAGES_URL for package updates"
  echo "  -f, --force-download                 Force download the Cloud-Init image even if it already exists"
  echo "  -h, --help                           Show this help message"
  echo ""
  echo "   * mandatory arguments to run the script"
  echo ""
  echo "Short command: (you must define values in the STATIC VARIABLE DECLARATION section of the script)"
  echo  "$0 -i 1011 -n ubuntu-test-vm"
  echo ""
  echo "Long command:"
  echo  "$0 -i 1011 -n ubuntu-test-vm -m bc:24:11:00:00:00 -c https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img -s local-zfs -r 4096 -p 2 -d 20 -b vmbr0 -u username_to_configure --password-hash 'AAAA...' --ssh-key 'ssh-rsa AAAA...' -a amd64 -U http://gb.archive.ubuntu.com/ubuntu"
  echo ""
  exit 0
}

################### START OF STATIC VARIABLE DECLARATION

### Define cloud-init image to download to create the vm
DEFAULT_VMCLOUDINITURL=https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

### Define RAM size in MB
DEFAULT_RAM=2048

### Define CPU Cores to use for the VM
DEFAULT_CPUCORES=2

### Define proxmox storage device name to use for the VM
DEFAULT_STORAGE=local-zfs

### Define default disk size increase in GB (excluding cloud-init image initial size)
DEFAULT_DISK_SIZE=20

### Define a valid existing proxmox bridge
DEFAULT_BRIDGE=vmbr0

### Define CPU architecture. Normally amd64 but should also work with arm64 (if you installed proxmox with EFI boot)
DEFAULT_ARCH=amd64

### Define a package URL if you prefer to use one specfically or leave empty for default. (use http://ports.ubuntu.com/ubuntu-ports for arm64/rpi proxmox-port)
DEFAULT_PACKAGES_URL=

### Define a username you want to create
DEFAULT_USERNAME=new_user_here

### Define the computed hash of the password for the username above
DEFAULT_PASSWORD_HASH='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' # use (echo 'mypasswordhere' | mkpasswd -m sha-512 -s) to generate the password hash

### Define the public ssh key you want to use (for passwordless authentication)
DEFAULT_SSH_KEY='ssh-rsa AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA user@example.com'

################### END OF STATIC VARIABLE DECLARATION

# Parse command-line arguments
FORCE_DOWNLOAD=false
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    -i|--vmid) VMID="$2"; shift ;;
    -n|--name) VMNAME="$2"; shift ;;
    -m|--mac) VMMAC="$2"; shift ;;
    -c|--cloudimage) VMCLOUDINITURL="$2"; shift ;;
    -r|--ram) RAM="$2"; shift ;;
    -p|--cpucores) CPUCORES="$2"; shift ;;
    -s|--storage) STORAGE="$2"; shift ;;
    -d|--disk-size) DISK_SIZE="$2"; shift ;;
    -b|--bridge) BRIDGE="$2"; shift ;;
    -u|--username) USERNAME="$2"; shift ;;
    --password-hash) PASSWORD_HASH="$2"; shift ;;
	--ssh-key) SSH_KEY="$2"; shift ;;
    -a|--arch) ARCH="$2"; shift ;;
    -U|--packages-url) PACKAGES_URL="$2"; shift ;;
    -f|--force-download) FORCE_DOWNLOAD=true ;;
    -h|--help) show_help ;;
    *) echo "Unknown parameter passed: $1"; show_help ;;
  esac
  shift
done


# Assigns DEFAULT defined values to variables if not specified from command arguments
if [ -z "$VMCLOUDINITURL" ]; then
  VMCLOUDINITURL="$DEFAULT_VMCLOUDINITURL"
fi

if [ -z "$RAM" ]; then
  RAM="$DEFAULT_RAM"
fi

if [ -z "$CPUCORES" ]; then
  CPUCORES="$DEFAULT_CPUCORES"
fi

if [ -z "$STORAGE" ]; then
  STORAGE="$DEFAULT_STORAGE"
fi

if [ -z "$DISK_SIZE" ]; then
  DISK_SIZE="$DEFAULT_DISK_SIZE"
fi

if [ -z "$BRIDGE" ]; then
  BRIDGE="$DEFAULT_BRIDGE"
fi

if [ -z "$ARCH" ]; then
  ARCH="$DEFAULT_ARCH"
fi

if [ -z "$PACKAGES_URL" ]; then
  PACKAGES_URL="$DEFAULT_PACKAGES_URL"
fi

if [ -z "$USERNAME" ]; then
  USERNAME="$DEFAULT_USERNAME"
fi

if [ -z "$PASSWORD_HASH" ]; then
  PASSWORD_HASH="$DEFAULT_PASSWORD_HASH"
fi

if [ -z "$SSH_KEY" ]; then
  SSH_KEY="$DEFAULT_SSH_KEY"
fi

# Validate MAC address format
validate_mac() {
  if [[ ! "$VMMAC" =~ ^([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2}$ ]]; then
    echo "Error: Invalid MAC address format."
    exit 1
  fi
}

# Validate if the argument is a number
validate_number() {
  if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "Error: $2 must be a number."
    exit 1
  fi
}

# Validate if the argument is a positive number
validate_positive_number() {
  if ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "Error: $2 must be a positive number."
    exit 1
  fi
}

# Download the cloud-init image
download_image() {
  local url="$1"
  local output="$2"
  echo "Downloading cloud-init image from $url..."
  if ! curl -L -o "$output" "$url"; then
    echo "Error: Failed to download cloud-init image."
    exit 1
  fi
  echo "Downloaded cloud-init image to $output"
}

# Validate file existence
validate_file() {
  if [ ! -f "$1" ]; then
    echo "Error: VM image file $1 does not exist."
    exit 1
  fi
}

# Check and remove files
remove_files_if_exist() {
  for file in "$@"; do
    if [ -e "$file" ]; then
      echo "Removing existing $file"
      rm -f "$file"
    else
      echo "File $file does not exist, skipping."
    fi
  done
}

# Prompt for confirmation before destroying VM
prompt_for_confirmation() {
  local vmid="$1"
  read -p "VM with ID $vmid already exists. Do you want to destroy it and create a new one? Type 'YES' to confirm: " confirmation
  if [[ "$confirmation" != "YES" ]]; then
    echo "Operation aborted."
    exit 1
  fi
}

## Validate required arguments
#if [ -z "$VMID" ] || [ -z "$VMNAME" ]; then
#  echo "Error: Missing required arguments."
#  show_help
#fi

if [ -z "$VMID" ] || [ -z "$VMNAME" ] || [ -z "$VMCLOUDINITURL" ] || [ -z "$RAM" ] || [ -z "$CPUCORES" ] ||  [ -z "$STORAGE" ] || [ -z "$DISK_SIZE" ] || [ -z "$BRIDGE" ] || [ -z "$USERNAME" ] || [ -z "$ARCH" ] || [ -z "PASSWORD_HASH" ] || [ -z "SSH_KEY" ]; then
  echo "Error: Missing required arguments."
  show_help
fi

# Validate VMID, RAM, and CPU cores
validate_number "$VMID" "VMID"
validate_number "$RAM" "RAM"
validate_number "$CPUCORES" "CPU cores"

# Validate MAC address if provided
if [ -n "$VMMAC" ]; then
  validate_mac "$VMMAC"
fi

# Validate disk size if provided
if [ -n "$DISK_SIZE" ]; then
  validate_positive_number "$DISK_SIZE" "Disk size increase"
fi

# Check if VM already exists
if qm status "$VMID" &>/dev/null; then
  prompt_for_confirmation "$VMID"
fi

# Prepare Cloud-Init image path
VMCLOUDINITIMAGE="/var/lib/vz/template/iso/$(basename "$VMCLOUDINITURL")"

# Download the Cloud-Init image if it doesn't exist or if force download is enabled
if [ ! -f "$VMCLOUDINITIMAGE" ] || [ "$FORCE_DOWNLOAD" = true ]; then
  echo "Downloading the Cloud-Init image"
  download_image "$VMCLOUDINITURL" "$VMCLOUDINITIMAGE"
else
  echo "Cloud-Init image already exists at $VMCLOUDINITIMAGE. Use --force-download to re-download."
fi
echo ""
# Validate Cloud-Init image file existence
validate_file "$VMCLOUDINITIMAGE"

# Stop existing VM if it exists
echo "Stoping existing VM if it exists"
qm stop "$VMID"
echo ""

# Destroy the VM and purge its disks
echo "Destroying existing VM if it exists"
qm destroy "$VMID" --purge
echo ""

# Remove old cloud-init configuration files
echo "Checking if existing cloud-init config file need to be removed"
remove_files_if_exist "user-data.yaml" "network-config.yaml"
echo ""


############################################################################
############################################################################
##### ##### ##### CUSTOMIZE YOUR CLOUDINITI user-data.yaml ##### ##### #####

cat << EOF > user-data.yaml
#cloud-config

hostname: $VMNAME

apt:
  primary:
    - arches: [$ARCH]
      uri: $PACKAGES_URL
      search_dns: true

users:
  - name: $USERNAME
    gecos: vm owner
    homedir: /home/$USERNAME
EOF
cat << 'EOF' >> user-data.yaml
    groups: sudo
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    shell: /bin/bash
EOF

# Defines PASSWORD_HASH and SSH_KEY in user-data.yaml
cat << EOF >> user-data.yaml
    passwd: '$PASSWORD_HASH'
    lock_passwd: false  # Set to true if you want to disable password login
    ssh_authorized_keys:
      - '$SSH_KEY'
EOF

cat << 'EOF' >> user-data.yaml

package_update: true
package_upgrade: true
packages:
  - git
  - curl
  - wget
  - tshark
  - iftop
  - net-tools
  - neovim
  - fzf

# Write multiline content to .bashrc
write_files:
  - path: /root/.bashrc.cloud-init
    content: |
      
      ###
      # added by cloud-init script
      LS_COLORS="rs=0:di=01;33:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:*.c=01;35:*.cpp=01;35:*.java=01;35:*.py=01;35:*.js=01;35:*.rb=01;35:*.php=01;35:*.html=01;35:*.htm=01;35:*.css=01;35:*.sh=01;32:*.bat=01;32:*.pl=01;32:*.awk=01;32:*.yaml=01;36:*.yml=01;36:*.conf=01;36:*.txt=01;36:"
      export LS_COLORS
      
      
      if [ -f /usr/share/bash-completion/completions/fzf ]; then
        source /usr/share/bash-completion/completions/fzf
      fi
      
      if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
        source /usr/share/doc/fzf/examples/key-bindings.bash
      fi
      
      ## Define all the colors
      COL_USER_HOST='\[\e[32m\]' # The color of 'user@host.ext'
      COL_CURSOR='\[\e[31m\]' # The color of the trailing cursor arrow
      COL_CURRENT_PATH='\[\e[37m\]' # The color of the current directory full path
      COL_GIT_STATUS_CLEAN='\[\e[93m\]' # Color of fresh git branch name, with NO changes
      COL_GIT_STATUS_CHANGES='\[\e[92m\]' # Color of git branch, affter its diverged from remote
      
      ## Text Styles
      RESET='\[\e[0m\]' # What color will comand outputs be in
      BOLD='\[\e[1m\]' # BOLD
      
      ## Config
      SHOW_GIT=true
      
      ## If this is a valid git repo, echo the current branch name
      parse_git_branch() {
          git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
      }
      
      ## Echos what color the git branch should be (depending on changes)
      parse_git_changes() {
        if [[ $(git status --porcelain) ]]; then
          echo ${COL_GIT_STATUS_CLEAN}
        else
          echo ${COL_GIT_STATUS_CHANGES}
        fi
      }
      
      ## Build-up what will be the final PS1 string
      set_bash_prompt(){
        PS1="${RESET}"
        PS1+="${BOLD}${COL_USER_HOST}\u @ \h ${RESET}${COL_CURRENT_PATH}\w "
      
        if [ "$SHOW_GIT" = true ] && [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" = true ] ; then
          PS1+="$(parse_git_changes)"
          PS1+="$(parse_git_branch)"
        fi
      
        PS1+="\n${COL_CURSOR}└─▶ "
        PS1+="${RESET}"
      }
      
      ## Done, now just set the PS1 prompt :)
      PROMPT_COMMAND=set_bash_prompt

EOF

cat << EOF >> user-data.yaml
runcmd:
  - sed -i 's/^127.0.0.1.*/127.0.0.1 localhost $VMNAME/' /etc/hosts
  - echo "Running custom commands"
  - update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60
  - update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
  - update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
  - su -c "cat /root/.bashrc.cloud-init >> /home/$USERNAME/.bashrc"
  - su -c "cat /root/.bashrc.cloud-init >> /root/.bashrc"
EOF
##### ##### ##### CUSTOMIZE YOUR CLOUDINITI user-data.yaml ##### ##### ##### 
############################################################################
############################################################################




################################################################################
################################################################################
##### ##### ##### CUSTOMIZE YOUR CLOUDINITI network-config.yaml ##### ##### ##### 
# Create network-config.yaml
# This is where you could set a static ip address or other network settings, didn't implement any variables but can be used.
cat << EOF > network-config.yaml
#network-config
#network:
#  version: 2
#  ethernets:
#    ens18: ### ens18 on amd64 ### enp0s11 on rpi
#      dhcp4: true
#      dhcp6: false
EOF
##### ##### ##### CUSTOMIZE YOUR CLOUDINITI network-config.yaml ##### ##### ##### 
################################################################################
################################################################################


# Create the cloud-init ISO
echo "Creating the cloud-init ISO"
cloud-localds /var/lib/vz/template/iso/cloud-init.iso user-data.yaml --network-config=network-config.yaml
echo ""
# Create the VM with specified configurations
echo "Creating the VM with specified configurations"
if [ -n "$VMMAC" ]; then
  # when -m, --mac is specified
  qm create "$VMID" --memory "$RAM" --cores "$CPUCORES" --name "$VMNAME" --net0 virtio,bridge="$BRIDGE",macaddr="$VMMAC",firewall=1 --bios ovmf --efidisk0 "$STORAGE":64 --scsihw virtio-scsi-pci --scsi2 local:iso/cloud-init.iso,media=cdrom
else
  # when -m, --mac is NOT specified
  qm create "$VMID" --memory "$RAM" --cores "$CPUCORES" --name "$VMNAME" --net0 virtio,bridge="$BRIDGE",firewall=1 --bios ovmf --efidisk0 "$STORAGE":64 --scsihw virtio-scsi-pci --scsi2 local:iso/cloud-init.iso,media=cdrom
fi
echo ""
# Import img disk for the VM
echo "Importing cloud-init img disk for the VM"
qm importdisk "$VMID" "$VMCLOUDINITIMAGE" "$STORAGE"
echo ""
# Attach disk to the VM
echo "Attaching disk to the VM"
qm set "$VMID" --scsihw virtio-scsi-pci --scsi0 "$STORAGE":vm-"$VMID"-disk-1
echo ""
# Resize the disk using the provided disk size
echo "Increasing size of disk: +$DISK_SIZE GB"
qm resize "$VMID" scsi0 +"$DISK_SIZE"G
echo ""
# Set boot disk
echo "Setting boot disk"
qm set "$VMID" --boot c --bootdisk scsi0
echo ""
# Configure VM output for serial console
echo "Configuring VM output for serial console"
qm set "$VMID" --serial0 socket --vga serial0
echo ""
# Start the VM
echo "Starting the VM"
qm start "$VMID"
echo ""
# Attach terminal to the VM console to see it boot and the cloudinit process progress
echo "Attaching terminal to the VM console"
qm terminal "$VMID" ### press ctrl-o to exit the console of the VM
