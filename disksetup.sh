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
    
    max_partition_size=$(echo "$disk_size" | cut -d ' ' -f1 | cut -d '.' -f1)  # TODO: This won't work if the disk is in TiB

    if [[ $disk_info =~ "$boot_partition" ]]; then
        existing_partitions=( $(echo "$disk_info" | grep '^/dev/' | cut -d' ' -f1))
        echo "WARNING: Disk has ${#existing_partitions[@]} existing partition(s). All data will be lost."
        confirm_delete_partitions
    fi
}
function confirm_delete_partitions {
    echo
    read -p 'Unmount and delete partitions? (y/N) ' should_delete
    if [[ "$should_delete" == [Yy] ]]
    then
        echo
        echo 'Existing partitions will be deleted after final confirmation.'
    elif [[ "$should_delete" == [Nn] ]]
    then
        select_disk
    else
        echo 'Please enter Y or N'
        confirm_delete_partitions
    fi
}

######### Partitions
function start_partitions {
    get_boot_partition_size
    get_root_partition_size
    get_swap_size
}
function get_boot_partition_size {
    echo
    read -p "How big should the boot partition be in Megabytes? (1-1000, default: 512) " boot_partition_size_mb
    if [ "$boot_partition_size_mb" == "" ]
    then
        boot_partition_size_mb=512
        echo "Defaulting to $boot_partition_size_mb MiB"
    elif [[ "$boot_partition_size_mb" != ?(-)+([0-9]) ]]
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
    echo
    echo "Remaining space: $max_partition_size Gib"
}
function get_root_partition_size {
    echo
    read -p "How big should the root partition be in Gigabytes? (1-$max_partition_size) " root_partition_size_gb
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
    echo "Remaining space: $max_partition_size Gib"
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
        start_filesystems
    elif ! (( "0" <= "$root_filesystem_selection" && "$root_filesystem_selection" < "${#FILESYSTEM_OPTIONS[@]}" ));
    then
        echo "Invalid selection"
        start_filesystems
    else
        root_filesystem="${FILESYSTEM_OPTIONS[$root_filesystem_selection]}"
    fi
}

######### Doooooooooooooooooooooo
function confirm_final {
    echo
    echo "Creating GPT partition table on $selected_disk_name"
    if [ "${#existing_partitions[@]}" -gt "0" ]
    then
        echo "Deleting ${#existing_partitions[@]} existing partitions"
    fi
    echo "Creating partitions:"
    echo "  /boot  - $boot_partition_size_mb MiB (FAT32)"
    echo "  /      - $root_partition_size_gb GiB ($root_filesystem)"
    echo "  swap - $swap_partition_size GiB"
    echo
    read -p "Write changes? (y/N) " should_create
    echo $should_create
    if [[ "$should_create" == [Yy] ]]
    then
        echo 'Yes'
        write_everything
    elif [[ "$should_create" == [Nn] ]]
    then
        echo 'No'
        select_disk
    else
        echo 'Please enter Y or N'
        confirm_final
    fi
}
function write_everything {
    if [ "${#existing_partitions[@]}" -gt 0 ]
    then
        delete_existing_partitions
    fi
    create_partitions
    create_filesystems
}
function delete_existing_partitions {
    echo
    echo 'getting mounts'
    mounts=$(mount | grep '^/dev' || true)
    swaps=$(swapon | grep '^/dev' || true)
    echo "Mounts $mounts"
    echo "Swaps $swaps"
    for partition in "${existing_partitions[@]}"
    do
        echo "Deleting $partition"
        if [[ "$mounts" == *"$partition"* ]]
        then
            echo "$mounts" contains $partition
            umount $partition
            echo "Unmounted $partition"
        fi
        if [[ "$swaps" == *"$partition"* ]]
        then
            echo "$swaps" contains $partition
            swapoff $partition
            echo "Swap $partition is off"
        fi
    done
    (
        echo $(printf 'd\n\n%.0s' {1..${#existing_partitions[@]}})
        echo 'w'
    ) | fdisk $selected_disk_name
    echo "Deleted ${#existing_partitions[@]} partitions."
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

echo
echo
echo
echo 'Finished configuring system partitions! Run prechroot.sh to continue'
