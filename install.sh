#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install packages based on distribution
install_packages() {
    local distribution=$1
    shift
    local packages=("$@")

    case $distribution in
        debian|ubuntu)
            sudo apt update
            sudo apt install -y "${packages[@]}"
            ;;
        fedora)
            sudo dnf install -y "${packages[@]}"
            ;;
        arch|endeavouros|manjaro)
            sudo pacman -Syu --needed --noconfirm "${packages[@]}"
            ;;
        *)
            echo "Unsupported distribution: $distribution"
            exit 1
            ;;
    esac
}

# Determine the Linux distribution
get_distribution() {
    if command_exists lsb_release; then
        lsb_release -si | tr '[:upper:]' '[:lower:]'
    elif [ -e /etc/os-release ]; then
        source /etc/os-release
        echo "$ID" | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

# Get GPU info and convert to lower case
GPU=$(lspci | grep -iE "vga")
GPU=$(echo $GPU | tr '[:upper:]' '[:lower:]')

# Output to check
echo "lspci output for VGA device is: $GPU"
echo 
echo "Looping through the device information"

# Loop through the GPU info to identify the GPU
for indices in $GPU; do
    case $indices in
        *radeon*)
            echo "String Radeon found."
            g="AMD Radeon"
            packages_to_install=("radeontop")
            break
            ;;
        *amd/ati*)
            echo "String AMD/ATI found."
            g="AMD ATI"
            packages_to_install=("radeontop")
            break
            ;;
        *intel*)
            echo "String Intel found."
            g="INTEL"
            packages_to_install=("intel-gpu-tools")
            break
            ;;
        *nvidia*)
            echo "String NVIDIA found."
            g="NVIDIA"
            packages_to_install=("nvidia-utils")
            break
            ;;
    esac
done

echo "VGA Device: $g"

# Check and install the required packages for the identified GPU
if [[ ${#packages_to_install[@]} -gt 0 ]]; then
    echo "Installing packages for $g: ${packages_to_install[*]}"
    distribution=$(get_distribution)
    install_packages "$distribution" "${packages_to_install[@]}"
else
    echo "No specific GPU packages to install."
fi

# Install Nerd Fonts
install_nerdfonts() {
    echo "Installing Nerd Fonts..."
    local distribution=$1
    case $distribution in
        debian|ubuntu)
            sudo apt install -y fonts-firacode
            ;;
        fedora)
            sudo dnf install -y fira-code-fonts
            ;;
        arch|endeavouros|manjaro)
            sudo pacman -S --noconfirm --needed ttf-fira-code
            ;;
        *)
            echo "Unsupported distribution: $distribution"
            exit 1
            ;;
    esac
}

# Check for and install Nerd Fonts
echo "Checking for Nerd Fonts..."
if ! fc-list : file family | grep -q "Nerd Font"; then
    distribution=$(get_distribution)
    install_nerdfonts "$distribution"
else
    echo "Nerd Fonts are already installed."
fi

# Install SYSI script
echo "Installing SYSI script..."
sudo cp sysi /usr/local/bin/sysi
sudo chmod +x /usr/local/bin/sysi

echo "SYSI installation completed."
echo "You can now run 'sysi' to display system information."
