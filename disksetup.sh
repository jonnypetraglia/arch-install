#!/bin/env bash
set -e
set -o pipefail
if [ $(id -u) -ne 0 ]
then
    echo 'Script must be run as root'
    exit 403
fi

source ./environment.sh

######### Constants

IFS=$'\n'
FILESYSTEM_OPTIONS=('ext4' 'btrfs')


######### Variables that will be set

disk_names=()
selected_disk_name=''
max_partition_size=0
boot_partition_size_mb=0
root_partition_size_gb=0
root_filesystem=''
boot_partition=''
root_partition=''
swap_partition=''

######### Selecting disk

function select_disk {
    disks=( $(fdisk -l | grep '^Disk /') )
    echo
    for i in "${!disks[@]}"
    do
        disk="${disks[$i]}"
        disk_name="$(echo $disk | cut -d ' ' -f2 | cut -d ':' -f1)"
        disk_names+=($disk_name)
        echo "$i) $disk_name"
    done
    echo
    read -p 'Select a disk: ' selected_disk_index
    if [[ "$selected_disk_index" != ?(-)+([0-9]) ]]
    then
        echo "Please enter the number of the option."
        echo
        select_disk
    elif ! (( 0 <= "$selected_disk_index" && "$selected_disk_index" < "${#disks[@]}" ));
    then
        echo "That is not a valid selection."
        echo
        select_disk
    else
        selected_disk_name="${disk_names[$selected_disk_index]}"
        boot_partition="${selected_disk_name}1"
        root_partition="${selected_disk_name}2"
        swap_partition="${selected_disk_name}3"
        print_disk_info
    fi
}
function print_disk_info {
    echo selected $selected_disk_name
    disk_info=$(fdisk -l "$selected_disk_name")
    disk_model=$(echo "$disk_info" | grep '^Disk model:' | cut -d ':' -f2 | xargs)
    disk_size=$(echo "$disk_info" | grep "^Disk $selected_disk_name:" | cut -d ':' -f2 | cut -d ',' -f1 | xargs)

    echo
    echo "Disk:     $selected_disk_name"
    echo "Model:    $disk_model"
    echo "Size:     $disk_size"
    

    echo
    echo "$disk_info"
    echo
    if [[ $disk_info =~ "$boot_partition" ]]; then
        partitions=( $(echo "$disk_info" | grep '^/dev/'))
        echo "WARNING: Disk has ${#partitions[@]} existing partition(s). All data will be lost."
        if [[ "${#partitions[@]}" -gt 0 ]]
        then
            echo "ERROR: Delete all partitions on selected_disk_name before proceeding"
            exit 500
        fi
    fi

    max_partition_size=$(echo "$disk_size" | cut -d ' ' -f1 | cut -d '.' -f1)  # TODO: This won't work if the disk is in TiB
    # for partition in "${partitions[@]}"
    # do
    #     echo "$partition"
    # done
}

######### Partitions
function start_partitions {
    get_boot_partition_size
    get_root_partition_size
    get_swap_size
}
function get_boot_partition_size {
    read -p "How big should the boot partition be in Megabytes [1-1000]: " boot_partition_size_mb
    if [[ "$boot_partition_size_mb" != ?(-)+([0-9]) ]]
    then
        echo "Please enter a valid number"
        echo
        get_boot_partition_size
    elif ! (( "1" <= "$boot_partition_size_mb" && "$boot_partition_size_mb" <= "1000" ));
    then
        echo "Please enter a size between 1 and 1000"
        get_boot_partition_size
    fi
    max_partition_size=$((max_partition_size - 1))
}
function get_root_partition_size {
    echo
    read -p "How big should the root partition be in Gigabytes [1-$max_partition_size]: " root_partition_size_gb
    if [[ "$root_partition_size_gb" != ?(-)+([0-9]) ]]
    then
        echo "Please enter a valid number"
        echo
        get_root_partition_size
    elif ! (( "1" <= "$root_partition_size_gb" && "$root_partition_size_gb" <= "$max_partition_size" ));
    then
        echo "Please enter a size between 1 and $max_partition_size"
        get_root_partition_size
    fi
    max_partition_size=$((max_partition_size - root_partition_size_gb))
}
function get_swap_size {
    let "swap_partition_size = $max_partition_size"
    echo "Swap partition size will be remaining (~$swap_partition_size GiB)"
}

######### Filesystems
function start_filesystems {
    echo
    for i in "${!FILESYSTEM_OPTIONS[@]}"
    do
        echo "$i) ${FILESYSTEM_OPTIONS[i]}"
    done
    echo
    read -p "Which filesystem should be used for the root partition? " root_filesystem_selection
    if [[ "$root_filesystem_selection" != ?(-)+([0-9]) ]]
    then
        echo "Please enter a valid number"
        echo
        start_filesystems
    elif ! (( "0" <= "$root_filesystem_selection" && "$root_filesystem_selection" < "${#FILESYSTEM_OPTIONS[@]}" ));
    then
        echo "Invalid selection"
        echo
        start_filesystems
    else
        root_filesystem="${FILESYSTEM_OPTIONS[$root_filesystem_selection]}"
    fi
}

######### Doooooooooooooooooooooo
function confirm_final {
    echo
    echo "Creating GPT partition table on $selected_disk_name"
    echo "2 partitions:"
    echo "  /boot  - $boot_partition_size_mb MiB (FAT32)"
    echo "  /      - $root_partition_size_gb GiB ($root_filesystem)"
    echo "  swap - $swap_partition_size GiB"
    echo
    read -p "Write changes? (y/N) " should_create
    if [[ "$should_create" == [Yy] ]]
    then
        write_everything
    elif [[ "$should_create" == [Nn] ]]
    then
        print_disk_info
        start_partitions
    else
        echo 'Please enter Y or N'
        confirm_final
    fi
}
function write_everything {
    create_partitions
    create_filesystems
}
function create_partitions {
    echo
    echo 'Creating partitions'
    # https://superuser.com/questions/332252/how-to-create-and-format-a-partition-using-a-bash-script
    (
        echo g      # create a new empty GPT partition table
        echo w
    ) | fdisk $selected_disk_name
    echo "Created new Partition Table on $selected_disk_name"
    (
        echo n      # add a new partition
        echo        ## (Partition number) - will default to 1
        echo        ## (First sector) - will default to start of disk
        echo "+${boot_partition_size_mb}m" ## (Last sector, +/-sectors or +/-size{K,M,G,T,P})
        echo t      # change a partition type
        echo 1      ## (EFI System)
        echo w
    ) | fdisk $selected_disk_name
    echo "Created boot partition at $boot_partition"
    (
        echo n      # add a new partition
        # ?? p   primary partition? Doesn't seem to be needed when trying flash drive...
        echo        ## (Partition number) - will default to 2
        echo        ## (First sector) - will default to start of disk
        echo "+${root_partition_size_gb}g" ## (Last sector, +/-sectors or +/-size{K,M,G,T,P})
        echo w
    ) | fdisk $selected_disk_name
    echo "Created boot partition at $root_partition"
    (
        echo n      # add a new partition
        echo        ## (Partition number) - will default to 3
        echo        ## (First sector) - will default to end of root partition
        ## could use +${swap_partition_size}g but meh, just use rest of disk
        echo        ## (Last sector, +/-sectors or +/-size{K,M,G,T,P}) - rest of disk
        echo t      # change a partition type
        echo        ## (Partition number) - will default to 3
        echo 19     ## (Linux Swap)
        echo w
    ) | fdisk $selected_disk_name
    echo "Created swap partition at $swap_partition"
}
function create_filesystems {
    echo "Creating filesystem for Boot partition at $boot_partition"
    mkfs.fat -F32 $boot_partition
    echo "Creating filesystem for Root partition at $root_partition"
    "mkfs.${root_filesystem}" $root_partition -F
    case "$root_filesystem" in
        'btrfs')
            btrfs filesystem label $root_partition $MY_HOSTNAME
            ;;
        'ext4')
            e2label $root_partition $MY_HOSTNAME
            ;;
    esac
    echo "Creating Swap at $swap_partition"
    mkswap $swap_partition
}


######### Post-steps
function mount_filesystems {
    echo "Mounting new filesystems"
    mkdir -p $ROOT_FS
    mount $root_partition $ROOT_FS
    mkdir $ROOT_FS/boot
    mount $boot_partition $ROOT_FS/boot
    swapon $swap_partition
}
function generate_fstab {
    echo "Generating $ROOT_FS/etc/fstab"
    mkdir -p $ROOT_FS/etc
    genfstab -U $ROOT_FS > $ROOT_FS/etc/fstab
}


select_disk
start_partitions
start_filesystems
confirm_final
mount_filesystems
generate_fstab

echo 'Finished configuring system partitions! Run prechroot.sh to continue'
