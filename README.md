# synchro_Iway

Pour installer le script une ligne suffit :
* wget --header="Authorization: token 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" --header="Accept: application/vnd.github.v3.raw" https://raw.githubusercontent.com/Z0uZOU/synchro_Iway/main/synchro_Iway.sh && chmod +x synchro_Iway.sh

Pour créer une tâche planifiée sous Windows avec WSL2 :
* schtasks /Create /TN "MaSynchro" /TR "wsl.exe -d Ubuntu bash -c '/home/zouzou/synchro_Iway.sh'" /SC DAILY /ST 08:00
