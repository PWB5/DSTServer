#!/bin/bash
		# echo "" > "/root/Steam/steamapps/common/DST_Public/mods/dedicated_server_mods_setup.lua"
		# cp "/root/.klei/DoNotStarveTogether/mods_setup.lua" "/root/Steam/steamapps/common/DST_Public/mods/dedicated_server_mods_setup.lua"
		cd /root/Steam/steamapps/common/DST_Public/bin
		screen -dmS "DST_Master" /bin/sh -c "./dontstarve_dedicated_server_nullrenderer -console -conf_dir DoNotStarveTogether -cluster 3MC -shard Master"
		screen -dmS "DST_Caves" /bin/sh -c "./dontstarve_dedicated_server_nullrenderer -console -conf_dir DoNotStarveTogether -cluster 3MC -shard Caves"
		echo -e "\E[33m正在重启服务器...请稍后.\c\e[0m"
		sleep 1
		

		cd $HOME
		if [[ $(screen -ls | grep -c "DST_autoupdate") == 0 ]]; then
		    screen -dmS "DST_autoupdate" /bin/sh -c "./auto_update.sh"
		fi
		sleep 3
		./Startcheck.sh
		
