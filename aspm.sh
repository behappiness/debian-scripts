#!/bin/bash

# Function to display usage information
function usage() {
    echo "Usage: $0 [-d] [-e]"
    echo "  -d: Dry run mode. Only display what would be set without making changes."
    echo "  -e: Execute changes. Enable ASPM settings on devices."
    exit 1
}

# Parse command-line arguments
DRY_RUN=false
EXECUTE=false
while getopts ":de" opt; do
    case $opt in
        d) DRY_RUN=true ;;
        e) EXECUTE=true ;;
        *) usage ;;
    esac
done

# If neither dry run nor execute is set, show usage
if [ "$DRY_RUN" = false ] && [ "$EXECUTE" = false ]; then
    usage
fi

# Function to enable ASPM for devices with ASPM disabled
function enable_aspm_for_devices() {
    lspci -vv | awk '
    /^[0-9a-f]+:[0-9a-f]+.[0-9a-f]+/ { 
        device_id = $1; 
        device_name = substr($0, index($0, $3)); 
        aspm_disabled = 0; 
        lnkcap = ""; 
        lnkctl = ""; 
    }
    /LnkCap:/ { 
        lnkcap = $0; 
    }
    /LnkCtl:/ { 
        lnkctl = $0; 
        if ($0 ~ /ASPM Disabled/) { 
            aspm_disabled = 1; 
        } 
    }
    /^$/ { 
        if (aspm_disabled) { 
            print device_id "\n" device_name "\n" lnkcap "\n" lnkctl; 
        } 
    }' | while IFS= read -r device_id && IFS= read -r device_name && IFS= read -r lnkcap && IFS= read -r lnkctl; do
        # Determine possible ASPM settings from LnkCap
        aspm_setting=-1
        aspm_description=""
        if [[ $lnkcap =~ "L0s L1" ]]; then
            aspm_setting=3
            aspm_description="L0s and L1"
        elif [[ $lnkcap =~ "L1" ]]; then
            aspm_setting=2
            aspm_description="L1"
        elif [[ $lnkcap =~ "L0s" ]]; then
            aspm_setting=1
            aspm_description="L0s"
        elif [[ $lnkcap =~ "L0" ]]; then
            aspm_setting=0
            aspm_description="L0"
        fi

        # Only proceed if a compatible ASPM setting is found
        if [ $aspm_setting -ne -1 ]; then
            if [ "$DRY_RUN" = true ]; then
                echo "Dry Run: Device ID: $device_id"
                echo "         Device Name: $device_name"
                echo "         ASPM Capabilities: $lnkcap"
                echo "         Current ASPM Setting: $lnkctl"
                echo "         Would enable ASPM with setting $aspm_setting ($aspm_description)"
                echo ""
            elif [ "$EXECUTE" = true ]; then
                echo "Enabling ASPM for device $device_id with setting $aspm_setting ($aspm_description)"
                ./enable_aspm.sh -e "$device_id" -s "$aspm_setting"
            fi
        else
            if [ "$DRY_RUN" = true ]; then
                echo "Dry Run: Device ID: $device_id"
                echo "         Device Name: $device_name"
                echo "         ASPM Capabilities: $lnkcap"
                echo "         Current ASPM Setting: $lnkctl"
                echo "         No compatible ASPM setting found."
                echo ""
            fi
        fi
    done
}

# Enable ASPM for devices
enable_aspm_for_devices