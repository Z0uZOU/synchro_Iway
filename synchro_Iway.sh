#!/bin/bash

### Variable
script_name=$(basename $0 | cut -d'.' -f1)
script_name_cap=${script_name^^}
script_name_full=$(basename $0)
script_bin=$0
script_conf=`echo $HOME"/.config/"$script_name"/"$script_name".conf"`
script_remote="https://raw.githubusercontent.com/Z0uZOU/$script_name/main/$script_name_full"
script_folder="$HOME/.config/$script_name"
if [[ ! -d "$script_folder" ]]; then
  mkdir -p "$script_folder"
fi
if [[ ! -d "$script_folder/logs" ]]; then
  mkdir -p "$script_folder/logs"
fi
date_log=`date +%Y-%m-%d`
logfile_lftp=`echo $script_folder"/logs/"$date_log"_lftp.log"`
logfile_display=`echo $script_folder"/logs/"$date_log"_display.log"`
logfile_display_cmd=`echo "| tee -a "$script_folder"/logs/"$date_log"_display.log"`
REMOTEDIR="/McDonalds"
EXCLUDED="-x Thumbs.db -x 'Licence NP6'"
dependencies="curl lftp"


## Check if this script is running
check_dupe=$(ps -ef | grep "$0" | grep -v grep | wc -l | xargs)
process_number="2"
if [[ "$check_dupe" > "$process_number" ]]; then
  echo "Script déjà en cours d'exécution"
  date
  exit 1
fi


## Advanced command arguments
die() { echo "$*" >&2; exit 2; }  # complain to STDERR and exit with error
needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option"; fi; }

while getopts euhr:l:-: OPT; do
  # support long options: https://stackoverflow.com/a/28466267/519360
  if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi
  case "$OPT" in
    h | help )
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
            exit 0
            ;;
    u | update )
            echo -e "\033[1m$script_name_cap - Mise à jour lancée\033[0m"
            read -n 1 -p "Voulez-vous continuer [o/N]:" yn
            printf "\r                                                     "
            if [[ "${yn}" == @(o|O) ]]; then
              echo ""
              this_script=$(realpath -s "$0")
              echo "Emplacement du script : "$this_script
              if curl -H "Authorization: token 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" -H "Accept: application/vnd.github.v3.raw" -m 2 --head --silent --fail "$script_remote" 2>/dev/null >/dev/null; then
                echo "Script disponible en ligne sur GitHub"
                md5_local=`md5sum "$this_script" | cut -f1 -d" " 2>/dev/null`
                md5_remote=`curl -H "Authorization: token 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" -H "Accept: application/vnd.github.v3.raw" -s "$script_remote" | md5sum | cut -f1 -d" "`
                echo "MD5 local  : "$md5_local
                echo "MD5 remote : "$md5_remote
                if [[ "$md5_local" != "$md5_remote" ]]; then
                  echo "Une nouvelle version du script est disponible... en téléchargement"
                  curl -H "Authorization: token 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" -H "Accept: application/vnd.github.v3.raw" -s -m 3 --create-dir -o "$this_script" "$script_remote"
                  echo "Mise à jour terminée... exit"
                else
                  echo "Le script est à jour... exit"
                fi
              else
                echo ""
                echo "Script hors ligne"
              fi
            else
              echo ""
              echo "Rien n'a été fait"
            fi
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
              echo -e "\033[1m$script_name_cap - éditeur de configuration\033[0m"
              echo ""
              echo "Pas d'éditeur spécifié, utilisation par défaut (nano)"
              nano "$script_conf"
              exit 0
            else
              echo -e "\033[1m$script_name_cap - éditeur de configuration\033[0m"
              echo ""
              if command -v $next_arg ; then
                echo "Édition du fichier avec: $next_arg"
                $next_arg "$script_conf"
              else
                echo "Il n'existe aucun logiciel appelé \"$next_arg\" installé"
              fi
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
      folder=`cat "$logfile_lftp" | egrep "CWD path to be sent is" | tail -1 | sed "s/.*CWD path to be sent is .//" | sed "s/.$//"`
      if [[ "$folder" != "$previous_folder" ]]; then
        previous_folder=$folder
      fi
      file=`cat "$logfile_lftp" | egrep " RETR " | tail -1 | sed "s/.*RETR //"`
      if [[ "$file" != "$previous_file" ]]; then
        previous_file=$file
        printf "\r\n"
      fi
      folder_line=`cat "$logfile_lftp" | grep -n "$folder" | tail -1  | cut -d: -f1`
      file_line=`cat "$logfile_lftp" | grep -n "$file" | tail -1  | cut -d: -f1`
      if [[ $folder_line -gt $file_line ]]; then
        file=""
      fi
      if [[ "$folder" != "" ]] && [[ "$file" != "" ]]; then
        i=$(((i+1) % ${#spin}))
        log_echo=`cat "$logfile_display" | egrep "$folder/$file"`
        if [[ "$log_echo" == "" ]]; then
          echo -e "[${spin:$i:1}] Téléchargement de $folder/$file" >> $logfile_display
        fi
        if [[ "${#folder} + ${#file}" -gt "65" ]]; then
          print_file=`echo ${folder: -65}/$file | sed "s:[^\/]*\/:...\/:"`
        else
          print_file=`echo $folder/$file`
        fi
        printf "\r[${spin:$i:1}] Téléchargement de $print_file"
        sleep .1
      fi
    fi
  done
  tput cnorm
  printf "$mon_printf" && printf "\r"
}


## Fix printf special char issue
Lengh1="55"
Lengh2="61"
lon() ( echo $(( Lengh1 + $(wc -c <<<"$1") - $(wc -m <<<"$1") )) )
lon2() ( echo $(( Lengh2 + $(wc -c <<<"$1") - $(wc -m <<<"$1") )) )


eval 'printf "\e[46m\u23E5\u23E5   \e[0m \e[46m \e[1m %-61s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" "$script_name_cap"' $logfile_display_cmd
executed_date=$(date)
eval 'printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd


## UI tags
ui_tag_write="[\e[43m \u270E \e[0m]"
ui_tag_checking="[\e[43m \u003F \e[0m]"
ui_tag_encoding="[\e[7m \u238B \e[0m]"
ui_tag_ok="[\e[42m \u2713 \e[0m]"
ui_tag_ok_sed="[\\\e[42m \\\u2713 \\\e[0m]"
ui_tag_bad="[\e[41m \u2713 \e[0m]"
ui_tag_warning="[\e[43m \u2713 \e[0m]"
ui_tag_section="\e[44m[\u2263\u2263\u2263]\e[0m \e[44m \e[1m %-*s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n"


### Configuration file
if [[ ! -f "$script_conf" ]]; then
  eval 'echo -e "$ui_tag_warning Fichier de conf absent, création du fichier de conf"' $logfile_display_cmd
  touch "$script_conf"
  chmod 777 "$script_conf"
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
  eval 'echo -e "      Vous dever éditer le fichier \"$script_conf\" avant de poursuivre"' $logfile_display_cmd
  exit 1
else
  eval 'echo -e "$ui_tag_ok Fichier de configuration présent"' $logfile_display_cmd
  source "$script_conf"
fi
echo ""


### Check dependencies
section_title="Contrôle des dépendances"
eval 'printf "$ui_tag_section" $(lon2 "$section_title") "$section_title"' $logfile_display_cmd
for dependency in $dependencies ; do
  if command -v $dependency > /dev/null 2>/dev/null ; then
    eval 'echo -e "$ui_tag_ok Dépendence: $dependency"' $logfile_display_cmd
  else
    eval 'echo -e "$ui_tag_bad Dépendence absente: $dependency"' $logfile_display_cmd
    sudo apt install $dependency
  fi
done
echo ""


### Creation of folders
section_title="Variables"
eval 'printf "$ui_tag_section" $(lon2 "$section_title") "$section_title"' $logfile_display_cmd
if [[ "$LOCALDIR" == "" ]]; then
  eval 'echo -e "$ui_tag_bad Veuillez spécifier un répertoire local\n"' $logfile_display_cmd
  eval 'echo -e "      UTILISATION: ./"$script_name_full" -l local_dir"' $logfile_display_cmd
  eval 'echo -e "                ou ./"$script_name_full" -e"' $logfile_display_cmd
  exit 1
else
  eval 'echo -e "$ui_tag_ok Répertoire local: $LOCALDIR"' $logfile_display_cmd
  if [[ "$REMOTEDIR" == "" ]]; then
    eval 'echo -e "$ui_tag_bad Veuillez spécifier un répertoire distant\n"' $logfile_display_cmd
    eval 'echo -e "      UTILISATION: ./"$script_name_full" -r remote_dir"' $logfile_display_cmd
    eval 'echo -e "                ou ./"$script_name_full" -e"' $logfile_display_cmd
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
    eval 'echo -e "      UTILISATION: ./"$script_name_full" -e"' $logfile_display_cmd
    eval 'echo -e "      ou editez le fichier \"$script_conf\" avant de poursuivre"' $logfile_display_cmd
  else
    eval 'echo -e "$ui_tag_ok Utilisateur: $LOGIN"' $logfile_display_cmd
  fi
  if [[ "$PASSWORD" == "" ]]; then
    eval 'echo -e "$ui_tag_bad Mot de passe non renseigné"' $logfile_display_cmd
    eval 'echo -e "      UTILISATION: ./"$script_name_full" -e"' $logfile_display_cmd
    eval 'echo -e "      ou editez le fichier \"$script_conf\" avant de poursuivre"' $logfile_display_cmd
  else
    eval 'echo -e "$ui_tag_ok Mot de passe renseigné"' $logfile_display_cmd
  fi
  exit 1
fi
echo ""


### Synchro launched
section_title="Synchronisation"
eval 'printf "$ui_tag_section" $(lon2 "$section_title") "$section_title"' $logfile_display_cmd
if [ -e "$LOCALDIR$REMOTEDIR" ]; then
  lftp -u $LOGIN,$PASSWORD $HOST -d -e "mirror $EXCLUDED $REMOTEDIR $LOCALDIR$REMOTEDIR ; quit" > $logfile_lftp 2>&1 & downloading_loading $!
  if [[ "$(cat $logfile_lftp | grep "Login failed")" != "" ]]; then
    eval 'echo -e "$ui_tag_bad Connexion echouée: LOGIN et/ou PASSWORD incorect(s)"' $logfile_display_cmd
    push-message "synchro_Iway" "Synchronisation échouée" "1"
  else
    eval 'echo -e "$ui_tag_ok Synchronisation terminée"' $logfile_display_cmd
    push-message "synchro_Iway" "Synchronisation terminée"
  fi
  chmod 777 -R $LOCALDIR$REMOTEDIR 2>/dev/null
else
  eval 'echo -e "$ui_tag_bad Dossier local non créé"' $logfile_display_cmd
fi
echo ""

executed_date=$(date)
eval 'printf "\e[46m\u23E5\u23E5   \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd
