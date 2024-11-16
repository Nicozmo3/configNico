#!/bin/bash

# Initialisation des variables
FichierLogiciel="choixLogiciel.csv"
logiciel=()
package_manager=()
type_installation=()

# Chargement du fichier CSV
if [[ -f $FichierLogiciel ]]; then
    while IFS="," read -r ID Name PackageManager Type; do
        if [[ $ID == "ID" ]]; then
            continue
        else
            logiciel+=("$Name")
            package_manager+=("$PackageManager")
            type_installation+=("$Type")
        fi
    done < "$FichierLogiciel"
else
    echo "Erreur : Fichier $FichierLogiciel introuvable."
    exit 1
fi

menu_interactif() {
    local index=0
    local key

    while true; do
        # Afficher la liste des logiciels avec leur état sélectionné [x] ou non [ ]
        clear
        echo "Naviguez : ↑ ↓"
        echo "Sélectionnez : Entrée"
        echo "Tous sélectionner : A"
        echo "Tous désélectionner : D"
        echo "continuer : Q"
        echo "------------------------------------------------------"
        for i in "${!logiciel[@]}"; do
            if [[ $i -eq $index ]]; then
                # Indiquer la ligne actuelle
                echo -n " > "
            else
                echo -n "   "
            fi

            # Afficher si le logiciel est sélectionné ou non
            if [[ ${selected[$i]} -eq 1 ]]; then
                echo "[x] ${logiciel[$i]}"
            else
                echo "[ ] ${logiciel[$i]}"
            fi
        done
        echo "------------------------------------------------------"

        # Lire une touche
        read -rsn1 key
        case $key in
        $'\x1b') # Détecter les flèches (séquence commence par ESC)
            read -rsn2 key # Lire les deux caractères suivants
            case $key in
            '[A') # Flèche haut
                ((index--))
                if [[ $index -lt 0 ]]; then index=$((${#logiciel[@]} - 1)); fi
                ;;
            '[B') # Flèche bas
                ((index++))
                if [[ $index -ge ${#logiciel[@]} ]]; then index=0; fi
                ;;
            esac
            ;;
        "") # Touche Entrée
            if [[ ${selected[$index]} -eq 1 ]]; then
                selected[$index]=0  # Désélectionner
            else
                selected[$index]=1  # Sélectionner
            fi
            ;;
        q|Q) # Quitter
            break
            ;;
        a|A) # Tout sélectionner
            for i in "${!selected[@]}"; do
                selected[$i]=1
            done
            ;;
        d|D) # Tout désélectionner
            for i in "${!selected[@]}"; do
                selected[$i]=0
            done
            ;;

        esac
    done
}


# Fonction pour installer les logiciels sélectionnés
Installation() {
    if [[ ${logiciel[0]} == null ]]; then
        echo "Aucun logiciel à installer."
        return
    else
        echo "Installation des programmes sélectionnés..."
        for i in "${!logiciel[@]}"; do
            logiciel_a_installer="${logiciel[$i]}"
            manager="${package_manager[$i]}"
            type="${type_installation[$i]}"

            echo "Installation de $logiciel_a_installer avec $manager ($type)..."
            
            case $manager in
            brew)
                if [[ $type == "cask" ]]; then
                    brew install --cask "$logiciel_a_installer"
                elif [[ $type == "cli" ]]; then
                    brew install "$logiciel_a_installer"
                fi
                ;;
            npm)
                if [[ $type == "cli" ]]; then
                    npm install -g "$logiciel_a_installer"
                fi
                ;;
            *)
                echo "Gestionnaire de paquets inconnu : $manager"
                ;;
            esac
        done
        echo "Installation terminée."
    fi
    
}



# Installation de Homebrew
installHomebrew() {
    read -p "Voulez-vous installer HomeBrew ? (O/N) : " choix
    case $choix in
        [oO])
            if [[ $(uname -m) == "arm64" ]]; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                echo "Mac sous Apple Silicon détecté. Installation de Rosetta 2..."
                softwareupdate --install-rosetta --agree-to-license
                echo 'eval $(/opt/homebrew/bin/brew shellenv)' >> "$HOME/.zprofile"
            else
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            ;;
        [nN]) return ;;
        *) echo "Veuillez répondre par O ou N." ;;
    esac
}
installNode() {
    if ! command -v npm &>/dev/null; then
        echo "Node.js et npm ne sont pas installés. Installation en cours..."
        if command -v brew &>/dev/null; then
            brew install node
            bre
        else
            echo "Veuillez installer Node.js et npm manuellement ou via un autre gestionnaire de paquets."
            exit 1
        fi
        echo "Node.js et npm installés avec succès."
    else
        echo "Node.js et npm sont déjà installés."
    fi
}


# Installation de Yabai
installYabai() {
    read -p "Voulez-vous installer Yabai ? (O/N) : " choix
    case $choix in
        [oO])
            brew install koekeishiya/formulae/yabai 
            brew install koekeishiya/formulae/skhd
            mkdir -p ~/tempyabaiskhdconfig ~/.config/yabai ~/.config/skhd
            cd ~/tempyabaiskhdconfig
            git clone https://github.com/Nicozmo3/configNico.git
            cp configNico/yabairc ~/.config/yabai/yabairc
            cp configNico/skhdrc ~/.config/skhd/skhdrc
            cd ~ && rm -rf ~/tempyabaiskhdconfig
            yabai --start-service
            skhd --start-service
            echo "Installation de Yabai terminée."
            ;;
        [nN]) return ;;
        *) echo "Veuillez répondre par O ou N." ;;
    esac
}

# Initialisation
installHomebrew
installNode
# Exécution du menu interactif
menu_interactif

# Installation des logiciels sélectionnés
Installation

installYabai
