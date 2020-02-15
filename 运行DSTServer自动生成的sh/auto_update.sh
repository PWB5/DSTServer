#!/bin/bash
	 
	DST_game_beta="Public"
	cluster_name="3MC"
	DST_conf_dirname="DoNotStarveTogether"  
	DST_temp_path="/root/Dstupdatecheck"
	DST_conf_basedir="/root/.klei"
function update_temp_game()
	{
	    DST_now=$(date +"%D %T")
	    echo "${DST_now}：同步服务端更新进程正在运行..."
	    cd ./steamcmd
	    if [[ ${DST_game_beta} != "Public" ]]; then
		    echo "正在同步测试版游戏服务端。"	
		    ./steamcmd.sh +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +force_install_dir "$HOME/Dstupdatecheck/branch_ANewReignBeta" +app_update 343050 -beta anewreignbeta validate +quit
			cp "$HOME/Dstupdatecheck/branch_ANewReignBeta/version.txt" "$HOME/Dstupdatecheck/branch_ANewReignBeta/version4updater.txt"	
		else
	        echo "正在同步正式版游戏服务端。"		
		    ./steamcmd.sh +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +force_install_dir "$HOME/Dstupdatecheck/branch_Public" +app_update 343050 validate +quit 
		    cp "$HOME/Dstupdatecheck/branch_Public/version.txt" "$HOME/Dstupdatecheck/branch_Public/version4updater.txt"
	    fi
		
	    echo "${DST_now}：服务端已完毕同步。"	
	    cd $HOME	
	}

	function update_shutdown()
	{   DST_now=$(date +"%D %T")
	    echo -e "\e[36m\e[1m${DST_now}：准备关服，\e[0m \e[36m正在获取服务器中的玩家数量并发送更新公告...\e[0m"
		randomness=$( date +%s%3N )
	    if [[ $(screen -ls | grep -c "DST_Master") > 0 ]]; then	
		    screen -S "DST_Master" -p 0 -X stuff "c_printplayersnumber(${randomness})$(printf \\r)"
		fi
		sleep 5
		if [[ $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
		    screen -S "DST_Caves" -p 0 -X stuff "c_printplayersnumber(${randomness})$(printf \\r)"						
		fi
		sleep 5
		if [[ $(screen -ls | grep -c "DST_Master") > 0 ]]; then
		    numplayersmaster=$( grep "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_log.txt" -e "^.*:.*:.*: PrintPlayersNumber:${randomness}:.*:END" | cut -f6 -d":" )									        
		    screen -S "DST_Master" -p 0 -X stuff "c_announce(\"感谢你在本服务器玩耍，服务器将于一分钟后关闭进行更新，预计耗时三分钟！\")$(printf \\r)"
		    DST_now=$(date +"%D %T")
		    echo "${DST_now}：服务器中还有 "${numplayersmaster}" 名玩家。"		
		fi
		if [[ $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
		    numplayerscaves=$( grep "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_log.txt" -e "^.*:.*:.*: PrintPlayersNumber:${randomness}:.*:END" | cut -f6 -d":" )						        
			screen -S "DST_Caves" -p 0 -X stuff "c_announce(\"感谢你在本服务器玩耍，服务器将于一分钟后关闭进行更新，预计耗时三分钟！\")$(printf \\r)"
			DST_now=$(date +"%D %T")
			echo "${DST_now}：服务器中还有 "${numplayerscaves}" 名玩家。"
		fi
	    sleep 60	
	    if [[ $(screen -ls | grep -c "DST_Master") > 0 ]]; then
		    screen -S "DST_Master" -p 0 -X stuff "c_shutdown(true)$(printf \\r)"
		fi
		if [[ $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
		    screen -S "DST_Caves" -p 0 -X stuff "c_shutdown(true)$(printf \\r)"
		fi
		sleep 20
		if [[ $(screen -ls | grep -c "DST_Master") = 0 && $(screen -ls | grep -c "DST_Caves") = 0 ]]; then
		    DST_now=$(date +"%D %T")
		    echo "${DST_now}：服务器已关闭。"
			update_game
		fi
	}

	function auto_update()
	{	
		DST_now=$(date +"%D %T")
	    echo "${DST_now}：服务器自动更新检查进程正在运行..."
		if [[ $(screen -ls | grep -c "DST_Master") > 0 ]]; then
		    if [[ $(grep "is out of date and needs to be updated for new users to be able to join the server" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_chat_log.txt") > 0 ]]; then
			    DST_has_mods_update=true
			    DST_now=$(date +"%D %T")
			    echo -e "\e[93m${DST_now}: Mod 有更新！\e[0m"
		    else
			    DST_has_mods_update=false
			    echo -e "\e[92m${DST_now}: Mod 没有更新!\e[0m"
			fi
		fi
	    if [[ $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
		    if [[ $(grep "is out of date and needs to be updated for new users to be able to join the server" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_chat_log.txt") > 0 ]]; then
			    DST_has_mods_update=true
			    DST_now=$(date +"%D %T")
			    echo -e "\e[93m${DST_now}: Mod 有更新！\e[0m"
		    else
			    DST_has_mods_update=false
			    echo -e "\e[92m${DST_now}: Mod 没有更新!\e[0m"
			fi
		fi
		if [[ -f "${DST_temp_path}/branch_${DST_game_beta}/version4updater.txt" ]]; then
			if flock "${DST_temp_path}/branch_${DST_game_beta}/version4updater.txt" -c "! diff -q "${DST_temp_path}/branch_${DST_game_beta}/version4updater.txt" "$HOME/Steam/steamapps/common/DST_${DST_game_beta}/version.txt" > /dev/null" ; then
			    DST_now=$(date +"%D %T")
			    DST_has_game_update=true
			    echo -e "\e[93m${DST_now}：游戏服务端有更新!\e[0m"				
			else
			    DST_has_game_update=false
				echo -e "\e[92m${DST_now}：游戏服务端没有更新!\e[0m"
			fi
		else
			echo -e "\e[31m\e[1m警告: 没有找到文件 ${DST_temp_path}/branch_${DST_game_beta}/version4updater.txt\e[0m"
			echo -e "\e[31m等待下一次循环检查！\e[0m"		
			sleep 5
		fi	
		if [[ "$DST_has_mods_update" == true || "$DST_has_game_update" == true ]]; then 
		    update_shutdown
		fi
	}

	function update_game()
	{
	    echo "更新游戏服务端!"
		cd ./steamcmd
	    if [[ ${DST_game_beta} != "Public" ]]; then
		    echo "游戏服务端版本为测试版！"
		    ./steamcmd.sh +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +force_install_dir "$HOME/Steam/steamapps/common/DST_ANewReignBeta" +app_update 343050 -beta anewreignbeta validate +quit
		else
	        echo "游戏服务端版本为正式版！"	
		    ./steamcmd.sh +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +force_install_dir "$HOME/Steam/steamapps/common/DST_Public" +app_update 343050 validate +quit 
	    fi
		cd $HOME
		echo "更新完毕!"
	}

	function processkeep()
	{
	    DST_now=$(date +"%D %T")
	    echo "${DST_now}：服务器进程保持开启检查正在运行..."
	    if [[ $(screen -ls | grep -c "DST_Caves") > 0 || $(screen -ls | grep -c "DST_Master") > 0 ]]; then
		    DST_now=$(date +"%D %T")
			echo "${DST_now}: 服务器已开启!"
		else
		    DST_now=$(date +"%D %T")
			echo "${DST_now}: 服务器未开启!"
		    cd $HOME
		    ./rebootserver.sh
			sleep 10
			echo "服务器已重启。"
		fi			
	}
	while :
	do
	    # clear
	    echo -e "\e[33m欢迎使用饥荒联机版独立服务器脚本[Ubuntu-Steam]\e[0m"
	    update_temp_game
		sleep 60
	    auto_update
	    sleep 60
	    processkeep
		DST_now=$(date +"%D %T")
		echo -e "\e[31m${DST_now}: 半小时后进行下一次循环检查！\e[0m"
		sleep 1800
	done
