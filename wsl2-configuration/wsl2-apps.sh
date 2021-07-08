#!/bin/bash

#-- Root check --#
if ! [ $(id -u) = 0 ]; then
   echo "The script need to be run as root." >&2
   exit 1
fi

if [ $SUDO_USER ]; then
    real_user=$SUDO_USER
else
    real_user=$(whoami)
fi

#-- Colours --#
RST='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'

#-- Functions --#
install_bash() {
    export default_rc=/home/$real_user/.bashrc
    notify+=("${GREEN}Bash: Configuration added to .bashrc, to make bash your default shell, run 'chsh' and select bash, then restart your shell${RST}")
}

install_zsh() {
    apt-get install -yq --no-install-recommends zsh
    sudo -u $real_user sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    export default_rc=/home/$real_user/.zshrc
    notify+=("${GREEN}Zsh: Zsh has been installed, to make Zsh your default shell, run 'chsh' and select Zsh, then restart your shell${RST}")
}

select_shell() {
    PS3='Select shell to use:'
    options=("bash" "zsh" "Quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "bash")
                #FIXME: Find a better way to check if this exists
                shell=$(awk -F: -v user=$real_user '$1 == user {print $NF}' /etc/passwd | grep -o bash)
                bash_path=$(which bash)
                if [ "$shell" == "bash" ]; then
                    echo -e "${YELLOW}Default shell is already bash${RST}"
                    sleep 2
                else
                    install_bash
                fi

                break
                ;;
            "zsh")
                #FIXME: Find a better way to check if this exists
                shell=$(awk -F: -v user=$real_user '$1 == user {print $NF}' /etc/passwd | grep -o zsh)
                zsh_path=$(which zsh)
                if [ "$shell" == "zsh" ]; then
                    echo -e "${YELLOW}Default shell is already zsh${RST}"
                    sleep 2
                else
                    install_zsh
                fi

                break
                ;;
            "Quit")
                break
                ;;
            *) echo -e "${RED}Invalid option${RST}";;
        esac
    done
}

confirm_update() {
    read -p "This script will run a series of 'apt install', would you like run an 'apt update' first? [Y/n]" -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "Updating..."
        apt-get -y update &> /dev/null
        echo "Done"
        sleep 1
    fi
}

install_default() {
    echo "Currently about to install the following:"
    echo "  - Azure CLI"
    echo "  - Terraform"
    echo "  - Docker Compose"
    read -p "Confirm Execution? [Y/n]" -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        # Azure CLI
        if ! command -v az &> /dev/null
        then
            curl -sL https://aka.ms/InstallAzureCLIDeb | bash
            az --version
        else
            echo -e "${YELLOW}Azure CLI already exists${RST}"
            az --version
        fi

        # Terraform
        if ! command -v terraform &> /dev/null
        then
            curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
            apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
            apt-get install -yq --no-install-recommends terraform
            terraform --version
        else
            echo -e "${YELLOW}Terraform already exists${RST}"
            terraform --version
        fi

        # Docker Compose
        if ! command -v docker-compose &> /dev/null
        then
            curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
            docker-compose --version
        else
            echo -e "${YELLOW}Docker Compose already exists${RST}"
            docker-compose --version
        fi
    fi
}

install_trueline() {
    if [ "$default_rc" == "/home/$real_user/.zshrc" ]; then
        notify+=("${RED}Trueline: Cannot install Trueline for zsh, only bash${RST}")
    elif [ "$default_rc" == "/home/$real_user/.bashrc" ]; then
        echo "trueline"

        if [[ -d /home/$real_user/.config/trueline ]]
        then
            notify+=("${RED}Trueline already exists${RST}")
        else
            [[ ! -d /home/$real_user/.config ]] && sudo -u $real_user mkdir /home/$real_user/.config
            sudo -u $real_user git clone https://github.com/petobens/trueline /home/$real_user/.config/trueline
            sudo -u $real_user echo "# Trueline Config" >> $default_rc
            sudo -u $real_user echo 'source ~/.config/trueline/trueline.sh' >> $default_rc
            sudo -u $real_user echo >> $default_rc
            notify+=("${GREEN}Trueline: ${YELLOW}Make sure to configure your fonts for Trueline${RST}")
        fi
    fi

}

install_fzf() {
    echo "fzf"
    if ! command -v fzf &> /dev/null
    then
        apt-get install -yq --no-install-recommends fzf
        sudo -u $real_user echo "# FZF Config" >> $default_rc
        sudo -u $real_user echo "FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'" >> $default_rc
        sudo -u $real_user echo >> $default_rc
        notify+=("${GREEN}FZF: ${YELLOW}Make sure to configure your key bindings and completion for fzf${RST}")
        fzf --version
    else
        notify+=("${YELLOW}fzf already exists${RST}")
        fzf --version
    fi
}

install_batcat() {
    echo "bat"
    if ! command -v batcat &> /dev/null
    then
        apt-get install -yq --no-install-recommends bat
        sudo -u $real_user echo "# Bat Config" >> $default_rc
        sudo -u $real_user echo "alias bat='batcat'" >> $default_rc
        sudo -u $real_user echo >> $default_rc
        batcat --version
    else
        notify+=("${YELLOW}bat already exists${RST}")
        batcat --version
    fi
}

install_lsd() {
    echo "lsd"
    if ! command -v lsd &> /dev/null
    then
        curl -Lo /tmp/lsd.deb https://github.com/Peltoche/lsd/releases/download/0.20.1/lsd_0.20.1_amd64.deb
        dpkg -i /tmp/lsd.deb
        rm /tmp/lsd.deb
        sudo -u $real_user echo "# LSD Config" >> $default_rc
        sudo -u $real_user echo "alias ls='lsd'" >> $default_rc
        sudo -u $real_user echo "alias l='ls -l'" >> $default_rc
        sudo -u $real_user echo "alias la='ls -a'" >> $default_rc
        sudo -u $real_user echo "alias lla='ls -la'" >> $default_rc
        sudo -u $real_user echo "alias lt='ls --tree'" >> $default_rc
        sudo -u $real_user echo >> $default_rc
        lsd --version
        echo
        notify+=("${GREEN}LSD: The following aliases have been assigned${RST}")
        notify+=("${GREEN}LSD: ls, l, la, lla, lt${RST}")
        sleep 2
    else
        notify+=("${YELLOW}lsd already exists${RST}")
        lsd --version
    fi
}

install_pet() {
    echo "pet"
    if ! command -v pet &> /dev/null
    then
        wget -O /tmp/pet.deb https://github.com/knqyf263/pet/releases/download/v0.3.0/pet_0.3.0_linux_amd64.deb
        dpkg -i /tmp/pet.deb
        rm /tmp/pet.deb
        pet version
        notify+=("${GREEN}Pet: Run 'pet configure' to set up pet or just 'pet' to view options${RST}")
    else
        notify+=("${YELLOW}pet already exists${RST}")
        pet version
    fi
}

install_jq() {
    echo "jq"
    if ! command -v jq &> /dev/null
    then
        apt-get install -yq --no-install-recommends jq
        jq --version
    else
        notify+=("${YELLOW}jq already exists"${RST})
        jq --version
    fi
}

install_yq() {
    echo "yq"
    if ! command -v yq &> /dev/null
    then
        wget https://github.com/mikefarah/yq/releases/download/v4.9.6/yq_linux_amd64 -O /usr/bin/yq
        chmod +x /usr/bin/yq
        yq --version
    else
        notify+=("${YELLOW}yq already exists"${RST})
        yq --version
    fi
}


bash_tools_install() {
    #Menu function
    function MENU {
        echo "Menu Options"
        for NUM in ${!options[@]}; do
            echo "[""${choices[NUM]:- }""]" $(( NUM+1 ))") ${options[NUM]}"
        done
        echo "$ERROR"
    }

    # Install shell tools
    # Menu options
    options[0]="trueline - Bash powerline style prompt with colours"
    options[1]="fzf      - A general purpose command-line fuzzy finder"
    options[2]="batcat   - A 'cat' clone with syntax highlighting and Git integration"
    options[3]="lsd      - A colour coded file listing command"
    options[4]="pet      - (Requires fzf) Command line snippet manager with Git integration"
    options[5]="jq + yq  - A 'sed' for JSON and YAML"


    # Variables
    ERROR=" "

    #Clear screen for menu
    clear
    echo "Install Shell Tool Selector"

    # Menu loop
    while MENU && read -e -p "Select the desired options using their number (again to uncheck, ENTER when done): " -n1 SELECTION && [[ -n "$SELECTION" ]]; do
        clear
        if [[ "$SELECTION" == *[[:digit:]]* && $SELECTION -ge 1 && $SELECTION -le ${#options[@]} ]]; then
            (( SELECTION-- ))
            if [[ "${choices[SELECTION]}" == "+" ]]; then
                choices[SELECTION]=""
            else
                choices[SELECTION]="+"
            fi
                ERROR=" "
        else
            ERROR="Invalid option: $SELECTION"
        fi
    done

    # Process Selections
    if [[ ${choices[0]} ]]; then
        install_trueline
        echo
    fi
    if [[ ${choices[1]} ]]; then
        install_fzf
        echo
    fi
    if [[ ${choices[2]} ]]; then
        install_batcat
        echo
    fi
    if [[ ${choices[3]} ]]; then
        install_lsd
        echo
    fi
    if [[ ${choices[4]} ]]; then
        install_pet
        echo
    fi
    if [[ ${choices[5]} ]]; then
        install_jq
        install_yq
        echo
    fi
}

print_notify() {
    arr=("$@")
    for str in "${arr[@]}";
    do
        echo -e "$str"
    done
}


## -- BEGIN SCRIPT -- ##
notify=()

#-- Confirmation --#
confirm_update
clear

select_shell
clear

set -e
install_default
bash_tools_install
clear

print_notify "${notify[@]}"

echo
echo "Installation successful! Please restart your shell for changes to take effect"
exit 0
