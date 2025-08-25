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


### Fix printf special char issue
Lengh1="55"
Lengh2="64"
lon() ( echo $(( Lengh1 + $(wc -c <<<"$1") - $(wc -m <<<"$1") )) )
lon2() ( echo $(( Lengh2 + $(wc -c <<<"$1") - $(wc -m <<<"$1") )) )


### UI tags
ui_tag_ok="✅"
ui_tag_bad="❌"
ui_tag_warning="⚠"
ui_tag_section="\e[44m  \e[0m \e[44m \e[1m %-*s  \e[0m \e[44m  \e[0m \e[44m \e[0m \e[34m\u2759\e[0m\n"


### Check dependencies
check_dependencies() {
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
}


### import configuration file
import_source_conf () {
  if [[ ! -f "$script_conf" ]]; then
    eval 'echo -e "$ui_tag_warning Fichier de conf absent"' $logfile_display_cmd
  else
    source "$script_conf"
    if [[ "$ui_tag_ok" == "" ]]; then ui_tag_ok="✅"; fi
    if [[ "$ui_tag_bad" == "" ]]; then ui_tag_bad="❌"; fi
    if [[ "$ui_tag_warning" == "" ]]; then ui_tag_warning="⚠"; fi
    eval 'echo -e "$ui_tag_ok Fichier de configuration présent"' $logfile_display_cmd
  fi
}


### Argument parser
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
            logfile_display_cmd=""
			import_source_conf
            echo ""
            check_dependencies
            echo ""
            section_title="Test de connexion au FTP"
            printf "$ui_tag_section" $(lon2 "$section_title") "$section_title"
            config_ok=true
            if [[ -z "$LOGIN" ]]; then echo "$ui_tag_bad LOGIN manquant"; config_ok=false; else echo "$ui_tag_ok LOGIN : $LOGIN"; fi
            if [[ -z "$PASSWORD" ]]; then echo "$ui_tag_bad PASSWORD manquant"; config_ok=false; else echo "$ui_tag_ok Mot de passe renseigné"; fi
            if [[ -z "$HOST" ]]; then echo "$ui_tag_bad HOST manquant"; config_ok=false; else echo "$ui_tag_ok Hôte FTP : $HOST"; fi
            if [[ -z "$LOCALDIR" ]]; then echo "$ui_tag_bad LOCALDIR manquant"; config_ok=false; else echo "$ui_tag_ok Dossier local : $LOCALDIR"; fi
            if [[ -z "$REMOTEDIR" ]]; then echo "$ui_tag_bad REMOTEDIR manquant"; config_ok=false; else echo "$ui_tag_ok Dossier distant : $REMOTEDIR"; fi
            echo ""
            if [[ "$config_ok" == false ]]; then
              echo -e "$ui_tag_bad\033[1;31m La configuration est incomplète\033[0m"
              echo ""
              executed_date=$(date)
              printf "\e[46m  \e[0m \e[46m  %*s  \e[0m \e[46m  \e[0m \e[46m \e[0m \e[36m\u2759\e[0m\n" $(lon2 "$executed_date") "$executed_date"
              exit 1
            else
              echo -e "$ui_tag_ok\033[1;32m La configuration est complète\033[0m"
              echo ""
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
              logfile_display_cmd=""
              import_source_conf
              echo ""
              check_dependencies
              echo ""
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
                logfile_display_cmd=""
                import_source_conf
                check_dependencies
                echo ""
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


### Check if this script is running
exec 200>/tmp/${script_name}.lock
flock -n 200 || { echo "Script déjà en cours d'exécution"; exit 1; }


### Message feature
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


### Build excludes for lftp mirror (-x patterns)
make_excludes() {
  local excludes="$1"
  local exclude_args=""
  [[ -z "$excludes" ]] && { echo ""; return; }
  IFS='|' read -ra parts <<< "$excludes"
  for p in "${parts[@]}"; do
    # trim surrounding spaces
    p="${p#"${p%%[![:space:]]*}"}"
    p="${p%"${p##*[![:space:]]}"}"
    [[ -z "$p" ]] && continue
    if [[ "$p" == *" "* ]]; then
      exclude_args+=" -x '$p'"
    else
      exclude_args+=" -x $p"
    fi
  done
  echo "$exclude_args"
}


## Liste globale des fichiers incomplets (chemins distants)
RETRY_LIST=()


## Function to display download progress
function downloading_loading() {
  local pid="$*"
  declare -gA __SEEN_COMPLETED=()
  local spin='⣾⣽⣻⢿⡿⣟⣯⣷' i=0
  tput civis
  local CLR=$'\r\033[2K'
  local GREEN=$'\033[0;32m'
  local RED=$'\033[0;31m'
  local RESET=$'\033[0m'
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
  shorten_path_term() {
    local folder="$1" file="$2" limit="${3:-65}"
    local full="$folder/$file"
    if (( ${#full} <= limit )); then
      printf '%s' "$full"
      return
    fi
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
  # Minimal helpers (fallback if not already defined)
  wait_local_stable() {
    local path="$1" checks=3 delay=1
    [[ -f "$path" ]] || return 1
    local prev=-1 cur i
    for (( i=0; i<checks; i++ )); do
      cur=$(stat -c '%s' -- "$path" 2>/dev/null || echo -1)
      (( cur <= 0 )) && return 1
      if (( prev >= 0 && cur != prev )); then
        prev="$cur"; sleep "$delay"; ((i--)); continue
      fi
      prev="$cur"; sleep "$delay"
    done
    return 0
  }
  verify_download() {
    local local_file="$1"
    [[ -f "$local_file" ]] || return 1
    wait_local_stable "$local_file" || return 1
    return 0
  }
  while kill -0 "$pid" 2>/dev/null; do
    if [[ -f "$logfile_lftp" ]]; then
      i=$(((i+1) % ${#spin}))
      # 1) Parse ALL completed transfers (RETR ... then 226/Transfer complete), with their last CWD
      #    Emit one line per completed file (folder<TAB>file)
      while IFS=$'\t' read -r folder file; do
        # Normalize quotes/backslashes
        folder="${folder//\`/}"; folder="${folder//\"/}"; folder="${folder//\'/}"
        file="${file//\`/}";     file="${file//\"/}";     file="${file//\'/}"
        folder="${folder//\\//}"
        file="${file//\\//}"
        # >>> Guard: ignore incomplete entries that would generate "/"
        if [[ -z "$folder" || -z "$file" ]]; then
          continue
        fi
        local remote_path="$folder/$file"
        # Skip if already handled
        if [[ -n "${__SEEN_COMPLETED[$remote_path]}" ]]; then
          continue
        fi
        local print_file; print_file="$(shorten_path_term "$folder" "$file" 65)"
        local local_path="$LOCALDIR$remote_path"
        local size_h="~"; [[ -f "$local_path" ]] && size_h=$(numfmt --to=iec "$(stat -c%s "$local_path")")
        if verify_download "$local_path"; then
          printf "%s%s✔%s  Téléchargement terminé : %s %s\n" "$CLR" "$GREEN" "$RESET" "$print_file" "$size_h" >&2
          replace_or_append_line "$logfile_display" \
            "Téléchargement de $remote_path" \
            "✔ Téléchargement terminé : $remote_path $size_h"
          __SEEN_COMPLETED["$remote_path"]=1
          # --- Pushover: log aussi les téléchargements terminés ---
          if [[ -n "$logfile_pushover" ]]; then
            if [[ ! -e "$logfile_pushover" ]]; then
              echo -e "<b>Téléchargements :</b>" > "$logfile_pushover"
            elif ! grep -q "<b>Téléchargements :</b>" "$logfile_pushover" 2>/dev/null; then
              echo -e "<b>Téléchargements :</b>" >> "$logfile_pushover"
            fi
            echo -e "$remote_path ($size_h)" >> "$logfile_pushover"
          fi
        else
          printf "%s%s✖%s  Téléchargement incomplet : %s\n" "$CLR" "$RED" "$RESET" "$print_file" >&2
          RETRY_LIST+=("$remote_path")
          replace_or_append_line "$logfile_display" \
            "Téléchargement de $remote_path" \
            "✖ Téléchargement incomplet : $remote_path"
        fi
      done < <(
        awk -v OFS='\t' '
          function trim(s){ sub(/^[ \t\r\n]+/,"",s); sub(/[ \t\r\n]+$/, "", s); return s }
          function isq(c){ return (c=="\"" || c=="`" || c==sprintf("%c",39)) }
          function stripq(s,   c1,cN){
            while (length(s)>0) { c1=substr(s,1,1); cN=substr(s,length(s),1);
              if (isq(c1)) s=substr(s,2);
              else if (isq(cN)) s=substr(s,1,length(s)-1);
              else break }
            return s
          }
          /CWD path to be sent is/ {
            s=$0; sub(/.*CWD path to be sent is[ \t]+/, "", s);
            cur=stripq(trim(s)); next
          }
          /(^|[ \t])RETR[ \t]+/ {
            f=$0; sub(/.*RETR[ \t]+/, "", f); f=stripq(trim(f));
            if (length(f) > 0) {  # push only if non-empty
              pending_f[pcount]=f; pending_d[pcount]=cur; pcount++;
            }
            next
          }
          /(^|[^0-9])226([^0-9]|$)/ || /Transfer complete/ {
            if (pcount>0) {
              # complete most recent pending
              print pending_d[pcount-1], pending_f[pcount-1];
              delete pending_d[pcount-1]; delete pending_f[pcount-1]; pcount--;
            }
            next
          }
        ' "$logfile_lftp"
      )
      printf "%s %s Téléchargement en cours ...   " "$CLR" "${spin:$i:1}" >&2
      sleep 0.2
    else
      sleep 0.2
    fi
  done
  # --------- Drain final : rattrape tout RETR vu et pas encore traité ---------
  if [[ -f "$logfile_lftp" ]]; then
    while IFS=$'\t' read -r folder file; do
      folder="${folder//\`/}"; folder="${folder//\"/}"; folder="${folder//\'/}"
      file="${file//\`/}";     file="${file//\"/}";     file="${file//\'/}"
      folder="${folder//\\//}"; file="${file//\\//}"
      [[ -z "$folder" || -z "$file" ]] && continue
      local remote_path="$folder/$file"
      [[ -n "${__SEEN_COMPLETED[$remote_path]}" ]] && continue
      local print_file; print_file="$(shorten_path_term "$folder" "$file" 65)"
      local local_path="$LOCALDIR$remote_path"
      local size_h="~"; [[ -f "$local_path" ]] && size_h=$(numfmt --to=iec "$(stat -c%s "$local_path")")
      if verify_download "$local_path"; then
        printf "%s✔  Téléchargement terminé : %s %s\n" "$CLR" "$print_file" "$size_h" >&2
        __SEEN_COMPLETED["$remote_path"]=1
        replace_or_append_line "$logfile_display" \
          "Téléchargement de $remote_path" \
          "✔ Téléchargement terminé : $remote_path $size_h"
        # Pushover
        if [[ -n "$logfile_pushover" ]]; then
          [[ -e "$logfile_pushover" ]] || echo -e "<b>Téléchargements :</b>" > "$logfile_pushover"
          grep -q "<b>Téléchargements :</b>" "$logfile_pushover" || echo -e "<b>Téléchargements :</b>" >> "$logfile_pushover"
          echo -e "$remote_path ($size_h)" >> "$logfile_pushover"
        fi
      else
        printf "%s✖  Téléchargement incomplet : %s\n" "$CLR" "$print_file" >&2
        RETRY_LIST+=("$remote_path")
        replace_or_append_line "$logfile_display" \
          "Téléchargement de $remote_path" \
          "✖ Téléchargement incomplet : $remote_path"
      fi
    done < <(
      # ⬇️ On sort TOUS les RETR avec leur CWD courant, sans regarder les 226
      awk -v OFS='\t' '
        function trim(s){ sub(/^[ \t\r\n]+/,"",s); sub(/[ \t\r\n]+$/, "", s); return s }
        function isq(c){ return (c=="\"" || c=="`" || c==sprintf("%c",39)) }
        function stripq(s,   c1,cN){
          while (length(s)>0) { c1=substr(s,1,1); cN=substr(s,length(s),1);
            if (isq(c1)) s=substr(s,2);
            else if (isq(cN)) s=substr(s,1,length(s)-1);
            else break }
          return s
        }
        /CWD path to be sent is/ {
          s=$0; sub(/.*CWD path to be sent is[ \t]+/, "", s);
          cur=stripq(trim(s)); next
        }
        /(^|[ \t])RETR[ \t]+/ {
          f=$0; sub(/.*RETR[ \t]+/, "", f); f=stripq(trim(f));
          if (length(f)>0 && length(cur)>0) print cur, f;
          next
        }
      ' "$logfile_lftp"
    )
  fi
  # --- Résumé final ---
  if [[ -f "$logfile_lftp" && -f "$logfile_display" ]]; then
    local total_expected ok_count retry_ok retry_fail final_ok
    total_expected=$(awk '/(^|[ \t])RETR[ \t]+/ {c++} END{print c+0}' "$logfile_lftp")
    if ! ok_count=$(grep -a -c '^✔ Téléchargement terminé' "$logfile_display" 2>/dev/null); then ok_count=0; fi
    if ! retry_ok=$(grep -a -c '^  ✔ RETRY OK' "$logfile_display" 2>/dev/null); then retry_ok=0; fi
    if ! retry_fail=$(grep -a -c '^  ✖ RETRY KO' "$logfile_display" 2>/dev/null); then retry_fail=0; fi
    ok_count=${ok_count//$'\n'/}
    retry_ok=${retry_ok//$'\n'/}
    retry_fail=${retry_fail//$'\n'/}
    final_ok=$(( ok_count + retry_ok ))
    local plural=""
    (( total_expected > 1 )) && plural="s"
    {
      echo ""
      printf '   Résumé : %d/%d fichier%s OK (%d retry, %d échec)\n' "$final_ok" "$total_expected" "$plural" "$retry_ok" "$retry_fail"
    } | tee -a "$logfile_display"
  fi
  tput cnorm
}


## Automatic file renaming function if existing
rename_if_exists() {
  local file="$1"
  [[ -n "$file" && -e "$file" ]] || { return 1; }
  local dir stem base ext
  dir=$(dirname -- "$file")
  stem=$(basename -- "$file")
  base="${stem%.*}"
  ext="${stem##*.}"
  [[ "$base" == "$stem" ]] && ext="" || ext=".$ext"
  # Sauvegarder/restaurer l'état de nullglob pour éviter des effets de bord
  local old_nullglob; old_nullglob=$(shopt -p nullglob); shopt -s nullglob
  local nums=() f n name name_no_ext
  for f in "$dir/$base".[0-9]*"$ext"; do
    name="$(basename -- "$f")"                  # ex: base.12.ext
    name_no_ext="$name"
    [[ -n "$ext" ]] && name_no_ext="${name%$ext}" # -> base.12
    n="${name_no_ext##*.}"                      # -> 12
    [[ "$n" =~ ^[0-9]+$ ]] && nums+=("$n")
  done
  if ((${#nums[@]})); then
    IFS=$'\n' nums=($(printf '%s\n' "${nums[@]}" | sort -n)); IFS=$' \t\n'
    for (( i=${#nums[@]}-1; i>=0; i-- )); do
      n="${nums[i]}"
      mv -- "$dir/$base.$n$ext" "$dir/$base.$((n+1))$ext"
    done
  fi
  eval "$old_nullglob"
  mv -- "$file" "$dir/$base.1$ext"
}
rename_if_exists "$logfile_display"
rename_if_exists "$logfile_lftp"
touch "$logfile_display"
touch "$logfile_lftp"
chmod 600 "$logfile_display"
chmod 600 "$logfile_lftp"


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
EXCLUDED="Thumbs.db|Licence NP6"
 
#### Paramètres Pushover
## ces réglages se trouvent sur le site http://www.pushover.net
token_app=""
target_1=""
target_2=""
 
#### Paramètre Discord
## Webhook URL pour la prise en charge de Discord
WEBHOOK_URL=""
 
#### UI tags pour customisation
ui_tag_ok=""
ui_tag_bad=""
ui_tag_warning="️"
 
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
  import_source_conf
fi
is_wsl() {
  if grep -qi microsoft /proc/version 2>/dev/null; then
    return 0
  else
    return 1
  fi
}
if is_wsl; then
  eval 'echo -e "$ui_tag_ok Script lancé sous WSL"' $logfile_display_cmd
else
  eval 'echo -e "$ui_tag_ok Script lancé sous Linux natif"' $logfile_display_cmd
fi
eval 'echo ""' $logfile_display_cmd


check_dependencies


### Check update
this_script=$(realpath -s "$0")
if curl -m 2 --head --silent --fail "$script_remote" 2>/dev/null >/dev/null; then
  md5_local=`md5sum "$this_script" | cut -f1 -d" " 2>/dev/null`
  md5_remote=`curl -s "$script_remote" | md5sum | cut -f1 -d" "`
  if [[ "$md5_local" != "$md5_remote" ]]; then
    eval 'echo -e "$ui_tag_warning  Une nouvelle version du script est disponible..."' $logfile_display_cmd
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
# Normalize exclusion patterns:
# - If EXCLUDED already contains "-x", use as-is
# - Else if it's a pipe-separated list "a|b c", convert to "-x a -x 'b c'"
EXCLUDED_ARGS=""
if [[ -n "$EXCLUDED" ]]; then
  if [[ "$EXCLUDED" == *"-x"* ]]; then
    EXCLUDED_ARGS="$EXCLUDED"
  else
    EXCLUDED_ARGS="$(make_excludes "$EXCLUDED")"
  fi
fi
# Show what will be applied
if [[ -n "$EXCLUDED_ARGS" ]]; then
  eval 'echo "$ui_tag_ok Exclusions appliquées : '"'"'$EXCLUDED_ARGS'"'"'"' $logfile_display_cmd
else
  eval 'echo "$ui_tag_ok Aucune exclusion appliquée"' $logfile_display_cmd
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
    lftp -u $LOGIN,$PASSWORD $HOST -d -e "mirror --delete $EXCLUDED_ARGS '$REMOTEDIR' '$LOCALDIR$REMOTEDIR' ; quit" > $logfile_lftp 2>&1 & downloading_loading $!
  else
    eval 'echo -e "$ui_tag_warning Suppression des fichiers/dossiers inutiles désactivé"' $logfile_display_cmd
    lftp -u $LOGIN,$PASSWORD $HOST -d -e "mirror $EXCLUDED_ARGS '$REMOTEDIR' '$LOCALDIR$REMOTEDIR' ; quit" > $logfile_lftp 2>&1 & downloading_loading $!
  fi
  if [[ "$(cat $logfile_lftp | grep "Login failed")" != "" ]]; then
    eval 'echo -e "$ui_tag_bad Connexion echouée: LOGIN et/ou PASSWORD incorect(s)"' $logfile_display_cmd
    pushover_message=`echo -e "[ <b>SYNCHRONISATION ÉCHOUÉE</b> ]\n💻 $(hostname)\nLOGIN et/ou PASSWORD incorect(s)"`
    if [[ -n "$WEBHOOK_URL" ]]; then discord-message "$pushover_message"; fi
    push-message "$pushover_message" "1"
  else
    # --- Retry pass for incomplete files recorded by downloading_loading ---
    if ((${#RETRY_LIST[@]} > 0)); then
      # dédoublonne
      mapfile -t __RETRY_UNIQ < <(printf '%s
' "${RETRY_LIST[@]}" | awk 'NF' | sort -u)
      eval 'echo -e "🔁 Relance de ${#__RETRY_UNIQ[@]} fichier(s) incomplet(s)..."' $logfile_display_cmd
      for remote_path in "${__RETRY_UNIQ[@]}"; do
        rel="${remote_path#$REMOTEDIR/}"
        local_path="$LOCALDIR$REMOTEDIR/$rel"
        dest_dir="$(dirname -- "$local_path")"
        mkdir -p -- "$dest_dir"
        lftp -u "$LOGIN","$PASSWORD" "$HOST" \
          -e "pget -n 8 -c -O '$dest_dir' -- '$remote_path' ; bye" >> "$logfile_lftp" 2>&1
        if verify_download "$local_path"; then
          eval 'echo -e "  ✔ RETRY OK  '$remote_path' ($(numfmt --to=iec $(stat -c%s \"'$local_path'\" 2>/dev/null || echo 0)))"' $logfile_display_cmd
          sed -i "s#✖ Téléchargement incomplet : $remote_path#✔ Téléchargement terminé : $remote_path $(numfmt --to=iec $(stat -c%s \"$local_path\" 2>/dev/null || echo 0))#g" "$logfile_display"
          if [[ -n "$logfile_pushover" ]]; then
            [[ -e "$logfile_pushover" ]] || echo -e "<b>Téléchargements :</b>" > "$logfile_pushover"
            grep -q "<b>Téléchargements :</b>" "$logfile_pushover" || echo -e "<b>Téléchargements :</b>" >> "$logfile_pushover"
            echo -e "$remote_path ($(numfmt --to=iec $(stat -c%s "$local_path" 2>/dev/null || echo 0)))" >> "$logfile_pushover"
          fi
        else
          eval 'echo -e "  ✖ RETRY KO  '$remote_path'"' $logfile_display_cmd
        fi
      done
    fi
    # --- End retry pass ---
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
