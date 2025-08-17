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
REMOTEDIR="/McDonalds"


## Fix printf special char issue
Lengh1="55"
Lengh2="64"
lon() ( echo $(( Lengh1 + $(wc -c <<<"$1") - $(wc -m <<<"$1") )) )
lon2() ( echo $(( Lengh2 + $(wc -c <<<"$1") - $(wc -m <<<"$1") )) )


## UI tags
ui_tag_ok="✅"
ui_tag_bad="❌"
ui_tag_warning="⚠️"
ui_tag_section="\e[44m  \e[0m \e[44m \e[1m %-*s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n"


## Argument parser
while getopts sceuhr:l:-: OPT; do
  if [ "$OPT" = "-" ]; then
    OPT="${OPTARG%%=*}"
    OPTARG="${OPTARG#$OPT}"
    OPTARG="${OPTARG#=}" 
  fi
  case "$OPT" in
    c | check-config )
            printf "\e[46m  \e[0m \e[46m \e[1m %-64s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" "$script_name_cap"
            executed_date=$(date)
            printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
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
              printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
              exit 1
            else
              echo -e "\033[1;32mLa configuration est complète\033[0m"
              echo ""
              executed_date=$(date)
              printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
              exit 0
            fi
            ;;
    e | edit-config )
            eval next_arg=\${$OPTIND}
            if [[ "$next_arg" == "" ]]; then
              printf "\e[46m  \e[0m \e[46m \e[1m %-64s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" "$script_name_cap"
              executed_date=$(date)
              printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
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
              printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
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
              printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
              exit 0
            fi
            ;;
    h | help )
            printf "\e[46m  \e[0m \e[46m \e[1m %-64s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" "$script_name_cap"
            executed_date=$(date)
            printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
            echo -e "\033[1m$script_name_cap - aide\033[0m"
            echo ""
            echo "Utilisation : $script_bin [option]"
            echo ""
            echo "Options disponibles:"
            echo "[value*] signifie un argument facultatif"
            echo ""
            echo " -h or --help                              : ce menu d'aide"
            echo " -c or --check-config                      : vérification du fichier de configuration"
            echo " -e [value*] or --edit-config=[value*]     : édition du fichier de configuration (défaut: nano)"
            echo " -l [value] or --local=[value]             : dossier local"
            echo " -r [value] or --remote=[value]            : dossier distant"
            echo " -s or --stop                              : force l'arrêt du script"
            echo " -u or --update                            : mise à jour du script"
            echo ""
            executed_date=$(date)
            printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
            exit 0
            ;;
    l | local )
            needs_arg
            LOCALDIR="$OPTARG"
            if [[ -f "$script_conf" ]]; then
              sed -i 's|LOCALDIR=.*|LOCALDIR="'$LOCALDIR'"|' $script_conf
            fi
            ;;
    r | remote )
            needs_arg
            REMOTEDIR="$OPTARG"
            if [[ -f "$script_conf" ]]; then
              sed -i 's|REMOTEDIR=.*|REMOTEDIR="'$REMOTEDIR'"|' $script_conf
            fi
            ;;
    s | stop )
            if pgrep -x lftp >/dev/null 2>&1; then
              echo "Arrêt du script"
              mapfile -t pids < <(pgrep -f "(${script_name}|lftp)" 2>/dev/null || true)
              for bad in "$$" "$BASHPID" "$PPID"; do
                for i in "${!pids[@]}"; do
                  [[ "${pids[i]}" == "$bad" ]] && unset 'pids[i]'
                done
              done
              if ((${#pids[@]})); then
                readarray -t pids < <(printf "%s\n" "${pids[@]}" | awk 'NF' | sort -u)
              fi
              if ((${#pids[@]})); then
                kill -TERM "${pids[@]}" 2>/dev/null
                sleep 1
                kill -KILL "${pids[@]}" 2>/dev/null
              fi
            else
              echo "Pas de synchro en cours"
            fi
            exit 0
            ;;
    u | update )
            printf "\e[46m  \e[0m \e[46m \e[1m %-64s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" "$script_name_cap"
            executed_date=$(date)
            printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
            echo -e "\033[1m$script_name_cap - Mise à jour lancée\033[0m"
            read -n 1 -p "Voulez-vous continuer [o/N]:" yn
            printf "\r                                                     "
            if [[ "$yn" =~ ^[oO]$ ]]; then
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
            printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
            exit 0
            ;;
    ??* )          die "Option illégale --$OPT" ;;  # bad long option
    ? )            exit 2 ;;  # bad short option (error reported via getopts)
  esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list


## Check if this script is running
exec 200>/tmp/${script_name}.lock
flock -n 200 || { echo "Script déjà en cours d'exécution"; exit 1; }


## Message feature
push-message() {
  push_content=$1
  push_priority=$2
  if [[ "$push_priority" == "" ]]; then
    push_priority="-1"
  fi
  for user in {1..10}; do
    target=`eval echo "\\$target_"$user`
    if [ -n "$target" ]; then
      curl -s \
        --form-string "token=$token_app" \
        --form-string "user=$target" \
        --form-string "title=$script_name" \
        --form-string "message=$push_content" \
        --form-string "html=1" \
        --form-string "priority=$push_priority" \
        https://api.pushover.net/1/messages.json > /dev/null
    fi
  done
}
discord-message() {
  discord_message=$(echo -e "$1" \
    | sed 's|<b>|**|g' \
    | sed 's|</b>|**|g' \
    | sed ':a;N;$!ba;s|\n|\\n|g')
  curl -s -H "Content-Type: application/json" \
    -X POST \
    -d "{\"content\": \"${discord_message}\"}" \
    "$WEBHOOK_URL" > /dev/null
}


## Function to display download progress
function downloading_loading() {
  local pid="$*"
  local previous_file=""
  local last_done_key=""
  local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
  local i=0

  # ------ Terminal formatting (stderr) ------
  local CLR=$'\r\033[2K'      # clear whole line + CR
  local GREEN=$'\033[0;32m'   # green
  local RESET=$'\033[0m'
  # ------------------------------------------

  # ------ Helpers ------
  # Remplace la ligne qui commence (après espaces) par "token" par "newline", sinon ajoute en fin.
  # Comparaison LITTÉRALE (pas de regex), résiste aux espaces, &, \9, (), etc.
  replace_or_append_line() {
    local file="$1" token="$2" newline="$3"
    local tmp="${file}.tmp.$$"
    awk -v token="$token" -v newline="$newline" '
      BEGIN{ done=0; toklen=length(token) }
      {
        s=$0; sub(/^[[:space:]]*/,"",s)
        if (!done && substr(s,1,toklen)==token) { print newline; done=1; next }
        print $0
      }
      END{ if (!done) print newline }
    ' "$file" > "$tmp" && mv -- "$tmp" "$file"
  }

  # Affichage terminal compact: ".../<derniers dossiers>/Fichier" (≤ limit), sans tronquer de dossier.
  # Si le nom de fichier seul dépasse, on tronque le NOM DE FICHIER au milieu (en gardant l’extension).
  shorten_path_term() {
    local folder="$1" file="$2" limit="${3:-65}"
    IFS='/' read -ra raw <<< "$folder"
    local parts=() seg
    for seg in "${raw[@]}"; do [[ -n "$seg" ]] && parts+=("$seg"); done
    local right="$file" i
    for (( i=${#parts[@]}-1; i>=0; i-- )); do
      local cand="${parts[i]}/$right"
      if (( ${#cand} + 4 <= limit )); then right="$cand"; else break; fi
    done
    if (( ${#right} + 4 > limit )); then
      local base="$file" ext=""
      if [[ "$file" == *.* ]]; then ext=".${file##*.}"; base="${file%.*}"; fi
      local allow=$(( limit - 4 ))
      if (( ${#ext} >= allow - 1 )); then
        right="${file:0:allow-3}..."
      else
        local mid="..." keep=$(( allow - ${#ext} - ${#mid} ))
        (( keep < 2 )) && keep=2
        local L=$(( keep/2 )) R=$(( keep - L ))
        right="${base:0:L}${mid}${base: -R}${ext}"
      fi
    fi
    printf '%s' ".../$right"
  }
  # ---------------------

  while kill -0 "$pid" 2>/dev/null; do
    if [[ -f "$logfile_lftp" ]]; then
      i=$(((i+1) % ${#spin}))

      # Parse: dernier CWD avant dernier RETR + flag de fin
      IFS=$'\t' read -r folder_line file_line folder file done_flag < <(
        awk -v OFS='\t' '
          function trim(s){ sub(/^[ \t\r\n]+/,"",s); sub(/[ \t\r\n]+$/, "", s); return s }
          function isq(c){ return (c=="\"" || c=="`" || c==sprintf("%c",39)) }
          function strip_outer_quotes(s,   c1,cN){
            while (length(s)>0) { c1=substr(s,1,1); cN=substr(s,length(s),1);
              if (isq(c1)) s=substr(s,2);
              else if (isq(cN)) s=substr(s,1,length(s)-1);
              else break }
            return s
          }
          BEGIN { last_completed=0; cwd=""; cwd_line=0; last_file_line=0 }
          /CWD path to be sent is/ { s=$0; sub(/.*CWD path to be sent is[ \t]+/, "", s);
            cwd=strip_outer_quotes(trim(s)); cwd_line=NR; next }
          /(^|[ \t])RETR[ \t]+/ { f=$0; sub(/.*RETR[ \t]+/, "", f); f=strip_outer_quotes(trim(f));
            if (cwd_line && cwd_line<NR){ last_cwd=cwd; last_cwd_line=cwd_line; last_file=f; last_file_line=NR; last_completed=0 } ; next }
          /(^|[^0-9])226([^0-9]|$)/ { if (last_file_line) last_completed=1; next }
          /Transfer complete/       { if (last_file_line) last_completed=1; next }
          END { if (last_file_line) print last_cwd_line, last_file_line, last_cwd, last_file, last_completed }
        ' "$logfile_lftp"
      )

      # Rien d exploitable
      if [[ -z "$file_line" || -z "$folder" || -z "$file" ]]; then
        printf "%s %s Téléchargement en cours ...   " "$CLR" "${spin:$i:1}" >&2
        sleep 0.1; continue
      fi

      # Nettoyage quotes + normalisation des séparateurs "\" -> "/"
      folder="${folder//\`/}"; folder="${folder//\"/}"; folder="${folder//\'/}"
      file="${file//\`/}";     file="${file//\"/}";     file="${file//\'/}"
      folder="$(printf '%s' "$folder" | sed -E 's#\\([[:alnum:]_.-])#/\1#g')"
      file="$(printf '%s' "$file"     | sed -E 's#\\([[:alnum:]_.-])#/\1#g')"

      # Nouveau fichier -> autoriser une nouvelle ligne "terminée"
      if [[ "$file" != "$previous_file" ]]; then
        previous_file="$file"
        last_done_key=""
      fi

      # Affichage terminal compact
      local print_file; print_file="$(shorten_path_term "$folder" "$file" 65)"

      # Taille locale si dispo
      local file_path="$LOCALDIR$folder/$file"
      local file_size=""
      if [[ -f "$file_path" ]]; then
        file_size=$(numfmt --to=iec "$(stat -c%s "$file_path")")
      fi
      [[ -z "$file_size" ]] && file_size="~"

      # Lignes stables pour le log
      local base_token="Téléchargement de $folder/$file"
      local log_line_now=" Téléchargement de $folder/$file $file_size"

      # Fallback cohérence: si le log a déjà la ligne "terminée", force l’affichage terminal en terminé
      if grep -qF "✔ Téléchargement terminé : $folder/$file" "$logfile_display" 2>/dev/null; then
        done_flag="1"
      fi

      if [[ "$done_flag" == "1" ]]; then
        # TERMINÉ: une seule fois par fichier
        if [[ "$last_done_key" != "$folder/$file" ]]; then
          last_done_key="$folder/$file"

          # Terminal (stderr) : tick vert + espace
          printf "%s%s✔%s  Téléchargement terminé : %s %s\n" \
            "$CLR" "$GREEN" "$RESET" "$print_file" "$file_size" >&2

          # display.log : remplacer "Téléchargement de ..." -> "✔ Téléchargement terminé ..."
          replace_or_append_line "$logfile_display" \
            "Téléchargement de $folder/$file" \
            "✔ Téléchargement terminé : $folder/$file $file_size"

          # pushover : ajouter SANS tick, une seule fois
          if [[ ! -e "$logfile_pushover" ]]; then
            echo -e "<b>Téléchargements terminés :</b>" > "$logfile_pushover"
          fi
          if ! grep -qxF "$folder/$file" "$logfile_pushover" 2>/dev/null; then
            echo -e "$folder/$file" >> "$logfile_pushover"
          fi
        fi

        # Spinner générique pendant l’attente d’un prochain RETR
        printf "%s %s Téléchargement en cours ...   " "$CLR" "${spin:$i:1}" >&2

      else
        # EN COURS : terminal (stderr) uniquement
        printf "%s %s Téléchargement de %s %s    " "$CLR" "${spin:$i:1}" "$print_file" "$file_size" >&2

        # display.log : UNE ligne stable sans spinner (maj atomique)
        replace_or_append_line "$logfile_display" \
          "Téléchargement de $folder/$file" \
          " Téléchargement de $folder/$file $file_size"
        # (rien dans pushover pendant l’en cours)
      fi

      sleep 0.1
    else
      sleep 0.1
    fi
  done
}


## Automatic file renaming function if existing
rename_if_exists() {
  file="$1"
  if [[ ! -e "$file" ]]; then return 1; fi
  dir=$(dirname "$file")
  filename=$(basename "$file")
  base="${filename%.*}"
  ext="${filename##*.}"
  if [[ "$base" == "$filename" ]]; then ext="";  fi
  counter=1
  newfile="$file"
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


eval 'printf "\e[46m  \e[0m \e[46m \e[1m %-64s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" "$script_name_cap"' $logfile_display_cmd
executed_date=$(date)
eval 'printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd


### Configuration file
if [[ ! -f "$script_conf" ]]; then
  eval 'echo -e "$ui_tag_warning Fichier de conf absent, création du fichier de conf"' $logfile_display_cmd
  touch "$script_conf"
  chmod 600 "$script_conf"
cat <<EOT >> "$script_conf"
####################################
## Configuration
####################################
 
#### Paramètres
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
 
#### Paramètres Pushover
## ces réglages se trouvent sur le site http://www.pushover.net
token_app=""
target_1=""
target_2=""
 
#### Paramètre Discord
## Webhook URL pour la prise en charge de Discord
WEBHOOK_URL=""
 
####################################
## Fin de configuration
####################################
EOT
  eval 'echo -e "$ui_tag_ok Fichier conf créé"' $logfile_display_cmd
  eval 'echo -e "   Vous devez éditer le fichier \"$script_conf\" avant de poursuivre"' $logfile_display_cmd
  eval 'echo -e "   UTILISATION: ./"$script_name_full" -e"' $logfile_display_cmd
  eval 'echo ""' $logfile_display_cmd
  executed_date=$(date)
  eval 'printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd
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
        eval 'printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd
        exit 1
      fi
    else
      eval 'echo "$ui_tag_bad Veuillez installer manuellement $dependency (apt non disponible)"' $logfile_display_cmd
      eval 'echo ""' $logfile_display_cmd
      executed_date=$(date)
      eval 'printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd
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
  eval 'printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd
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
    eval 'printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd
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
  eval 'printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd
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
    pushover_message=`echo -e "[ <b>SYNCHRONISATION ÉCHOUÉE</b> ]\n💻 $(hostname)\nLOGIN et/ou PASSWORD incorect(s)"`
    if [[ -n "$WEBHOOK_URL" ]]; then discord-message "$pushover_message"; fi
    push-message "$pushover_message" "1"
  else
    eval 'echo ""' $logfile_display_cmd
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
      pushover_message=`echo -e "[ <b>SYNCHRONISATION TERMINÉE</b> ]\n💻 $(hostname)\nDisque dur à jour"`
    else
      pushover_message=`echo -e "[ <b>SYNCHRONISATION TERMINÉE</b> ]\n💻 $(hostname)\n$(cat $logfile_pushover)"`
    fi
    if [[ -n "$WEBHOOK_URL" ]]; then discord-message "$pushover_message"; fi
    push-message "$pushover_message"
  fi
  chmod 777 -R $LOCALDIR$REMOTEDIR 2>/dev/null
else
  eval 'echo -e "$ui_tag_bad Dossier local non créé"' $logfile_display_cmd
fi
eval 'echo ""' $logfile_display_cmd
executed_date=$(date)
eval 'printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"' $logfile_display_cmd
