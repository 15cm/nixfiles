#!/bin/bash

set -eox pipefail

################################################################################

COLOR_RESET="\033[0m"
RED_BG="\033[41m"
BLUE_BG="\033[44m"

function err {
    echo -e "${RED_BG}$1${COLOR_RESET}"
}

function info {
    echo -e "${BLUE_BG}$1${COLOR_RESET}"
}

################################################################################

usage() {
  cat << EOF
Usage: ${0} [OPTIONS] [ARGUMENTS]
Options:
  --help              Display this help and exit
  -d, --disk          </dev/disk/by-path/disk> of the disk for installation.
  -p, --partition     The start partition number of the Windows resevered partition. Example "1".
                      WARNING: - If on the same disk as the Linux Installation, it must be greater than the last Linux partition number
                               - If on the different disk, it must be greater than 1 to be after the separate dummy esp for Windows.
  [-s, --size]        <size> of the windows data partition in sgdisk end section format. Default value: use all remaining space of the partition.
  [-z, --zap]         If specified, destroy the existing partition table of the disk. Usually used for a multiple disks setup.
  [--separate_esp]    For dual boot on different disks. Create a dummy ESP partition for Windows to install.
EOF
}

while (("$#")); do
  case "$1" in
    -d|--disk)
      disk="$2"
      shift 2
      ;;
    -p|--partition)
      part_start_num="$2"
      shift 2
      ;;
    -s|--size)
      size="$2"
      shift 2
      ;;
    -z|--zap)
      should_zap=true
      shift
      ;;
    --separate_esp)
      separate_esp=true
      shift
      ;;
    --help)
      help=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [[ -n "$help" || -z "$disk" || -z "$part_start_num" ]]; then
  usage
  exit 0
fi

# Ref: https://wiki.archlinux.org/title/Dual_boot_with_Windows#Windows_10_with_GRUB
part_num_microsoft_reserved=$(($part_start_num))
part_num_windows_re=$(($part_start_num + 1))
part_num_microsoft_basic_data=$(($part_start_num + 2))
info "Partitioning $disk"
if [ -n "$should_zap" ]; then
  zpool labelclear -f $disk || :
  wipefs -a $disk
  sgdisk --zap-all $disk
fi
if [ -n "$separate_esp" ]; then
  sgdisk -n1:1M:+128M                                   -t1:0700 $disk
fi
sgdisk -n${part_num_microsoft_reserved}:0:+16M          -t${part_num_microsoft_reserved}:0C01 $disk
sgdisk -n${part_num_windows_re}:0:+300M                 -t${part_num_windows_re}:2700 $disk
if [ -n "$size" ]; then
  sgdisk -n${part_num_microsoft_basic_data}:0:+${size}  -t${part_num_microsoft_basic_data}:0700 $disk
else
  sgdisk -n${part_num_microsoft_basic_data}::           -t${part_num_microsoft_basic_data}:0700 $disk
fi

sleep 3
partprobe $disk

disk_part_microsoft_reserved=${disk}-part${part_num_microsoft_reserved}
disk_part_microsoft_basic_data=${disk}-part${part_num_microsoft_basic_data}
disk_part_windows_re=${disk}-part${part_num_windows_re}

for i in {1..10}; do
  info "Waiting for windows partitions to be ready. $i out of 10 retries"
  sleep 3
  if [[
    -e "${disk_part_microsoft_reserved}" \
    && -e "${disk_part_microsoft_basic_data}" \
    && -e "${disk_part_windows_re}" ]]; then
  break
  fi
done

info "Formatting Windows partitions"
mkntfs -L MICROSOFT_BASIC_DATA -f ${disk_part_microsoft_basic_data}
mkntfs -L WINDOWS_RE -f ${disk_part_windows_re}

