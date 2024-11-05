#!/bin/bash

# Minimum Neovim version requirement
MIN_NEVIM_VERSION="0.8.0"

# Define paths
KITTY_PATH="$HOME/.local/kitty.app"
PYTHON_REQUIREMENTS="$HOME/scripts/python_requirements.txt"

# Function to compare version numbers
version_ge() {
    [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

# Install system packages with apt and provide comments for each package
install_apt_packages() {
    sudo apt update
    sudo apt install -y \
        python3 \
        python3-dev \
        python3-pip \
        zsh \
        fzf \
        tmux \
        git \
        build-essential \
        cmake \
        ninja-build \
        pkg-config \
        libtool \
        libtool-bin \
        autoconf \
        automake \
        gettext \
        curl
}


# Install Kitty terminal emulator
install_kitty() {
    if ! command -v kitty &> /dev/null; then
        echo "Installing Kitty from binary..."
        curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
        mkdir -p ~/.local/bin
        ln -sf "$KITTY_PATH/bin/kitty" ~/.local/bin/kitty
        ln -sf "$KITTY_PATH/bin/kitten" ~/.local/bin/kitten
    fi
}

# Install Python tools: pip, virtualenv, and virtualenvwrapper
install_python_tools() {
    if ! command -v pip3 &> /dev/null; then
        echo "Installing pip3..."
        sudo apt install -y python3-pip
    fi

    # Ensure requirements.txt for pip packages
    if [ ! -f "$PYTHON_REQUIREMENTS" ]; then
        echo -e "virtualenv\nvirtualenvwrapper\n" > "$PYTHON_REQUIREMENTS"
    fi

    echo "Installing Python packages..."
    pip3 install --user -r "$PYTHON_REQUIREMENTS"
}

# Configure virtualenvwrapper in .zshrc or .bashrc
configure_virtualenvwrapper() {
    for shell_rc in ~/.zshrc ~/.bashrc; do
        if ! grep -q 'WORKON_HOME' "$shell_rc"; then
            echo "Configuring virtualenvwrapper in $shell_rc..."
            {
                echo 'export WORKON_HOME=$HOME/.virtualenvs'
                echo 'export VIRTUALENVWRAPPER_PYTHON=$(which python3)'
                echo 'source $(pip3 show virtualenvwrapper | grep Location | cut -d" " -f2)/virtualenvwrapper.sh'
            } >> "$shell_rc"
        fi
    done
}

# Install tmuxp
install_tmuxp() {
    if ! command -v tmuxp &> /dev/null; then
        echo "Installing tmuxp..."
        pip3 install --user tmuxp
    fi
}

# Install yazi (use the binary from GitHub releases)
install_yazi() {
    if ! command -v yazi &> /dev/null; then
        echo "Installing yazi..."
        curl -L https://github.com/sxyazi/yazi/releases/latest/download/yazi-linux -o ~/.local/bin/yazi
        chmod +x ~/.local/bin/yazi
    fi
}

# Install Docker from the official Docker repository and configure it to run without sudo
configure_docker() {
    # Add Docker's official GPG key and repository
    echo "Configuring Docker repository..."
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker repository based on Ubuntu version
    echo "Adding Docker repository..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    # Install Docker components
    echo "Installing Docker components..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Enable Docker to run without sudo
    if ! groups $USER | grep -q '\bdocker\b'; then
        echo "Configuring Docker to run without sudo..."
        sudo usermod -aG docker $USER
        echo "Please log out and log back in to apply Docker group changes."
    fi
}

# Function to build and install Neovim from source
install_neovim() {
    if ! command -v nvim &> /dev/null || ! version_ge "$(nvim --version | head -n 1 | awk '{print $2}')" "$MIN_NEVIM_VERSION"; then
        echo "Building and installing Neovim from source..."
        git clone https://github.com/neovim/neovim.git /tmp/neovim
        cd /tmp/neovim
        git checkout stable
        make CMAKE_BUILD_TYPE=Release
        cpack -G DEB
        sudo dpkg -i nvim*.deb
        cd -
        rm -rf /tmp/neovim
    else
        echo "Neovim is already installed and meets the version requirement."
    fi
}

# Main function to run all installations
main() {
    install_apt_packages
    install_kitty
    install_python_tools
    configure_virtualenvwrapper
    install_tmuxp
    install_yazi
    configure_docker
    install_neovim
}

main


