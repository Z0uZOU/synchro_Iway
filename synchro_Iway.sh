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
logfile=`echo $script_folder"/logs/"$date_log".log"`
logfile_cmd="| tee -a $logfile"

EXCLUDED="-x Thumbs.db -x 'Licence NP6'"
dependencies="lftpd"

#######################
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
            echo -e "\033[1m$script_name_cap - Update initiated\033[0m"
            read -n 1 -p "Do you want to proceed [y/N]:" yn
            printf "\r                                                     "
            if [[ "${yn}" == @(y|Y) ]]; then
              echo ""
              this_script=$(realpath -s "$0")
              echo "Script location : "$this_script
              if curl -m 2 --head --silent --fail "$script_remote" 2>/dev/null >/dev/null; then
                echo "Script available online on GitHub "
                md5_local=`md5sum "$this_script" | cut -f1 -d" " 2>/dev/null`
                md5_remote=`curl -s "$script_remote" | md5sum | cut -f1 -d" "`
                echo "MD5 local  : "$md5_local
                echo "MD5 remote : "$md5_remote
                if [[ "$md5_local" != "$md5_remote" ]]; then
                  echo "A new version of the script is available... downloading"
                  curl -s -m 3 --create-dir -o "$this_script" "$script_remote"
                  echo "Update completed... exit"
                else
                  echo "The script is up to date... exit"
                fi
              else
                echo ""
                echo "Script offline"
              fi
            else
              echo ""
              echo "Nothing was done"
            fi
            exit 0
            ;;
    r | remote )
            needs_arg
            REMOTEDIR="$OPTARG"
            echo -e "REMOTEDIR : "$REMOTEDIR
            ;;
    l | local )
            needs_arg
            LOCALDIR="$OPTARG"
            echo -e "LOCALDIR : "$LOCALDIR
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

exit 1

### Usage function
function Usage()
{
  eval 'echo -e "\n  Synchronise un répertoire local avec un répertoire distant en utilisant LFTP"' $logfile_cmd;  
  eval 'echo -e "  USAGE: ./synchro.sh local_dir remote_dir"' $logfile_cmd;
  echo;
}

function downloading_loading() {
  pid="$*"
  previous_folder=""
  previous_file=""
  spin='⣾⣽⣻⢿⡿⣟⣯⣷'
  i=0
  tput civis # cursor invisible
  mon_printf="\r                                                                             "
  while kill -0 "$pid" 2>/dev/null; do
    if [[ -f "$logfile" ]]; then
	  folder=`cat "$logfile" | egrep "CWD path to be sent is" | tail -1 | sed "s/.*CWD path to be sent is .//" | sed "s/.$//"`
      if [[ "$folder" != "$previous_folder" ]]; then
#        echo "Folder : "$folder
        previous_folder=$folder
      fi
	  file=`cat "$logfile" | egrep " RETR " | tail -1 | sed "s/.*RETR //"`
      if [[ "$file" != "$previous_file" ]]; then
#        echo "file : "$file
        previous_file=$file
		printf "\r\n"
      fi
      folder_line=`cat "$logfile" | grep -n "$folder" | tail -1  | cut -d: -f1`
      file_line=`cat "$logfile" | grep -n "$file" | tail -1  | cut -d: -f1`
      if [[ $folder_line -gt $file_line ]]; then
        file=""
      fi
#      if [[ "$(echo -e "$progress" | awk '{ print $1 }')" == "RETR" ]]; then
#        file=`echo $progress | sed "s/.*RETR //"`
#        echo "File : "$file
#	  fi

      if [[ "$folder" != "" ]] && [[ "$file" != "" ]]; then
  	    i=$(((i+1) % ${#spin}))
        printf "\r[${spin:$i:1}] Téléchargement de $folder/$file"
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


eval 'printf "\e[46m\u23E5\u23E5   \e[0m \e[46m \e[1m %-61s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" "$script_name_cap"' $logfile_cmd


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
  eval 'echo -e "$ui_tag_warning Fichier de conf absent, création du fichier de conf"' $logfile_cmd
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
destinataire=""
 
####################################
## Fin de configuration
####################################
EOT
  eval 'echo -e "$ui_tag_ok Fichier conf créé"' $mon_log_perso
  eval 'echo -e "      Vous dever éditer le fichier \"$script_conf\" avant de poursuivre"' $mon_log_perso
  exit 1
else
  eval 'echo -e "$ui_tag_ok Fichier de configuration présent"' $logfile_cmd
fi


### Check dependencies
section_title="Checking dependencies"
eval 'printf "$ui_tag_section" $(lon2 "$section_title") "$section_title"' $logfile_cmd
for dependency in $dependencies ; do
  if command -v $dependency > /dev/null 2>/dev/null ; then
    eval 'echo -e "$ui_tag_ok Dépendence: $dependency"' $logfile_cmd
  else
    eval 'echo -e "$ui_tag_bad Dépendence absente: $dependency"' $logfile_cmd
    sudo apt install $dependency
  fi
done
echo ""



### Creation of folders
if [[ "$LOCALDIR" == "" ]]; then
  eval 'echo -e "[\e[41m\u2717 \e[0m] Veuillez spécifier un répertoire local"' $logfile_cmd
  Usage
  exit 1
else
  if [[ "$REMOTEDIR" == "" ]]; then
    eval 'echo -e "[\e[41m\u2717 \e[0m] Veuillez spécifier un répertoire distant"' $logfile_cmd
    Usage
    exit 1
  fi
  mkdir -p "$LOCALDIR$REMOTEDIR" 2>/dev/null
fi

echo "SYNCHRO..."
exit 1

### Synchro launched
if [ -e "$LOCALDIR$REMOTEDIR" ]; then
#  eval 'lftp -u $LOGIN,$PASSWORD $HOST -e "mirror $EXCLUDED $REMOTEDIR $LOCALDIR$REMOTEDIR ; quit"' $logfile_cmd
  lftp -u $LOGIN,$PASSWORD $HOST -d -e "mirror $EXCLUDED $REMOTEDIR $LOCALDIR$REMOTEDIR ; quit" > $logfile 2>&1 & downloading_loading $!
fi

chmod 777 -R $LOCALDIR$REMOTEDIR 2>/dev/null
