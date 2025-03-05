#!/bin/bash

# Initialisation des variables
FichierLogiciel=""
logiciel=()
package_manager=()
type_installation=()
selected=()
empty=true
nb_logiciel=0


# Choix Sauvegarde/Chargement

ChoixSauvegardeChargement() {
    while true; do
        clear
        echo "Choisissez une option :"
        echo "1. Sauvegarder la liste des logiciels"
        echo "2. Charger la liste des logiciels"
        read -p "Votre choix : " choix
        case $choix in
        1)
            SauvegardeCSV
            break
            ;;
        2)
            Chargement
            break
            ;;
        *)
            echo "Choix invalide."
            ;;
        esac
    done
}



# Chargement du fichier CSV
ChargementCSV() {
  if [[ -f $FichierLogiciel ]]; then
      while IFS="," read -r ID Name Category interface; do
          if [[ $ID == "ID" ]]; then
              continue
          else
              logiciel+=("$Name")
              package_manager+=("$Category")
              type_installation+=("$interface")
              (($nb_logiciel++))
          fi
      done < "$FichierLogiciel"
  else
      echo "Erreur : Fichier $FichierLogiciel introuvable."
      exit 1
  fi
}

# Récupération des logiciels installé dans le dossier /Applications dans le fichier csv
RecuperationLogicielInstalle() {
  while true ; do
    clear
    echo "Entrer le nom du fichier à creer : "
    read -r fichierName
    if [[ -f "$fichierName.csv" ]]; then
      echo "Le fichier existe déjà"
    else
      touch "$fichierName.csv"
      break
    fi
  done
  echo "ID,Name,Category,interface" > "$fichierName.csv"
  nb_application=0
  for application in /Applications/*; do
    if [[ -d "$application" ]]; then
      applicationName=$(basename "$application")
      echo "Ajout de $applicationName dans le fichier $fichierName.csv"
      # on remplace les espaces par des -
      applicationName=$(echo "$applicationName" | sed 's/ /-/g')
      echo "$nb_application,$applicationName,brew,cask" >> "$fichierName.csv"

      logiciel+=("$applicationName")
      package_manager+=("brew")
      type_installation+=("cask")
      selected[$nb_logiciel]=0
      ((nb_application++))
    fi
  done


}

# Choix du csv
ChoixFichier() {
  local index=0
    while true; do
        clear
        echo "Choisissez le fichier CSV contenant les logiciels à installer :"
        echo "Naviguez : ↑ ↓"
        echo "continuer : Q"
        echo "------------------------------------------------------"
        i=0
        for fichier in *.csv; do
          if [[ $i -eq $index ]]; then
            echo -n " > "
            FichierLogiciel="$fichier"
          else
            echo -n "   "
          fi

            echo "$i. $fichier"
            ((i++))
        done
        echo "------------------------------------------------------"
        # Lire une touche
        read -rsn1 key
        case $key in
        $'\x1b') # flèche commence par ça 
            read -rsn2 key # Lire les deux caractères suivants
            case $key in
            '[A') ((index--)); [[ $index -lt 0 ]] && index=$((${#fichiers[@]} - 1)) ;;
            '[B') # Flèche bas
                ((index++))
                if [[ $index -ge $i ]]; then index=0; fi
                ;;
            esac
            ;;
        q|Q|"")# Continuer 
            break
            ;;
        esac
    done
}


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
        echo "Ajouter un logiciel manuellement: M"
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
        $'\x1b') # flèche commence par ça 
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
            for i in "${!selected[@]}"; do
                if [[ ${selected[$i]} -eq 1 ]]; then
                    empty=false
                    break
                fi
            done
            break
            ;;
        a|A) # Tout sélectionner
            for i in "${!logiciel[@]}"; do
                selected[$i]=1
            done
            ;;
        d|D) # Tout désélectionner
            for i in "${!selected[@]}"; do
                selected[$i]=0
            done
            ;;
        m|M) # ajouter manuellement
            read -p "Entrez le nom du logiciel : " nom
            logiciel+=("$nom")
            echo "Selectionner le gestionnaire de paquet :"
            SelectManager
            #selection le dernier element du tableau
            selected[nb_logiciel]=1
            ((nb_logiciel++))
            ;;


        esac
    done
}


SelectManager() {

    while true; do
        clear
        echo "Sélectionner le gestionnaire de paquet :"
        echo "1. Homebrew"
        echo "2. npm"
        echo "3. pip3"
        read -p "Votre choix : " choix
        case $choix in
        1)
            package_manager+=("brew")
            break
            ;;
        2)
            package_manager+=("npm")
            break
            ;;
        3)
            package_manager+=("pip3")
            break
            ;;
        *)
            echo "Choix invalide."
            ;;
        esac
    done
    if [[ $choix -eq 1 ]]; then
        while true; do
            clear
            echo "Sélectionner le type d'installation :"
            echo "1. Cask"
            echo "2. CLI"
            read -p "Votre choix : " choix
            case $choix in
            1)
                type_installation+=("cask")
                break
                ;;
            2)
                type_installation+=("cli")
                break
                ;;
            *)
                echo "Choix invalide."
                ;;
            esac
        done
    else
        type_installation+=("cli")
    fi


    
}


# Fonction pour installer les logiciels sélectionnés
Installation() {
    if [[ $empty == true ]]; then
        echo "Aucun programme sélectionné."
    else
        echo "Installation des programmes sélectionnés..."
        for i in "${!logiciel[@]}"; do
            if [[ ${selected[$i]} -eq 0 ]]; then
                continue
            else
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
                
                pip3)
                    if [[ $type == "cli" ]]; then
                        pip3 install "$logiciel_a_installer"
                    fi
                    ;;
                *)
                    echo "Gestionnaire de paquets inconnu : $manager"
                    ;;
                esac
            fi
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
            brew install python3
            ;;
        [nN]) return ;;
        *) echo "Veuillez répondre par O ou N." ;;
    esac
}
# Installation de Node.js et npm
installNode() {
    if ! command -v npm &>/dev/null; then
        echo "Node.js et npm ne sont pas installés. Installation en cours..."
        if command -v brew &>/dev/null; then
            brew install node
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

SauvegardeCSV() {
  RecuperationLogicielInstalle
}

Chargement() {
  installHomebrew
  installNode
  ChoixFichier
  ChargementCSV
  menu_interactif
  Installation
  installYabai
}

ChoixSauvegardeChargement
