#!/bin/bash

### Variable
script_name=$(basename $0 | cut -d'.' -f1)
script_name_cap=${script_name^^}
script_name_full=$(basename $0)
script_bin=$0
script_conf="$HOME/.config/$script_name/$script_name.conf"
script_remote="https://raw.githubusercontent.com/Z0uZOU/$script_name/main/$script_name_full"
script_folder="$HOME/.config/$script_name"
if [[ ! -d "$script_folder" ]]; then mkdir -p "$script_folder"; fi
if [[ ! -d "$script_folder/logs" ]]; then mkdir -p "$script_folder/logs"; fi
date_log=$(date +%Y-%m-%d)
logfile_pushover="$script_folder/logs/pushover.log"
logfile_lftp="$script_folder/logs/${date_log}_lftp.log"
logfile_display="$script_folder/logs/${date_log}_display.log"
logfile_display_cmd="| tee -a $logfile_display"
dependencies="curl lftp"


## Check if this script is running
exec 200>/tmp/${script_name}.lock
flock -n 200 || { echo "Script déjà en cours d'exécution"; exit 1; }


## Fix printf special char issue
Lengh1="55"
Lengh2="61"
lon() ( echo $(( Lengh1 + $(wc -c <<<"$1") - $(wc -m <<<"$1") )) )
lon2() ( echo $(( Lengh2 + $(wc -c <<<"$1") - $(wc -m <<<"$1") )) )


## UI tags
ui_tag_ok="✅"
ui_tag_bad="❌"
ui_tag_warning="⚠️"
ui_tag_section="\e[44m[\u2263\u2263\u2263]\e[0m \e[44m \e[1m %-*s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n"


## Argument parser
while getopts ceuhr:l:-: OPT; do
  if [ "$OPT" = "-" ]; then
    OPT="${OPTARG%%=*}"
    OPTARG="${OPTARG#$OPT}"
    OPTARG="${OPTARG#=}" 
  fi
  case "$OPT" in
    c | check-config )
            printf "\e[46m\u23E5\u23E5   \e[0m \e[46m \e[1m %-61s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" "$script_name_cap"
            executed_date=$(date)
            printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
            echo -e "\033[1m$script_name_cap - Vérification de la configuration\033[0m"
            source "$script_conf"
            echo ""
            config_ok=true
            if [[ -z "$LOGIN" ]]; then echo "$ui_tag_bad LOGIN manquant"; config_ok=false; else echo "$ui_tag_ok LOGIN : $LOGIN"; fi
            if [[ -z "$PASSWORD" ]]; then echo "$ui_tag_bad PASSWORD manquant"; config_ok=false; else echo "$ui_tag_ok Mot de passe renseigné"; fi
            if [[ -z "$HOST" ]]; then echo "$ui_tag_bad HOST manquant"; config_ok=false; else echo "$ui_tag_ok Hôte FTP : $HOST"; fi
            if [[ -z "$REMOTEDIR" ]]; then echo "$ui_tag_bad REMOTEDIR manquant"; config_ok=false; else echo "$ui_tag_ok Dossier distant : $REMOTEDIR"; fi
            if [[ -z "$LOCALDIR" ]]; then echo "$ui_tag_bad LOCALDIR manquant"; config_ok=false; else echo "$ui_tag_ok Dossier local : $LOCALDIR"; fi
            echo ""
            if [[ "$config_ok" == false ]]; then
              echo -e "\033[1;31mLa configuration est incomplète\033[0m"
              echo ""
              executed_date=$(date)
              printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
              exit 1
            else
              echo -e "\033[1;32mLa configuration est complète\033[0m"
              echo ""
              executed_date=$(date)
              printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
              exit 0
            fi
            ;;
    h | help )
            printf "\e[46m\u23E5\u23E5   \e[0m \e[46m \e[1m %-61s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" "$script_name_cap"
            executed_date=$(date)
            printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
            echo -e "\033[1m$script_name_cap - aide\033[0m"
            echo ""
            echo "Utilisation : $script_bin [option]"
            echo ""
            echo "Options disponibles:"
            echo "[value*] signifie un argument facultatif"
            echo ""
            echo " -h or --help                              : ce menu d'aide"
            echo " -u or --update                            : mise à jour du script"
            echo " -r [value] or --remote=[value]            : dossier distant"
            echo " -l [value] or --local=[value]             : dossier local"
            echo " -e [value*] or --edit-config=[value*]     : édition du fichier de configuration (défaut: nano)"
            echo ""
            executed_date=$(date)
            printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
            exit 0
            ;;
    u | update )
            printf "\e[46m\u23E5\u23E5   \e[0m \e[46m \e[1m %-61s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" "$script_name_cap"
            executed_date=$(date)
            printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
            echo -e "\033[1m$script_name_cap - Mise à jour lancée\033[0m"
            read -n 1 -p "Voulez-vous continuer [o/N]:" yn
            printf "\r                                                     "
            if [[ "${yn}" == @(o|O) ]]; then
              echo ""
              this_script=$(realpath -s "$0")
              echo "Emplacement du script : "$this_script
              if curl -m 2 --head --silent --fail "$script_remote" 2>/dev/null >/dev/null; then
                echo "Script disponible en ligne sur GitHub"
                md5_local=`md5sum "$this_script" | cut -f1 -d" " 2>/dev/null`
                md5_remote=`curl -s "$script_remote" | md5sum | cut -f1 -d" "`
                echo "MD5 local  : "$md5_local
                echo "MD5 remote : "$md5_remote
                if [[ "$md5_local" != "$md5_remote" ]]; then
                  echo "Une nouvelle version du script est disponible... Téléchargement en cours"
                  curl -s -m 3 --create-dir -o "$this_script" "$script_remote"
                  echo "Mise à jour terminée..."
                else
                  echo "Le script est à jour..."
                fi
              else
                echo ""
                echo "Script hors ligne"
              fi
            else
              echo ""
              echo "Rien n'a été fait"
            fi
            echo ""
            executed_date=$(date)
            printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
            exit 0
            ;;
    r | remote )
            needs_arg
            REMOTEDIR="$OPTARG"
            if [[ -f "$script_conf" ]]; then
              sed -i 's|REMOTEDIR=.*|REMOTEDIR="'$REMOTEDIR'"|' $script_conf
            fi
            ;;
    l | local )
            needs_arg
            LOCALDIR="$OPTARG"
            if [[ -f "$script_conf" ]]; then
              sed -i 's|LOCALDIR=.*|LOCALDIR="'$LOCALDIR'"|' $script_conf
            fi
            ;;
    e | edit-config )
            eval next_arg=\${$OPTIND}
            if [[ "$next_arg" == "" ]]; then
              printf "\e[46m\u23E5\u23E5   \e[0m \e[46m \e[1m %-61s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" "$script_name_cap"
              executed_date=$(date)
              printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
              echo -e "\033[1m$script_name_cap - éditeur de configuration\033[0m"
              echo ""
              echo "Pas d'éditeur spécifié, utilisation par défaut (nano)"
              nano "$script_conf"
              source "$script_conf"
              section_title="Test de connexion au FTP"
              printf "$ui_tag_section" $(lon2 "$section_title") "$section_title"
              lftp -u "$LOGIN","$PASSWORD" "$HOST" -e "ls $REMOTEDIR; bye" >/dev/null 2>&1
              if [[ $? -ne 0 ]]; then
                echo -e "$ui_tag_bad Connexion echouée: LOGIN et/ou PASSWORD incorect(s)"
              else
                echo -e "$ui_tag_ok Connexion OK"
              fi
              echo ""
              executed_date=$(date)
              printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
              exit 0
            else
              echo -e "\033[1m$script_name_cap - éditeur de configuration\033[0m"
              echo ""
              if command -v $next_arg ; then
                echo "Édition du fichier avec: $next_arg"
                $next_arg "$script_conf"
                source "$script_conf"
                section_title="Test de connexion au FTP"
                printf "$ui_tag_section" $(lon2 "$section_title") "$section_title"
                lftp -u "$LOGIN","$PASSWORD" "$HOST" -e "ls $REMOTEDIR; bye" >/dev/null 2>&1
                if [[ $? -ne 0 ]]; then
                  echo -e "$ui_tag_bad Connexion echouée: LOGIN et/ou PASSWORD incorect(s)"
                else
                  echo -e "$ui_tag_ok Connexion OK"
                fi
              else
                echo "Il n'existe aucun logiciel appelé \"$next_arg\" installé"
              fi
              echo ""
              executed_date=$(date)
              printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
              exit 0
            fi
            ;;
    ??* )          die "Illegal option --$OPT" ;;  # bad long option
    ? )            exit 2 ;;  # bad short option (error reported via getopts)
  esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list


## Push feature
push-message() {
  push_title=$1
  push_content=$2
  push_priority=$3
  if [[ "$push_priority" == "" ]]; then
    push_priority="-1"
  fi
  for user in {1..10}; do
    target=`eval echo "\\$target_"$user`
    if [ -n "$target" ]; then
      curl -s \
        --form-string "token=$token_app" \
        --form-string "user=$target" \
        --form-string "title=$push_title" \
        --form-string "message=$push_content" \
        --form-string "html=1" \
        --form-string "priority=$push_priority" \
        https://api.pushover.net/1/messages.json > /dev/null
    fi
  done
}


## Function to display download progress
function downloading_loading() {
  pid="$*"
  previous_folder=""
  previous_file=""
  spin='⣾⣽⣻⢿⡿⣟⣯⣷'
  i=0
  tput civis # cursor invisible
  mon_printf="\r                                                                             "
  while kill -0 "$pid" 2>/dev/null; do
    if [[ -f "$logfile_lftp" ]]; then
      folder=$(grep "CWD path to be sent is" "$logfile_lftp" | tail -1 | sed -E 's/.*CWD path to be sent is .(.+).$/\1/')
      if [[ "$folder" != "$previous_folder" ]]; then
        previous_folder=$folder
      fi
      file=$(grep " RETR " "$logfile_lftp" | tail -1 | sed 's/.*RETR //')
      if [[ "$file" != "$previous_file" ]]; then
        previous_file=$file
        printf "\r\n"
      fi
      folder_line=$(grep -n "$folder" "$logfile_lftp" | tail -1 | cut -d: -f1)
      file_line=$(grep -n "$file" "$logfile_lftp" | tail -1 | cut -d: -f1)
      if [[ $folder_line -gt $file_line ]]; then
        file=""
      fi
      if [[ -n "$folder" && -n "$file" ]]; then
        i=$(((i+1) % ${#spin}))
        if [[ "${#folder} + ${#file}" -gt "65" ]]; then
          print_file=$(echo "${folder: -20}/$file" | sed "s:[^/]*/:.../:")
        else
          print_file="$folder/$file"
        fi
        file_path="$LOCALDIR$folder/$file"
        if [[ -f "$file_path" ]]; then
          file_size=$(stat -c%s "$file_path")
          file_size=$(numfmt --to=iec "$file_size")
        else
          file_size=""
        fi
        log_line_prefix="Téléchargement de $folder/$file"
        log_line_full=" ${spin:$i:1} $log_line_prefix $file_size"
        if grep -qF "$log_line_prefix" "$logfile_display"; then
          sed -i "s|.*$log_line_prefix.*|$log_line_full|" "$logfile_display"
        else
          echo "$log_line_full" >> $logfile_display
          if [[ ! -e "$logfile_pushover" ]]; then
            echo -e "<b>Téléchargement de :</b>" > $logfile_pushover
          fi
          echo -e $folder/$file >> $logfile_pushover
        fi
        printf "\r ${spin:$i:1} Téléchargement de $print_file $file_size    "
        sleep 0.1
      fi
    fi
  done
  tput cnorm
  printf "$mon_printf" && printf "\r"
}

## Automatic file renaming function if existing
rename_if_exists() {
    local file="$1"

    if [[ ! -e "$file" ]]; then
        return 1
    fi

    local dir=$(dirname "$file")
    local filename=$(basename "$file")
    local base="${filename%.*}"
    local ext="${filename##*.}"

    if [[ "$base" == "$filename" ]]; then
        ext=""
    fi

    local counter=1
    local newfile="$file"

    while [[ -e "$newfile" ]]; do
        if [[ -z "$ext" || "$filename" == "$ext" ]]; then
            newfile="${dir}/${base}.${counter}"
        else
            newfile="${dir}/${base}.${counter}.${ext}"
        fi
        ((counter++))
    done

    mv "$file" "$newfile"
}
rename_if_exists "$logfile_display"
rename_if_exists "$logfile_lftp"


eval 'printf "\e[46m\u23E5\u23E5   \e[0m \e[46m \e[1m %-61s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" "$script_name_cap"' $logfile_display_cmd
executed_date=$(date)
eval 'printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd


### Configuration file
if [[ ! -f "$script_conf" ]]; then
  eval 'echo -e "$ui_tag_warning Fichier de conf absent, création du fichier de conf"' $logfile_display_cmd
  touch "$script_conf"
  chmod 600 "$script_conf"
cat <<EOT >> "$script_conf"
####################################
## Configuration
####################################
 
##### Paramètres
## Dossier distant
REMOTEDIR="$REMOTEDIR"
## Dossier local
LOCALDIR="$LOCALDIR"
## Adresse du FTP
HOST="ged.interway.fr"
## Paramètres de connexion
LOGIN=""
PASSWORD=""
DELETEUSELESSFILES="yes"
EXCLUDED="-x Thumbs.db -x 'Licence NP6'"
 
#### Paramètre du push
## ces réglages se trouvent sur le site http://www.pushover.net
token_app=""
target_1=""
target_2=""
 
####################################
## Fin de configuration
####################################
EOT
  eval 'echo -e "$ui_tag_ok Fichier conf créé"' $logfile_display_cmd
  eval 'echo -e "   Vous devez éditer le fichier \"$script_conf\" avant de poursuivre"' $logfile_display_cmd
  eval 'echo -e "   UTILISATION: ./"$script_name_full" -e"' $logfile_display_cmd
  eval 'echo ""' $logfile_display_cmd
  executed_date=$(date)
  eval 'printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd
  exit 1
else
  eval 'echo -e "$ui_tag_ok Fichier de configuration présent"' $logfile_display_cmd
  source "$script_conf"
fi
eval 'echo ""' $logfile_display_cmd


### Check dependencies
section_title="Contrôle des dépendances"
eval 'printf "$ui_tag_section" $(lon2 "$section_title") "$section_title"' $logfile_display_cmd
for dependency in $dependencies ; do
  if ! command -v $dependency >/dev/null 2>&1 ; then
    eval 'echo -e "$ui_tag_warning Dépendance absente: $dependency"' $logfile_display_cmd
    if command -v apt >/dev/null 2>&1; then
      read -p "Voulez-vous installer $dependency ? [o/N] " yn
      if [[ "$yn" =~ ^[oO]$ ]]; then
        sudo apt update && sudo apt install -y "$dependency"
      else
        eval 'echo "$ui_tag_bad Installation annulée pour : $dependency"' $logfile_display_cmd
        eval 'echo ""' $logfile_display_cmd
        executed_date=$(date)
        eval 'printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd
        exit 1
      fi
    else
      eval 'echo "$ui_tag_bad Veuillez installer manuellement $dependency (apt non disponible)"' $logfile_display_cmd
      eval 'echo ""' $logfile_display_cmd
      executed_date=$(date)
      eval 'printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd
      exit 1
    fi
  else
    eval 'echo -e "$ui_tag_ok Dépendance: $dependency"' $logfile_display_cmd
  fi
done


### Check update
this_script=$(realpath -s "$0")
if curl -m 2 --head --silent --fail "$script_remote" 2>/dev/null >/dev/null; then
  md5_local=`md5sum "$this_script" | cut -f1 -d" " 2>/dev/null`
  md5_remote=`curl -s "$script_remote" | md5sum | cut -f1 -d" "`
  if [[ "$md5_local" != "$md5_remote" ]]; then
    eval 'echo -e "$ui_tag_warning Une nouvelle version du script est disponible..."' $logfile_display_cmd
  else
    eval 'echo -e "$ui_tag_ok Le script est à jour..."' $logfile_display_cmd
  fi
else
  echo ""
  eval 'echo -e "$ui_tag_bad Script hors ligne..."' $logfile_display_cmd
fi
eval 'echo ""' $logfile_display_cmd


### Creation of folders
section_title="Variables"
eval 'printf "$ui_tag_section" $(lon2 "$section_title") "$section_title"' $logfile_display_cmd
if [[ "$LOCALDIR" == "" ]]; then
  eval 'echo -e "$ui_tag_bad Veuillez spécifier un répertoire local\n"' $logfile_display_cmd
  eval 'echo -e "   UTILISATION: ./"$script_name_full" -l local_dir"' $logfile_display_cmd
  eval 'echo -e "             ou ./"$script_name_full" -e"' $logfile_display_cmd
  eval 'echo -e "   ou editez le fichier \"$script_conf\" avant de poursuivre"' $logfile_display_cmd
  eval 'echo ""' $logfile_display_cmd
  executed_date=$(date)
  eval 'printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd
  exit 1
else
  eval 'echo -e "$ui_tag_ok Répertoire local: $LOCALDIR"' $logfile_display_cmd
  if [[ "$REMOTEDIR" == "" ]]; then
    eval 'echo -e "$ui_tag_bad Veuillez spécifier un répertoire distant\n"' $logfile_display_cmd
    eval 'echo -e "   UTILISATION: ./"$script_name_full" -r remote_dir"' $logfile_display_cmd
    eval 'echo -e "             ou ./"$script_name_full" -e"' $logfile_display_cmd
    eval 'echo -e "   ou editez le fichier \"$script_conf\" avant de poursuivre"' $logfile_display_cmd
    eval 'echo ""' $logfile_display_cmd
    executed_date=$(date)
    eval 'printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd
    exit 1
  fi
  eval 'echo -e "$ui_tag_ok Répertoire distant: $REMOTEDIR"' $logfile_display_cmd
  mkdir -p "$LOCALDIR/$REMOTEDIR" 2>/dev/null
fi
if [[ "$LOGIN" != "" ]] && [[ "$PASSWORD" != "" ]]; then
  eval 'echo -e "$ui_tag_ok Utilisateur: $LOGIN"' $logfile_display_cmd
  eval 'echo -e "$ui_tag_ok Mot de passe renseigné"' $logfile_display_cmd
else
  if [[ "$LOGIN" == "" ]]; then
    eval 'echo -e "$ui_tag_bad Utilisateur non renseigné"' $logfile_display_cmd
    eval 'echo -e "   UTILISATION: ./"$script_name_full" -e"' $logfile_display_cmd
    eval 'echo -e "   ou editez le fichier \"$script_conf\" avant de poursuivre"' $logfile_display_cmd
  else
    eval 'echo -e "$ui_tag_ok Utilisateur: $LOGIN"' $logfile_display_cmd
  fi
  if [[ "$PASSWORD" == "" ]]; then
    eval 'echo -e "$ui_tag_bad Mot de passe non renseigné"' $logfile_display_cmd
    eval 'echo -e "   UTILISATION: ./"$script_name_full" -e"' $logfile_display_cmd
    eval 'echo -e "   ou editez le fichier \"$script_conf\" avant de poursuivre"' $logfile_display_cmd
  else
    eval 'echo -e "$ui_tag_ok Mot de passe renseigné"' $logfile_display_cmd
  fi
  eval 'echo ""' $logfile_display_cmd
  executed_date=$(date)
  eval 'printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd
  exit 1
fi
eval 'echo ""' $logfile_display_cmd


### Synchro launched
section_title="Synchronisation"
eval 'printf "$ui_tag_section" $(lon2 "$section_title") "$section_title"' $logfile_display_cmd
if [ -e "$LOCALDIR$REMOTEDIR" ]; then
  if [[ -e "$logfile_pushover" ]]; then
    rm "$logfile_pushover"
  fi
  if [[ "$DELETEUSELESSFILES" == "yes" ]]; then
    eval 'echo -e "$ui_tag_ok Suppression des fichiers/dossiers inutiles activé"' $logfile_display_cmd
    lftp -u $LOGIN,$PASSWORD $HOST -d -e "mirror --delete $EXCLUDED '$REMOTEDIR' '$LOCALDIR$REMOTEDIR' ; quit" > $logfile_lftp 2>&1 & downloading_loading $!
  else
    eval 'echo -e "$ui_tag_warning Suppression des fichiers/dossiers inutiles désactivé"' $logfile_display_cmd
    lftp -u $LOGIN,$PASSWORD $HOST -d -e "mirror $EXCLUDED '$REMOTEDIR' '$LOCALDIR$REMOTEDIR' ; quit" > $logfile_lftp 2>&1 & downloading_loading $!
  fi
  if [[ "$(cat $logfile_lftp | grep "Login failed")" != "" ]]; then
    eval 'echo -e "$ui_tag_bad Connexion echouée: LOGIN et/ou PASSWORD incorect(s)"' $logfile_display_cmd
    pushover_message=`echo -e "[ <b>SYNCHRONISATION ÉCHOUÉE</b> ]\nLOGIN et/ou PASSWORD incorect(s)"`
    push-message "synchro_Iway" "$pushover_message" "1"
  else
    eval 'echo -e "$ui_tag_ok Synchronisation terminée"' $logfile_display_cmd
    if [[ "$DELETEUSELESSFILES" == "yes" ]]; then
      log_cleaning=`grep '^---- remove(' "$logfile_lftp" | sed -E 's/^---- remove\((.*)\)/\1/' | sed "s|^$LOCALDIR||"`
      if [[ "$log_cleaning" != "" ]]; then
        eval 'echo -e "$ui_tag_ok Suppression des fichiers/dossiers absents du FTP"' $logfile_display_cmd
        if [[ ! -e "$logfile_pushover" ]]; then
          echo -e "<b>Supression de :</b>" > $logfile_pushover
        else
          echo -e "<b>Supression de :</b>" >> $logfile_pushover
        fi
        while IFS= read -r line; do
          eval 'echo -e "..... $line"' $logfile_display_cmd
          echo -e $line >> $logfile_pushover
        done <<< "$log_cleaning"
      fi
    fi
    if [[ ! -e "$logfile_pushover" ]]; then
      pushover_message=`echo -e "[ <b>SYNCHRONISATION TERMINÉE</b> ]\nDisque dur à jour"`
    else
      pushover_message=`echo -e "[ <b>SYNCHRONISATION TERMINÉE</b> ]\n$(cat $logfile_pushover)"`
    fi
    push-message "synchro_Iway" "$pushover_message"
  fi
  chmod 777 -R $LOCALDIR$REMOTEDIR 2>/dev/null
else
  eval 'echo -e "$ui_tag_bad Dossier local non créé"' $logfile_display_cmd
fi
eval 'echo ""' $logfile_display_cmd
executed_date=$(date)
eval 'printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd
