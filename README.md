# synchro_Iway

Pour installer le script une ligne suffit :
* wget -O synchro_Iway.sh "https://raw.githubusercontent.com/Z0uZOU/synchro_Iway/refs/heads/main/synchro_Iway.sh" && chmod +x synchro_Iway.sh

Pour créer une tâche planifiée sous Windows avec WSL2 :
* schtasks /Create /TN "MaSynchro" /TR "wsl.exe -d Ubuntu bash -c '/home/zouzou/synchro_Iway.sh'" /SC DAILY /ST 08:00
