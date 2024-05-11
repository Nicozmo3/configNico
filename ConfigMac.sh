#!/bin/bash

logiciel=("wget" "git" "tree" "htop" "discord" "iterm2" "MonitorControl" "Nextcloud" "Ollama" "Plex" "python" "qbittorrent" "telegram" "TextMate" "Tor-browser" "whatsapp" "wireshark" "visual-studio-code" "balenaetcher" "prismlauncher")
logiciel_deselectionner=()

Installation() {
    echo "Installation des programmes sélectionnés..."
    for index in "${selection_indices[@]}"; do
        echo "Installation de ${logiciel[$index]}"
        if [ "${logiciel[$index]}" == "" ]; then
            :
        elif [ "${logiciel[$index]}" == "ollama" ] || [ "${logiciel[$index]}" == "qbittorrent" ] || [ "${logiciel[$index]}" == "wireshark" ]; then
            brew install --cask "${logiciel[$index]}"
        else
            brew install "${logiciel[$index]}"
        fi
    done
    echo "Installation terminée."
}

menu() {
    echo "Déselectionné des programmes (x pour aucun et a pour tout déselectionner):"
    PS3="Votre choix : "
    while true; do
        select program in "${logiciel[@]}"; do
            case $REPLY in
                [0-9]*)
                    index=$((REPLY-1))
                    if [[ "${selection_indices[index]}" ]]; then
                        unset selection_indices[index]
                        logiciel_deselectionner+=("${logiciel[index]}")
                        logiciel=(${logiciel[@]:0:$index} ${logiciel[@]:$(($index + 1))})
                        if [[ ${#logiciel_deselectionner[@]} -gt 0 ]]; then
                            last_index=${#logiciel_deselectionner[@]}-1
                            echo "${logiciel_deselectionner[last_index]} retiré de la sélection."
                        fi
                    fi
                    break
                    ;;
                [xX])
                    echo "Aucun programme n'a été retiré."
                    echo "Sortie du menu."
                    break 2
                    ;;
                [aA]) 
                    logiciel_deselectionner=("${logiciel[@]}")
                    selection_indices=()
                    logiciel=()
                    echo "Tous les programmes ont été retirés."
                    break 2
                    ;;
                [qQ])
                    echo "Sortie du menu."
                    break 2
                    ;;
                *)
                    echo "Sélection invalide." ;;
            esac
        done
    done
    echo "Programmes désélectionnés : ${logiciel_deselectionner[@]}"
}

installHomebrew(){
    read -p "Voulez-vous installer HomeBrew ? (O/N) : " choix
    case $choix in
            [oO]) 
                if [[ $(uname -m) == "arm64" ]]; then
                    
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                    echo "Mac sous apple silicon : "
                    echo "Installation de Rosetta 2"
                    softwareupdate --install-rosetta --agree-to-license
                    echo 'eval $(/opt/homebrew/bin/brew shellenv)' >> $HOME/.zprofile
                else
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                fi
                ;;
            [nN]) return ;;
            *) echo "Veuillez répondre par O ou N." ;;
    esac
}
installYabai(){
    read -p "Voulez-vous installer Yabai ? (O/N) : " choix
    case $choix in
            [oO]) brew install koekeishiya/formulae/yabai 
                brew install koekeishiya/formulae/skhd
                mkdir ~/tempyabaiskhdconfig
                cd ~/tempyabaiskhdconfig
                git clone https://github.com/Nicozmo3/configNico.git
                mkdir -p ~/.config/yabai
                mkdir -p ~/.config/skhd
                cp ~/tempyabaiskhdconfig/configNico/yabairc ~/.config/yabai/yabairc
                cp ~/tempyabaiskhdconfig/configNico/skhdrc ~/.config/skhd/skhdrc
                rm -rf ~/tempyabaiskhdconfig
                yabai --start-service
                skhd --start-service
                read -p "appuyer sur o quand vous avez activé yabai : " choix
                    case $choix in
                    [oO]) : ;;
                    *) echo "Veuillez appuyer sur o" ;;
                    esac
                echo "Installation de Yabai terminée"
                yabai --start-service
                skhd --start-service
            
            ;;
            [nN]) break ;;
            *) echo "Veuillez répondre par O ou N." ;;
    esac


}
installHomebrew

for ((i=0; i<${#logiciel[@]}; i++)); do
    selection_indices[$i]=$i
done

while true; do
    menu
    read -p "Voulez-vous retirer un autre programme ? (O/N) : " choix
    case $choix in
        [oO]) continue ;;
        [nN]) break ;;
        *) echo "Veuillez répondre par O ou N." ;;
    esac
done

Installation
installYabai

