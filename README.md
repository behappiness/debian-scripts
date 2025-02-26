# Debian Scripts Documentation

This repository contains several scripts designed to manage system performance and configurations. Below are detailed introductions and usage instructions for each script.

## `cpu_scale.sh`

### Introduction
The `cpu_scale.sh` script dynamically adjusts the CPU governor settings based on the system's CPU load. It optimizes power consumption and performance by switching between different CPU governors depending on the current load. (Recommended to use `powertop` as well.)

### Usage
1. **Place the script** in the desired directory where it should be executed.
2. **Make the script executable**:
   ```shell
   chmod +x /path/to/cpu_scale.sh
   ```
3. **Edit the crontab** to run the script at every reboot:
   ```shell
   @reboot sleep 60 && bash /path/to/cpu_scale.sh
   ```
4. **Reboot** the system to apply changes.
5. **Monitor** the script's performance and logs to ensure it is functioning as expected.

### Requirements
- **sysstat** package: Ensure that the `sysstat` package is installed, as it provides the `sar` command used in the script.

### Source
- The script is sourced from [Tontonjo's GitHub repository](https://github.com/Tontonjo/proxmox).

---

## `aspm.sh`

### Introduction
The `aspm.sh` script manages Active State Power Management (ASPM) settings on PCI devices. It can run in a dry mode to display potential changes or execute mode to apply the changes.

### Usage
- **Dry Run Mode**: Display what would be set without making changes.
  ```shell
  ./aspm.sh -d
  ```
- **Execute Mode**: Enable ASPM settings on devices.
  ```shell
  ./aspm.sh -e
  ```

### Requirements
- **lspci**: The script uses `lspci` to list PCI devices and their capabilities.

### Source
- The script is custom.

---

## `iommu.sh`

### Introduction
The `iommu.sh` script lists all IOMMU groups and their associated devices. This is useful for understanding the IOMMU groupings on a system, which is particularly relevant for virtualization and PCI passthrough configurations.

### Usage
- Simply execute the script to list IOMMU groups and devices:
  ```shell
  ./iommu.sh
  ```

### Requirements
- **lspci**: The script uses `lspci` to display device information.

### Source
- The script is custom.

---

## `enable_aspm.sh`

### Introduction
The `enable_aspm.sh` script is used to enable Active State Power Management (ASPM) on PCI devices. It allows you to specify the PCI endpoint and root complex addresses, as well as the desired ASPM settings.

### Usage
- **Basic Command**:
  ```shell
  ./enable_aspm.sh -e <ENDPOINT> -r <ROOT_COMPLEX> -s <ASPM_SETTING>
  ```
  - `-e ENDPOINT`: PCI endpoint address (e.g., `03:00.0`).
  - `-r ROOT_COMPLEX`: (Optional) PCI root complex address (e.g., `00:1c.4`).
  - `-s ASPM_SETTING`: ASPM setting (0=L0, 1=L0s, 2=L1, 3=L1 and L0s).

### Requirements
- **lspci**: The script uses `lspci` to list PCI devices and their capabilities.
- **bc**: The script uses `bc` for floating-point arithmetic.

### Source
- The script was obtained from [abclution](https://github.com/abclution/enable_aspm_on_device) and is based on a gist by [baybal](https://gist.github.com/baybal/b499fc5811a7073df0c03ab8da4be904) who got it from Luis R. Rodriguez [mcgrof@do-not-panic.com](https://github.com/mcgrof).

---