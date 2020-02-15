#!/bin/bash
#-------------------------------------------------------------------------------------------
#Tendy 2017.01.20
#Bug反馈：QQ1113787381
#需配合putty和winscp或者Xshell使用
#首次使用上传脚本至用户目录并给予执行权限
#云服务器系统须安装ubuntu系统(linux发行版本)                                                                        
#-------------------------------------------------------------------------------------------
#V1.0.1 19/02/19
# 初版
#-------------------------------------------------------------------------------
# 脚本变量
DST_conf_dirname="DoNotStarveTogether"   
DST_conf_basedir="$HOME/.klei" 
DST_bin_cmd="./dontstarve_dedicated_server_nullrenderer"   

function PreLibrary()
{
	sudo apt-get -y update
	sudo apt-get -y install screen
	sudo apt-get -y install lib32gcc1
    sudo apt-get -y install lib32stdc++6 
	sudo apt-get -y install libcurl4-gnutls-dev:i386
	sudo apt-get -y install htop
	sudo apt-get -y install diffutils 
	sudo apt-get -y install grep
}

function update_game()
{
    if [ ! -d "./steamcmd" ];then
   	    PreLibrary
	    mkdir ./steamcmd
        cd ./steamcmd
        wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
        tar -xvzf steamcmd_linux.tar.gz
        rm -f steamcmd_linux.tar.gz
		cd $HOME
	fi
	cd ./steamcmd
    if [[ ${DST_game_beta} != "Public" ]]; then
	    echo "游戏服务端版本为测试版！"
	    ./steamcmd.sh +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +force_install_dir "$HOME/Steam/steamapps/common/DST_ANewReignBeta" +app_update 343050 -beta anewreignbeta validate +quit
	else
        echo "游戏服务端版本为正式版！"	
	    ./steamcmd.sh +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +force_install_dir "$HOME/Steam/steamapps/common/DST_Public" +app_update 343050 validate +quit 
    fi
	cd $HOME
}

function setupmod()
{
    echo "ServerModSetup(\"815489374\")
ServerModSetup(\"367546858\")
ServerModSetup(\"572538624\")" > "${DST_conf_basedir}/${DST_conf_dirname}/mods_setup.lua"
    dir=$(ls -l "$HOME/Steam/steamapps/common/DST_${DST_game_beta}/mods" |awk '/^d/ {print $NF}'|grep "workshop"|cut -f2 -d"-")
    for modid in $dir
    do
	    if [[ $(grep "$modid" -c "${DST_conf_basedir}/${DST_conf_dirname}/mods_setup.lua") > 0 ]] ;then 
		    echo "" >> "${DST_conf_basedir}/${DST_conf_dirname}/mods_setup.lua"
		else	
            echo "ServerModSetup(\"$modid\")" >> "${DST_conf_basedir}/${DST_conf_dirname}/mods_setup.lua"
		fi
    done	
}

function closeserver()
{
    if [[ $(screen -ls | grep -c "DST_Master") > 0 || $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
	    if [[ $(screen -ls | grep -c "DST_Master") > 0 ]]; then
            screen -S "DST_Master" -p 0 -X stuff "c_shutdown(true)$(printf \\r)"
	    fi
	    if [[ $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
            screen -S "DST_Caves" -p 0 -X stuff "c_shutdown(true)$(printf \\r)"
	    fi
	    sleep 10
	    echo -e "\e[92m服务器已关闭！\e[0m"
	else
	    echo "游戏服务器未开启！"
	fi
}


function savelog()
{
    if [ ! -d "${DST_conf_basedir}/backup" ]
	    then 
		    mkdir -p ${DST_conf_basedir}/backup
	fi
	if [ ! -d "${DST_conf_basedir}/backup/log_archive" ]
	    then 
		    mkdir -p ${DST_conf_basedir}/backup/log_archive
	fi
    if [ -f "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_chat_log.txt" ]; then
		echo "保存聊天日志。。。"
		DST_now=$(date +"%D %T")
		echo "${DST_now}" >> "${DST_conf_basedir}/backup/log_archive/server_chat_log.save.txt"
		cat "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_chat_log.txt" >> "${DST_conf_basedir}/backup/log_archive/server_chat_log.save.txt"
	fi
	
	echo "删除旧的服务器日志。。。"
	find "${DST_conf_basedir}/backup/log_archive/server_log."*".txt" -mtime + 20 -delete 2>/dev/null
	logs_size=$( find "${DST_conf_basedir}/backup/log_archive/server_log."*".txt" -mtime -1 -printf "%s\n" 2>/dev/null | awk '{t+=$1}END{print t}' )
	if [[ ${logs_size} =~ ^-?[0-9]+$ ]]; then 
	    logs_size_Mo=$(( ${logs_size} / 1048576 ))					
	    if [[ $logs_size_Mo > 50 ]]; then
	        echo -e "\e[31m\e[1m警告: 服务器日志存储过多，删除所有服务器日志。。。\e[0m"
	        find "${DST_conf_basedir}/backup/log_archive/server_log."*".txt" -delete 2>/dev/null
            rm "${DST_conf_basedir}/backup/log-updater.txt"
	        DST_now=$(date +"%D %T")
	        echo "${DST_now}: 服务器日志存储过多，删除所有服务器日志。"
		fi
	fi
			
	if [ -f "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_log.txt" ]; then
	    echo -e "保存服务器日志。。。"
		DST_timestamp=$(date +"%s")
		mkdir "${DST_conf_basedir}/backup/log_archive" 2&>/dev/null
		cat "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_log.txt" > "${DST_conf_basedir}/backup/log_archive/server_log.${DST_timestamp}.txt"
	fi
}


function settoken()
{
    echo -e "\e[92m是否使用预设服务器令牌：1.是 2.否 \e[0m"
    read isreset
	case $isreset in 	
		1)
		echo "xyXThBqSds+ku7ObcWRS1gbH/GlXdtKZ" > "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/cluster_token.txt" ;;
		2)
		echo -e "\e[92m请输入你的服务器令牌：（提示：在输入框右键鼠标可以粘贴。）\e[0m"
		read token
		echo "$token" > "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/cluster_token.txt" ;;
	esac
	echo "服务器令牌设置完毕！"
}

function setcluster()
{
    echo "" > "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/cluster.ini"
    echo -e "\e[92m是否为Steam群组服务器：1.是 2.否 \e[0m"
    read isgroup
    case $isgroup in 
        1)	
		echo -e "\e[92m群组官员是否设为管理员：1.是 2.否\e[0m"
        read isadmin
		case $isadmin in
		    1)
			steamgroupadmins="true";;
            2)
			steamgroupadmins="false";;
        esac
		echo -e "\e[92m请输入Steam群组ID:\e[0m"
		read steamgroupid
		echo -e "\e[92m服务器是否设为仅Steam群组成员可进：1.是 2.否\e[0m"
		read isonly
		case $isonly in
		    1)
			steamgrouponly="true";;
            2)
			steamgrouponly="false";;
		    esac
	    echo "[STEAM]
steam_group_admins = $steamgroupadmins
steam_group_id = $steamgroupid
steam_group_only = $steamgrouponly

" >> "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/cluster.ini";;
       2)
	   echo "" >> "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/cluster.ini";;
	esac
    echo -e "\e[92m请选择游戏模式：1.无尽 2.生存 3.荒野\e[0m"
    read choosemode
    case $choosemode in
        1)
		gamemode="endless";;
        2)
		gamemode="survival";;
        3)
		gamemode="wilderness";;
    esac

    echo -e "\e[92m请输入最大玩家数量：\e[0m"
    read players

    echo -e "\e[92m是否开启PVP：1.是 2.否\e[0m"
    read ispvp
    case $ispvp in
        1)
		ifpvp="true";;
        2)
		ifpvp="false";;
    esac
	
echo "[GAMEPLAY]
game_mode = $gamemode
max_players = $players
pvp = $ifpvp
pause_when_empty = true

" >> "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/cluster.ini"

    echo -e "\e[92m请选择游戏风格：1.休闲 2.合作 3.竞赛 4.疯狂\e[0m"
    read intent
    case $intent in
        1)
        intention="social";;
        2)
        intention="cooperative";;
        3)
        intention="competitive";;
        4)
        intention="madness";;
    esac
	
    echo -e "\e[92m请输入服务器介绍：PS：若无请按Enter键\e[0m"
    read description

	echo -e "\e[92m请输入服务器名字：\e[0m"
    read name
	
	echo -e "\e[92m请输入服务器密码：PS：若无请按Enter键\e[0m"
    read password
	
    echo "[NETWORK]
lan_only_cluster = false
cluster_intention = $intention
cluster_description = $description
cluster_name = $name
offline_cluster = false
cluster_password = $password

" >> "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/cluster.ini"

    echo "[MISC]
console_enabled = true

" >> "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/cluster.ini"

    echo -e "\e[92m请选择服务器开启模式：1.只搭建地上或者洞穴世界 2.同时搭建地上和洞穴世界\e[0m"
    read servermode
	case $servermode in
	    1)
		echo -e "\e[92m请输入主世界外网IP:\e[0m"
		read masterip
		echo "[SHARD]
shard_enabled = true
bind_ip = 0.0.0.0
master_ip = $masterip
master_port = 10888
cluster_key = defaultPass

" >> "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/cluster.ini";;
        2)
		echo "[SHARD]
shard_enabled = true
bind_ip = 127.0.0.1
master_ip = 127.0.0.1
master_port = 10888
cluster_key = defaultPass

" >> "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/cluster.ini";;
	esac
    clear
    echo "房间信息配置完成！"
} 

function setserverini()
{
    if [ ! -d "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master" ]
	    then 
		    mkdir -p ${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master
			echo "[NETWORK]
server_port = 10999


[SHARD]
is_master = true
name = Master
id = 1


[STEAM]
master_server_port = 27019
authentication_port = 8769" > "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server.ini"			
	    fi
	if [ ! -d "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves" ]
	then 
	    mkdir -p ${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves
        echo "[NETWORK]
server_port = 10998


[SHARD]
is_master = false
name = Caves
id = 2


[STEAM]
master_server_port = 27018
authentication_port = 8768" > "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server.ini"
	fi
}

function movemod()
{	

	if [ ! -d "$HOME/Steam/steamapps/common/DST_Public/mods" ]
	then 
		mkdir -p $HOME/Steam/steamapps/common/DST_Public/mods
	fi
	if [ ! -d "$HOME/Steam/steamapps/common/DST_ANewReignBeta/mods" ]
	then 
		mkdir -p $HOME/Steam/steamapps/common/DST_ANewReignBeta/mods
	fi
	cp -r "$HOME/Steam/steamapps/common/DST_ANewReignBeta/mods" "$HOME/Steam/steamapps/common/DST_Public"
	cp -r "$HOME/Steam/steamapps/common/DST_Public/mods" "$HOME/Steam/steamapps/common/DST_ANewReignBeta"
}

function startserver()
{
    if [ ! -d "${DST_conf_basedir}/${DST_conf_dirname}" ]
	then 
		mkdir -p ${DST_conf_basedir}/${DST_conf_dirname}
	fi
	closeserver
	sudo killall screen
    echo -e "\e[92m是否新建存档：1.是  2.否\e[0m"
	read isnew
	case $isnew in
	    1)
		echo -e "\e[92m请输入存档名称：（不要包含中文）\e[0m"
		read clustername
		cluster_name=$clustername
		if [ ! -d "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}" ]
	    then 
		    mkdir -p ${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}
	    fi
		setcluster
		settoken
		createlistfile
		setserverini
		setworld
		echo -e "\e[92m是否设置管理员和黑名单：1.是  2.否\e[0m"
		read setlist
		case $setlist in  
		    1)
			listmanager;;
		esac
		;;
		2)
		echo -e "\e[92m已有存档：\e[0m"
		ls -l ${DST_conf_basedir}/${DST_conf_dirname} |awk '/^d/ {print $NF}'
		echo -e "\e[92m请输入已有存档名称：（提示：在输入框右键鼠标可以粘贴。）\e[0m"
		read clustername
		cluster_name=$clustername		
		;;
	esac
	savelog
	echo -e "\e[92m请选择游戏版本：1.正式版  2.新的国度测试版\e[0m"
	read isbeta
	case $isbeta in
	    1)
		DST_game_beta="Public" ;;
		2)
		DST_game_beta="ANewReignBeta" ;;
	esac	
	echo -e "\e[92m启动前更新。。。请稍候。。。\e[0m"
	update_game
	movemod
	if [[ ! -f ${DST_conf_basedir}/${DST_conf_dirname}/$cluster_name/Master/modoverrides.lua ]]; then
        setupmod
		modadd
	    listallmod
        addmod
    fi
    cp "${DST_conf_basedir}/${DST_conf_dirname}/mods_setup.lua" "$HOME/Steam/steamapps/common/DST_${DST_game_beta}/mods/dedicated_server_mods_setup.lua"	
	cd "$HOME/Steam/steamapps/common/DST_${DST_game_beta}/bin"
	echo -e "\e[92m请选择要启动的服务器：1.仅地上  2.仅洞穴  3.地上 + 洞穴\e[0m"
	read shard 
	case $shard in
		1)		
		screen -dmS "DST_Master" /bin/sh -c "$DST_bin_cmd -console -conf_dir $DST_conf_dirname -cluster $cluster_name -shard Master"
		echo "#!/bin/bash
masterchatlog_path=\"${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_chat_log.txt\"
caveschatlog_path=\"${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_chat_log.txt\"			
echo \"\" > \"$HOME/Steam/steamapps/common/DST_${DST_game_beta}/mods/dedicated_server_mods_setup.lua\"	
cp \"${DST_conf_basedir}/${DST_conf_dirname}/mods_setup.lua\" \"$HOME/Steam/steamapps/common/DST_${DST_game_beta}/mods/dedicated_server_mods_setup.lua\"
cd $HOME/Steam/steamapps/common/DST_${DST_game_beta}/bin
screen -dmS \"DST_Master\" /bin/sh -c \"$DST_bin_cmd -console -conf_dir $DST_conf_dirname -cluster $cluster_name -shard Master\"
echo -e \"\e[92m正在重启服务器。。。请稍后。。。\e[0m\"
sleep 60" > $HOME/rebootserver.sh
        echo 'if [[ $(screen -ls | grep -c "DST_Master") = 0 && $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
    if [[ $(grep "Your Server Will Not Start !!!" -c "$masterchatlog_path") > 0 ]]; then
	    echo "服务器开启未成功，请执行关闭服务器命令后再次尝试，并注意令牌是否成功设置且有效。"
	else
		echo "服务器开启成功，和小伙伴尽情玩耍吧！"
    fi
else
	if [[ $(screen -ls | grep -c "DST_Master") > 0 ]]; then
        if [[ $(grep "Your Server Will Not Start !!!" -c "$masterchatlog_path") > 0 ]]; then
		    echo "服务器开启未成功，请执行关闭服务器命令后再次尝试，并注意令牌是否成功设置且有效。"
	    else
		    echo "服务器开启成功，和小伙伴尽情玩耍吧！"
		fi
	fi
	if [[ $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
        if [[ $(grep "Your Server Will Not Start !!!" -c "$caveschatlog_path") > 0 ]]; then
		    echo "服务器开启未成功，请执行关闭服务器命令后再次尝试，并注意令牌是否成功设置且有效。"
	    else
		    echo "服务器开启成功，和小伙伴尽情玩耍吧！"
	    fi
	fi
fi' >> $HOME/rebootserver.sh
		;;
		2)
		screen -dmS "DST_Caves" /bin/sh -c "$DST_bin_cmd -console -conf_dir $DST_conf_dirname -cluster $cluster_name -shard Caves"
		echo "#!/bin/bash
masterchatlog_path=\"${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_chat_log.txt\"
caveschatlog_path=\"${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_chat_log.txt\"
echo \"\" > \"$HOME/Steam/steamapps/common/DST_${DST_game_beta}/mods/dedicated_server_mods_setup.lua\"		
cp \"${DST_conf_basedir}/${DST_conf_dirname}/mods_setup.lua\" \"$HOME/Steam/steamapps/common/DST_${DST_game_beta}/mods/dedicated_server_mods_setup.lua\"
cd $HOME/Steam/steamapps/common/DST_${DST_game_beta}/bin
screen -dmS \"DST_Caves\" /bin/sh -c \"$DST_bin_cmd -console -conf_dir $DST_conf_dirname -cluster $cluster_name -shard Caves\"
echo -e \"\e[92m正在重启服务器。。。请稍后。。。\e[0m\"
sleep 60" > $HOME/rebootserver.sh
        echo 'if [[ $(screen -ls | grep -c "DST_Master") = 0 && $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
    if [[ $(grep "Your Server Will Not Start !!!" -c "$masterchatlog_path") > 0 ]]; then
	    echo "服务器开启未成功，请执行关闭服务器命令后再次尝试，并注意令牌是否成功设置且有效。"
	else
		echo "服务器开启成功，和小伙伴尽情玩耍吧！"
    fi
else
	if [[ $(screen -ls | grep -c "DST_Master") > 0 ]]; then
        if [[ $(grep "Your Server Will Not Start !!!" -c "$masterchatlog_path") > 0 ]]; then
		    echo "服务器开启未成功，请执行关闭服务器命令后再次尝试，并注意令牌是否成功设置且有效。"
	    else
		    echo "服务器开启成功，和小伙伴尽情玩耍吧！"
		fi
	fi
	if [[ $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
        if [[ $(grep "Your Server Will Not Start !!!" -c "$caveschatlog_path") > 0 ]]; then
		    echo "服务器开启未成功，请执行关闭服务器命令后再次尝试，并注意令牌是否成功设置且有效。"
	    else
		    echo "服务器开启成功，和小伙伴尽情玩耍吧！"
	    fi
	fi
fi' >> $HOME/rebootserver.sh
		;;
		3)
		screen -dmS "DST_Master" /bin/sh -c "$DST_bin_cmd -console -conf_dir $DST_conf_dirname -cluster $cluster_name -shard Master"
		screen -dmS "DST_Caves" /bin/sh -c "$DST_bin_cmd -console -conf_dir $DST_conf_dirname -cluster $cluster_name -shard Caves"
		echo "#!/bin/bash
masterchatlog_path=\"${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_chat_log.txt\"
caveschatlog_path=\"${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_chat_log.txt\"
echo \"\" > \"$HOME/Steam/steamapps/common/DST_${DST_game_beta}/mods/dedicated_server_mods_setup.lua\"		
cp \"${DST_conf_basedir}/${DST_conf_dirname}/mods_setup.lua\" \"$HOME/Steam/steamapps/common/DST_${DST_game_beta}/mods/dedicated_server_mods_setup.lua\"
cd $HOME/Steam/steamapps/common/DST_${DST_game_beta}/bin
screen -dmS \"DST_Master\" /bin/sh -c \"$DST_bin_cmd -console -conf_dir $DST_conf_dirname -cluster $cluster_name -shard Master\"
screen -dmS \"DST_Caves\" /bin/sh -c \"$DST_bin_cmd -console -conf_dir $DST_conf_dirname -cluster $cluster_name -shard Caves\"
echo -e \"\e[92m正在重启服务器。。。请稍后。。。\e[0m\"
sleep 60" > $HOME/rebootserver.sh
        echo 'if [[ $(screen -ls | grep -c "DST_Master") = 0 && $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
    if [[ $(grep "Your Server Will Not Start !!!" -c "$masterchatlog_path") > 0 ]]; then
	    echo "服务器开启未成功，请执行关闭服务器命令后再次尝试，并注意令牌是否成功设置且有效。"
	else
		echo "服务器开启成功，和小伙伴尽情玩耍吧！"
    fi
else
	if [[ $(screen -ls | grep -c "DST_Master") > 0 ]]; then
        if [[ $(grep "Your Server Will Not Start !!!" -c "$masterchatlog_path") > 0 ]]; then
		    echo "服务器开启未成功，请执行关闭服务器命令后再次尝试，并注意令牌是否成功设置且有效。"
	    else
		    echo "服务器开启成功，和小伙伴尽情玩耍吧！"
		fi
	fi
	if [[ $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
        if [[ $(grep "Your Server Will Not Start !!!" -c "$caveschatlog_path") > 0 ]]; then
		    echo "服务器开启未成功，请执行关闭服务器命令后再次尝试，并注意令牌是否成功设置且有效。"
	    else
		    echo "服务器开启成功，和小伙伴尽情玩耍吧！"
	    fi
	fi
fi' >> $HOME/rebootserver.sh
		;;
	esac
	chmod u+x $HOME/rebootserver.sh
	echo -e "\e[92m服务器开启中。。。请稍候。。。\e[0m"
	sleep 5
    auto_update_process
	sleep 60
	startcheck
	menu
}

function auto_update_process()
{
    cd $HOME
	echo "#!/bin/bash
	 
DST_game_beta=\"$DST_game_beta\"
cluster_name=\"$cluster_name\"
DST_conf_dirname=\"$DST_conf_dirname\"  
DST_temp_path=\"$HOME/Dstupdatecheck\"
DST_conf_basedir=\"$DST_conf_basedir\"" > $HOME/auto_update.sh

    echo 'function update_temp_game()
{
    DST_now=$(date +"%D %T")
    echo "${DST_now}：同步服务端更新进程正在运行。。。"
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
	
    echo "${DST_now}：服务端已完成同步。"	
    cd $HOME	
}

function update_shutdown()
{   DST_now=$(date +"%D %T")
    echo -e "\e[36m\e[1m${DST_now}：准备关服，\e[0m \e[36m正在获取服务器中的玩家数量并发送更新公告。。。\e[0m"
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
    echo "${DST_now}：服务器自动更新检查进程正在运行。。。"
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
	echo "更新完成!"
}

function processkeep()
{
    DST_now=$(date +"%D %T")
    echo "${DST_now}：服务器进程保持开启检查正在运行。。。"
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
    clear
    echo -e "\e[33m欢迎使用饥荒联机版独立服务器脚本[Ubuntu-Steam]\e[0m"
    update_temp_game
	sleep 60
    auto_update
    sleep 60
    processkeep
	DST_now=$(date +"%D %T")
	echo -e "\e[31m${DST_now}: 半小时后进行下一次循环检查！\e[0m"
	sleep 1800
done' >> $HOME/auto_update.sh
	chmod u+x $HOME/auto_update.sh
	screen -dmS "DST_autoupdate" /bin/sh -c "./auto_update.sh"
}

function startcheck()
{
	if [[ $(screen -ls | grep -c "DST_Master") = 0 && $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
        if [[ $(grep "Your Server Will Not Start !!!" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_chat_log.txt") > 0 ]]; then
		    echo "服务器开启未成功，请执行关闭服务器命令后再次尝试，并注意令牌是否成功设置且有效。"
	    else
		    echo "服务器开启成功，和小伙伴尽情玩耍吧！"
		fi
	else
	    if [[ $(screen -ls | grep -c "DST_Master") > 0 ]]; then
            if [[ $(grep "Your Server Will Not Start !!!" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_chat_log.txt") > 0 ]]; then
		        echo "服务器开启未成功，请执行关闭服务器命令后再次尝试，并注意令牌是否成功设置且有效。"
	        else
		        echo "服务器开启成功，和小伙伴尽情玩耍吧！"
		    fi
	    fi
	    if [[ $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
            if [[ $(grep "Your Server Will Not Start !!!" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_chat_log.txt") > 0 ]]; then
		        echo "服务器开启未成功，请执行关闭服务器命令后再次尝试，并注意令牌是否成功设置且有效。"
	        else
		        echo "服务器开启成功，和小伙伴尽情玩耍吧！"
		    fi
	    fi
	fi
}

function checkserver()
{    
	if [[ $(screen -ls | grep -c "DST_Master") > 0 || $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
	    echo -e "\e[92m即将跳转游戏服务器窗口，要退回本界面，在游戏服务器窗口按 ctrl+a+d 再执行脚本即可。\e[0m"
		sleep 3
	    if [[ $(screen -ls | grep -c "DST_Master") > 0 && $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
	        screen -r DST_Master
	    fi
	    if [[ $(screen -ls | grep -c "DST_Master") > 0 && $(screen -ls | grep -c "DST_Caves") = 0 ]]; then
	        screen -r DST_Master
	    fi
	    if [[ $(screen -ls | grep -c "DST_Master") = 0 && $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
	        screen -r DST_Caves
	    fi
	else
	    echo "游戏服务器未开启！"
		menu
	fi
}

function exitshell()
{
   clear
   cd $HOME
}

function setmasterworld()
{
    echo -e "\e[92m请选择生物群落：1.经典（没有巨人）  默认（联机）直接按Enter \e[0m"
	task_set="default"
	read smaster
	case $smaster in
	    1)
		task_set="classic";;
	esac
	echo -e "\e[92m请选择初始环境： 默认直接按Enter  1.三箱  2.永夜\e[0m"
	start_location="default"
	read smaster
	case $smaster in
	    1)
		world_size="plus";;
		2)
		world_size="darkness";;
	esac
	echo -e "\e[92m请选择地图大小：1.小型 2.中等  默认（大型）直接按Enter 3.巨型\e[0m"
	world_size="default"
	read scaves
	case $scaves in
	    1)
		world_size="small";;
		2)
		world_size="medium";;
		3)
		world_size="huge";;
	esac
	echo -e "\e[92m请设置岔路地形：1.无 2.最少  默认直接按Enter 3.最多\e[0m"
	branching="default"
	read scaves
	case $scaves in
	    1)
		branching="never";;
		2)
		branching="least";;
		3)
		branching="most";;
	esac
	echo -e "\e[92m请设置环状地形：1.无  默认直接按Enter   2.总是\e[0m"
	loop="default"
	read scaves
	case $scaves in
	    1)
		loop="never";;
		2)
		loop="always";;
	esac
	echo -e "\e[92m请选择要参与的活动：1.无  默认直接按Enter  2.万圣夜  3.冬季盛宴  4.鸡年吉祥\e[0m"
	specialevent="default"
	read scaves
	case $scaves in
	    1)
		specialevent="none";;
		2)
		specialevent="hallowed_nights";;
		3)
		specialevent="winters_feast";;
		4)
		specialevent="year_of_the_gobbler";;
	esac
	
	echo -e "\e[92m请设置秋天长度：1.无 2.很短 3.短 默认直接按Enter 4.长 5.很长 6.随机\e[0m"
	setseason
	autumn="$season"
	
	echo -e "\e[92m请设置冬天长度：1.无 2.很短 3.短 默认直接按Enter 4.长 5.很长 6.随机\e[0m"
	setseason
	winter="$season"

	echo -e "\e[92m请设置春天长度：1.无 2.很短 3.短 默认直接按Enter 4.长 5.很长 6.随机\e[0m"
	setseason
	spring="$season"
	
	echo -e "\e[92m请设置夏天长度：1.无 2.很短 3.短 默认直接按Enter 4.长 5.很长 6.随机\e[0m"
	setseason
	summer="$season"
	
	echo -e "\e[92m请设置开始季节：默认（秋季）直接按Enter  1. 冬季  2.春季  3.夏季  4.秋或春  5.冬或夏  6.随机\e[0m"
	season_start="default"
	read scaves
	case $scaves in
	    1)
		season_start="winter";;
		2)
		season_start="spring";;
		3)
		season_start="summer";;
		4)
		season_start="autumnorspring";;
		5)
		season_start="winterorsummer";;
		6)
		season_start="random";;
	esac
	
	echo -e "\e[92m请设置昼夜长短：\e[0m"
	echo -e "\e[92m      默认直接按Enter   1.长白昼\e[0m"
	echo -e "\e[92m      2.长黄昏          3.长夜晚\e[0m"
	echo -e "\e[92m      4.无白昼          5.无黄昏\e[0m"
	echo -e "\e[92m      6.无夜晚          7.仅有白昼\e[0m"
	echo -e "\e[92m      8.仅有黄昏        9.仅有夜晚\e[0m"
	day="default"
	read scaves
	case $scaves in
	    1)
		day="longday";;
		2)
		day="longdusk";;
		3)
		day="longnight";;
		4)
		day="noday";;
		5)
		day="nodusk";;
		6)
		day="nonight";;
		7)
		day="onlyday";;
		8)
		day="onlydusk";;
		8)
		day="onlynight";;
	esac
	echo -e "\e[92m请设置再生速度：1.极慢 2.慢 默认直接按Enter 3.快 4.极快\e[0m"
	regrowth="default"
	read scaves
	case $scaves in
	    1)
		regrowth="veryslow";;
		2)
		regrowth="slow";;
		3)
		regrowth="fast";;
		4)
		regrowth="veryfast";;
	esac
	echo -e "\e[92m请设置作物患病：1.无 2.随机 3.慢 默认直接按Enter 4.快\e[0m"
	disease_delay="default"
	read scaves
	case $scaves in
	    1)
		disease_delay="none";;
		2)
		disease_delay="random";;
		3)
		disease_delay="long";;
		4)
		disease_delay="short";;
	esac
	echo -e "\e[92m请设置初始资源多样性：1.经典 默认直接按Enter 2.高度随机\e[0m"
	prefabswaps_start="default"
	read scaves
	case $scaves in
	    1)
		prefabswaps_start="classic";;
		2)
		prefabswaps_start="highly random";;
	esac
	echo -e "\e[92m请设置树石化速率：1.无 2.慢 默认直接按Enter 3.快 4.极快\e[0m"
	petrification="default"
	read scaves
	case $scaves in
	    1)
		petrification="none";;
		2)
		petrification="few";;
		3)
		petrification="many";;
		4)
		petrification="max";;
	esac
	
	echo -e "\e[92m请设置前辈：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	boons="$preset"
	
	echo -e "\e[92m请设置复活台：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	touchstone="$preset"
	
	echo -e "\e[92m请设置雨：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	weather="$preset"
	
	echo -e "\e[92m请设置彩蛋：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	alternatehunt="$preset"
	
	echo -e "\e[92m请设置杀人蜂巢穴：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	angrybees="$preset"
	
	echo -e "\e[92m请设置秋季BOSS：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	bearger="$preset"
	
	echo -e "\e[92m请设置牛：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	beefalo="$preset"
	
	echo -e "\e[92m请设置牛发情频率：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	beefaloheat="$preset"
	
	echo -e "\e[92m请设置蜜蜂巢穴：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	bees="$preset"
	
	echo -e "\e[92m请设置鸟：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	birds="$preset"
	
	echo -e "\e[92m请设置草：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	grass="$preset"
	
	echo -e "\e[92m请设置蝴蝶：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	butterfly="$preset"
	
	echo -e "\e[92m请设置秃鹫：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	buzzard="$preset"
	
	echo -e "\e[92m请设置仙人掌：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	cactus="$preset"
	
	echo -e "\e[92m请设置胡萝卜：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	carrot="$preset"
	
	echo -e "\e[92m请设置浣熊猫：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	catcoon="$preset"
	
	echo -e "\e[92m请设置冬季BOSS：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	deerclops="$preset"
	
	echo -e "\e[92m请设置春季BOSS：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	goosemoose="$preset"
	
	echo -e "\e[92m请设置夏季BOSS：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	dragonfly="$preset"
	
	echo -e "\e[92m请设置花：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	flower="$preset"
	
	echo -e "\e[92m请设置青蛙雨：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	frograin="$preset"
	
	echo -e "\e[92m请设置树枝：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	sapling="$preset"
	
	echo -e "\e[92m请设置尖刺灌木：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	marshbush="$preset"
	
	echo -e "\e[92m请设置芦苇：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	reeds="$preset"
	
	echo -e "\e[92m请设置树木：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	trees="$preset"	
	
	echo -e "\e[92m请设置燧石：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	flint="$preset"
	
	echo -e "\e[92m请设置岩石：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	rock="$preset"
	
	echo -e "\e[92m请设置猎犬丘：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	houndmound="$preset"
	
    echo -e "\e[92m请设置猎犬袭击：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	hounds="$preset"
	
	echo -e "\e[92m请设置足迹：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	hunt="$preset"
	
    echo -e "\e[92m请设置小偷 ：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	krampus="$preset"	

    echo -e "\e[92m请设置浆果丛：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	berrybush="$preset" 	
	
	echo -e "\e[92m请设置蘑菇：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	mushroom="$preset"
	
	echo -e "\e[92m请设置闪电：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	lightning="$preset"
	
	echo -e "\e[92m请设置电羊：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	lightninggoat="$preset"
	
	echo -e "\e[92m请设置池塘：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	ponds="$preset"

	echo -e "\e[92m请设置食人花：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	lureplants="$preset"
	
	echo -e "\e[92m请设置兔子：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	rabbits="$preset"
	
	echo -e "\e[92m请设置鱼人：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	merm="$preset"
	
	echo -e "\e[92m请设置陨石频率：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	meteorshowers="$preset"
	
	echo -e "\e[92m请设置陨石区域：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	meteorspawner="$preset"  

    echo -e "\e[92m请设置蜘蛛：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	spiders="$preset"		
	
	echo -e "\e[92m请设置触手：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	tentacles="$preset"	
	
	echo -e "\e[92m请设置齿轮马：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	chess="$preset"

	echo -e "\e[92m请设置树人：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	liefs="$preset"
	
	echo -e "\e[92m请设置鼹鼠：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	moles="$preset"     	
	
	echo -e "\e[92m请设置企鹅：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	penguins="$preset"
	
	echo -e "\e[92m请设置火鸡：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	perd="$preset"
	
	echo -e "\e[92m请设置猪人：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	pigs="$preset"
	
	echo -e "\e[92m请设置冰川：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	rock_ice="$preset"
	
	echo -e "\e[92m请设置风滚草：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	tumbleweed="$preset"
	
	echo -e "\e[92m请设置海象巢穴：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	walrus="$preset"
	
	echo -e "\e[92m请设置野火（自燃）：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	wildfires="$preset"
	
	echo -e "\e[92m请设置高脚鸟：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	tallbirds="$preset"
	clear
	echo "return {
  desc=\"The standard Don't Starve experience.\",
  hideminimap=false,
  id=\"SURVIVAL_TOGETHER\",
  location=\"forest\",
  max_playlist_position=999,
  min_playlist_position=0,
  name=\"Default\",
  numrandom_set_pieces=4,
  ordered_story_setpieces={ \"Sculptures_1\", \"Maxwell5\" },
  override_level_string=false,
  overrides={
    alternatehunt=\"$alternatehunt\",
    angrybees=\"$angrybees\",
    autumn=\"$autumn\",
    bearger=\"$bearger\",
    beefalo=\"$beefalo\",
    beefaloheat=\"$beefaloheat\",
    bees=\"$bees\",
    berrybush=\"$berrybush\",
    birds=\"$birds\",
    boons=\"$boons\",
    branching=\"$branching\",
    butterfly=\"$butterfly\",
    buzzard=\"$buzzard\",
    cactus=\"$cactus\",
    carrot=\"$carrot\",
    catcoon=\"$catcoon\",
    chess=\"$chess\",
    day=\"$day\",
    deciduousmonster=\"default\",
    deerclops=\"$deerclops\",
    disease_delay=\"$disease_delay\",
    dragonfly=\"$dragonfly\",
    flint=\"$flint\",
    flowers=\"$flower\",
    frograin=\"$frograin\",
    goosemoose=\"$goosemoose\",
    grass=\"$grass\",
    houndmound=\"$houndmound\",
    hounds=\"$hounds\",
    hunt=\"$hunt\",
    krampus=\"$krampus\",
    layout_mode=\"LinkNodesByKeys\",
    liefs=\"$liefs\",
    lightning=\"$lightning\",
    lightninggoat=\"$lightninggoat\",
    loop=\"$loop\",
    lureplants=\"$lureplants\",
    marshbush=\"$marshbush\",
    merm=\"$merm\",
    meteorshowers=\"$meteorshowers\",
    meteorspawner=\"$meteorspawner\",
    moles=\"$moles\",
    mushroom=\"$mushroom\",
    penguins=\"$penguins\",
    perd=\"$perd\",
    petrification=\"$petrification\",
    pigs=\"$pigs\",
    ponds=\"$ponds\",
    prefabswaps_start=\"$prefabswaps_start\",
    rabbits=\"$rabbits\",
    reeds=\"$reeds\",
    regrowth=\"$regrowth\",
    roads=\"default\",
    rock=\"$rock\",
    rock_ice=\"$rock_ice\",
    sapling=\"$sapling\",
    season_start=\"$season_start\",
    specialevent=\"$specialevent\",
    spiders=\"$spiders\",
    spring=\"$spring\",
    start_location=\"$start_location\",
    summer=\"$summer\",
    tallbirds=\"$tallbirds\",
    task_set=\"$task_set\",
    tentacles=\"$tentacles\",
    touchstone=\"$touchstone\",
    trees=\"$trees\",
    tumbleweed=\"$tumbleweed\",
    walrus=\"$walrus\",
    weather=\"$weather\",
    wildfires=\"$wildfires\",
    winter=\"$winter\",
    world_size=\"$world_size\",
    wormhole_prefab=\"wormhole\" 
  },
  random_set_pieces={
    \"Sculptures_2\",
    \"Sculptures_3\",
    \"Sculptures_4\",
    \"Sculptures_5\",
    \"Chessy_1\",
    \"Chessy_2\",
    \"Chessy_3\",
    \"Chessy_4\",
    \"Chessy_5\",
    \"Chessy_6\",
    \"Maxwell1\",
    \"Maxwell2\",
    \"Maxwell3\",
    \"Maxwell4\",
    \"Maxwell6\",
    \"Maxwell7\",
    \"Warzone_1\",
    \"Warzone_2\",
    \"Warzone_3\" 
  },
  required_prefabs={ \"multiplayer_portal\" },
  substitutes={  },
  version=3 
}" > "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/leveldataoverride.lua"
}

function setseason()
{
    season="default"
	read scaves
	case $scaves in
	    1)
		season="noseason";;
		2)
		season="veryshortseason";;
		3)
		season="shortseason";;
		4)
		season="longseason";;
		5)
		season="verylongseason";;
		6)
		season="random";;
	esac
}

function setcavesworld()
{
    echo -e "\e[92m请选择地图大小：1.小型 2.中等  默认（大型）直接按Enter 3.巨型\e[0m"
	world_size="default"
	read scaves
	case $scaves in
	    1)
		world_size="small";;
		2)
		world_size="medium";;
		3)
		world_size="huge";;
	esac
	echo -e "\e[92m请设置岔路地形：1.无 2.最少 默认直接按Enter 3.最多\e[0m"
	branching="default"
	read scaves
	case $scaves in
	    1)
		branching="never";;
		2)
		branching="least";;
		3)
		branching="most";;
	esac
	echo -e "\e[92m请设置环状地形：1.无  默认直接按Enter 2.总是\e[0m"
	loop="default"
	read scaves
	case $scaves in
	    1)
		loop="never";;
		2)
		loop="always";;
	esac
	echo -e "\e[92m请设置再生速度：1.极慢 2.慢 默认直接按Enter 3.快 4.极快\e[0m"
	regrowth="default"
	read scaves
	case $scaves in
	    1)
		regrowth="veryslow";;
		2)
		regrowth="slow";;
		3)
		regrowth="fast";;
		4)
		regrowth="veryfast";;
	esac
	echo -e "\e[92m请设置洞穴光照：1.极慢 2.慢 默认直接按Enter 3.快 4.极快\e[0m"
	cavelight="default"
	read scaves
	case $scaves in
	    1)
		cavelight="veryslow";;
		2)
		cavelight="slow";;
		3)
		cavelight="fast";;
		4)
		cavelight="veryfast";;
	esac
	echo -e "\e[92m请设置作物患病：1.无 2.随机 3.慢 默认直接按Enter 4.快\e[0m"
	disease_delay="default"
	read scaves
	case $scaves in
	    1)
		disease_delay="none";;
		2)
		disease_delay="random";;
		3)
		disease_delay="long";;
		4)
		disease_delay="short";;
	esac
	echo -e "\e[92m请设置初始资源多样性：1.经典 默认直接按Enter 2.高度随机\e[0m"
	prefabswaps_start="default"
	read scaves
	case $scaves in
	    1)
		prefabswaps_start="classic";;
		2)
		prefabswaps_start="highly random";;
	esac
	echo -e "\e[92m请设置树石化速率：1.无 2.慢 默认直接按Enter 3.快 4.极快\e[0m"
	petrification="default"
	read scaves
	case $scaves in
	    1)
		petrification="none";;
		2)
		petrification="few";;
		3)
		petrification="many";;
		4)
		petrification="max";;
	esac
	echo -e "\e[92m请设置前辈：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	boons="$preset"
	
	echo -e "\e[92m请设置复活台：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	touchstone="$preset"
	
	echo -e "\e[92m请设置雨：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	weather="$preset"
	
	echo -e "\e[92m请设置地震频率：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	earthquakes="$preset"
	
	echo -e "\e[92m请设置草：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	grass="$preset"
	
	echo -e "\e[92m请设置树枝：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	sapling="$preset"
	
	echo -e "\e[92m请设置尖刺灌木：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	marshbush="$preset"
	
	echo -e "\e[92m请设置芦苇：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	reeds="$preset"
	
	echo -e "\e[92m请设置树木：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	trees="$preset"	
	
	echo -e "\e[92m请设置燧石：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	flint="$preset"
	
	echo -e "\e[92m请设置岩石：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	rock="$preset"
	
	echo -e "\e[92m请设置蘑菇树：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	mushtree="$preset"
	
    echo -e "\e[92m请设置蕨类植物：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	fern="$preset"
	
	echo -e "\e[92m请设置荧光果：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	flower_cave="$preset"
	
    echo -e "\e[92m请设置发光浆果 ：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	wormlights="$preset"	

    echo -e "\e[92m请设置浆果丛：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	berrybush="$preset" 	
	
	echo -e "\e[92m请设置蘑菇：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	mushroom="$preset"
	
	echo -e "\e[92m请设置香蕉：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	banana="$preset"
	
	echo -e "\e[92m请设置苔藓：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	lichen="$preset"
	
	echo -e "\e[92m请设置洞穴池塘：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	cave_ponds="$preset"
	
	echo -e "\e[92m请设置啜食者：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	slurper="$preset"
	
	echo -e "\e[92m请设置兔人：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	bunnymen="$preset"
	
	echo -e "\e[92m请设置蜗牛：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	slurtles="$preset"
	
	echo -e "\e[92m请设置石虾：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	rocky="$preset"
	
	echo -e "\e[92m请设置猴子：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	monkey="$preset"  

    echo -e "\e[92m请设置洞穴蜘蛛：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	cave_spiders="$preset"		
	
	echo -e "\e[92m请设置触手：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	tentacles="$preset"	
	
	echo -e "\e[92m请设置齿轮马：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	chess="$preset"

	echo -e "\e[92m请设置树人：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	liefs="$preset"
	
	echo -e "\e[92m请设置蝙蝠：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	bats="$preset"     	
	
	echo -e "\e[92m请设置裂缝：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	fissure="$preset"
	
	echo -e "\e[92m请设置蠕虫袭击：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	wormattacks="$preset"
	
	echo -e "\e[92m请设置蠕虫：1.无 2.较少 默认直接按Enter 3.较多 4.大量\e[0m"
	setoverride
	worms="$preset"
	
    clear
	echo "return {
  background_node_range={ 0, 1 },
  desc=\"Delve into the caves... together!\",
  hideminimap=false,
  id=\"DST_CAVE\",
  location=\"cave\",
  max_playlist_position=999,
  min_playlist_position=0,
  name=\"The Caves\",
  numrandom_set_pieces=0,
  override_level_string=false,
  overrides={
    banana=\"$banana\",
    bats=\"$bats\",
    berrybush=\"$berrybush\",
    boons=\"$boons\",
    branching=\"$branching\",
    bunnymen=\"$bunnymen\",
    cave_ponds=\"$cave_ponds\",
    cave_spiders=\"$cave_spiders\",
    cavelight=\"$cavelight\",
    chess=\"$chess\",
    disease_delay=\"$disease_delay\",
    earthquakes=\"$earthquakes\",
    fern=\"$fern\",
    fissure=\"$fissure\",
    flint=\"$flint\",
    flower_cave=\"$flower_cave\",
    grass=\"$grass\",
    layout_mode=\"RestrictNodesByKey\",
    lichen=\"$lichen\",
    liefs=\"$liefs\",
    loop=\"$loop\",
    marshbush=\"$marshbush\",
    monkey=\"$monkey\",
    mushroom=\"$mushroom\",
    mushtree=\"$mushtree\",
    petrification=\"$petrification\",
    prefabswaps_start=\"$prefabswaps_start\",
    reeds=\"$reeds\",
    regrowth=\"$regrowth\",
    roads=\"never\",
    rock=\"$rock\",
    rocky=\"$rocky\",
    sapling=\"$sapling\",
    season_start=\"default\",
    slurper=\"$slurper\",
    slurtles=\"$slurtles\",
    start_location=\"caves\",
    task_set=\"cave_default\",
    tentacles=\"$tentacles\",
    touchstone=\"$touchstone\",
    trees=\"$trees\",
    weather=\"$weather\",
    world_size=\"$world_size\",
    wormattacks=\"$wormattacks\",
    wormhole_prefab=\"tentacle_pillar\",
    wormlights=\"$wormlights\",
    worms=\"$worms\" 
  },
  required_prefabs={ \"multiplayer_portal\" },
  substitutes={  },
  version=3 
}" > "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/leveldataoverride.lua"
}

function setoverride()
{
    preset="default"
	read s
	case $s in
	    1)
		preset="never";;
		2)
		preset="rare";;
		3)
		preset="often";;
		4)
		preset="always";;
	esac
}

function setworld()
{
	echo -e "\e[92m请选择要更改的地上世界设置：（当前服务器不开地上直接选默认）\e[0m"
	echo -e "\e[92m         1.经典（没有巨人ROG）\e[0m"
	echo -e "\e[92m         2.三箱（快速开局）\e[0m"
	echo -e "\e[92m         3.永夜\e[0m"
	echo -e "\e[92m         4.自定义（随心所欲）\e[0m"
	echo -e "\e[92m         5.默认\e[0m"
	read masterset
	case $masterset in
	    1)
		echo "return {
  desc=\"Don't Starve Together with Reign of Giants turned off.\",
  hideminimap=false,
  id=\"SURVIVAL_TOGETHER_CLASSIC\",
  location=\"forest\",
  max_playlist_position=999,
  min_playlist_position=0,
  name=\"No Giants Here\",
  numrandom_set_pieces=4,
  ordered_story_setpieces={ \"Sculptures_1\", \"Maxwell5\" },
  override_level_string=false,
  overrides={
    alternatehunt=\"default\",
    angrybees=\"default\",
    autumn=\"default\",
    bearger=\"never\",
    beefalo=\"default\",
    beefaloheat=\"default\",
    bees=\"default\",
    berrybush=\"default\",
    birds=\"default\",
    boons=\"default\",
    branching=\"default\",
    butterfly=\"default\",
    buzzard=\"never\",
    cactus=\"never\",
    carrot=\"default\",
    catcoon=\"never\",
    chess=\"default\",
    day=\"default\",
    deciduousmonster=\"never\",
    deerclops=\"default\",
    disease_delay=\"default\",
    dragonfly=\"never\",
    flint=\"default\",
    flowers=\"default\",
    frograin=\"never\",
    goosemoose=\"never\",
    grass=\"default\",
    houndmound=\"never\",
    hounds=\"default\",
    hunt=\"default\",
    krampus=\"default\",
    layout_mode=\"LinkNodesByKeys\",
    liefs=\"default\",
    lightning=\"default\",
    lightninggoat=\"never\",
    loop=\"default\",
    lureplants=\"default\",
    marshbush=\"default\",
    merm=\"default\",
    meteorshowers=\"default\",
    meteorspawner=\"default\",
    moles=\"never\",
    mushroom=\"default\",
    penguins=\"default\",
    perd=\"default\",
    petrification=\"default\",
    pigs=\"default\",
    ponds=\"default\",
    prefabswaps_start=\"default\",
    rabbits=\"default\",
    reeds=\"default\",
    regrowth=\"default\",
    roads=\"default\",
    rock=\"default\",
    rock_ice=\"never\",
    sapling=\"default\",
    season_start=\"default\",
    specialevent=\"default\",
    spiders=\"default\",
    spring=\"noseason\",
    start_location=\"default\",
    summer=\"noseason\",
    tallbirds=\"default\",
    task_set=\"default\",
    tentacles=\"default\",
    touchstone=\"default\",
    trees=\"default\",
    tumbleweed=\"default\",
    walrus=\"default\",
    weather=\"default\",
    wildfires=\"never\",
    winter=\"default\",
    world_size=\"default\",
    wormhole_prefab=\"wormhole\" 
  },
  random_set_pieces={
    \"Sculptures_2\",
    \"Sculptures_3\",
    \"Sculptures_4\",
    \"Sculptures_5\",
    \"Chessy_1\",
    \"Chessy_2\",
    \"Chessy_3\",
    \"Chessy_4\",
    \"Chessy_5\",
    \"Chessy_6\",
    \"Maxwell1\",
    \"Maxwell2\",
    \"Maxwell3\",
    \"Maxwell4\",
    \"Maxwell6\",
    \"Maxwell7\",
    \"Warzone_1\",
    \"Warzone_2\",
    \"Warzone_3\" 
  },
  required_prefabs={ \"multiplayer_portal\" },
  substitutes={  },
  version=3 
}" > "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/leveldataoverride.lua"	;;
		2)
		echo "return {
  desc=\"A quicker start in a harsher world.\",
  hideminimap=false,
  id=\"SURVIVAL_DEFAULT_PLUS\",
  location=\"forest\",
  max_playlist_position=999,
  min_playlist_position=0,
  name=\"Together Plus\",
  numrandom_set_pieces=4,
  ordered_story_setpieces={ \"Sculptures_1\", \"Maxwell5\" },
  override_level_string=false,
  overrides={
    alternatehunt=\"default\",
    angrybees=\"default\",
    autumn=\"default\",
    bearger=\"default\",
    beefalo=\"default\",
    beefaloheat=\"default\",
    bees=\"default\",
    berrybush=\"rare\",
    birds=\"default\",
    boons=\"often\",
    branching=\"default\",
    butterfly=\"default\",
    buzzard=\"default\",
    cactus=\"default\",
    carrot=\"rare\",
    catcoon=\"default\",
    chess=\"default\",
    day=\"default\",
    deciduousmonster=\"default\",
    deerclops=\"default\",
    disease_delay=\"default\",
    dragonfly=\"default\",
    flint=\"default\",
    flowers=\"default\",
    frograin=\"default\",
    goosemoose=\"default\",
    grass=\"default\",
    houndmound=\"default\",
    hounds=\"default\",
    hunt=\"default\",
    krampus=\"default\",
    layout_mode=\"LinkNodesByKeys\",
    liefs=\"default\",
    lightning=\"default\",
    lightninggoat=\"default\",
    loop=\"default\",
    lureplants=\"default\",
    marshbush=\"default\",
    merm=\"default\",
    meteorshowers=\"default\",
    meteorspawner=\"default\",
    moles=\"default\",
    mushroom=\"default\",
    penguins=\"default\",
    perd=\"default\",
    petrification=\"default\",
    pigs=\"default\",
    ponds=\"default\",
    prefabswaps_start=\"default\",
    rabbits=\"rare\",
    reeds=\"default\",
    regrowth=\"default\",
    roads=\"default\",
    rock=\"default\",
    rock_ice=\"default\",
    sapling=\"default\",
    season_start=\"default\",
    specialevent=\"default\",
    spiders=\"often\",
    spring=\"default\",
    start_location=\"plus\",
    summer=\"default\",
    tallbirds=\"default\",
    task_set=\"default\",
    tentacles=\"default\",
    touchstone=\"default\",
    trees=\"default\",
    tumbleweed=\"default\",
    walrus=\"default\",
    weather=\"default\",
    wildfires=\"default\",
    winter=\"default\",
    world_size=\"default\",
    wormhole_prefab=\"wormhole\" 
  },
  random_set_pieces={
    \"Sculptures_2\",
    \"Sculptures_3\",
    \"Sculptures_4\",
    \"Sculptures_5\",
    \"Chessy_1\",
    \"Chessy_2\",
    \"Chessy_3\",
    \"Chessy_4\",
    \"Chessy_5\",
    \"Chessy_6\",
    \"Maxwell1\",
    \"Maxwell2\",
    \"Maxwell3\",
    \"Maxwell4\",
    \"Maxwell6\",
    \"Maxwell7\",
    \"Warzone_1\",
    \"Warzone_2\",
    \"Warzone_3\" 
  },
  required_prefabs={ \"multiplayer_portal\" },
  substitutes={  },
  version=3 
}" > "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/leveldataoverride.lua";;
        3)
		echo "return {
  desc=\"A dark twist on the standard Don't Starve experience.\",
  hideminimap=false,
  id=\"COMPLETE_DARKNESS\",
  location=\"forest\",
  max_playlist_position=999,
  min_playlist_position=0,
  name=\"Lights Out\",
  numrandom_set_pieces=4,
  ordered_story_setpieces={ \"Sculptures_1\", \"Maxwell5\" },
  override_level_string=false,
  overrides={
    alternatehunt=\"default\",
    angrybees=\"default\",
    autumn=\"default\",
    bearger=\"default\",
    beefalo=\"default\",
    beefaloheat=\"default\",
    bees=\"default\",
    berrybush=\"default\",
    birds=\"default\",
    boons=\"default\",
    branching=\"default\",
    butterfly=\"default\",
    buzzard=\"default\",
    cactus=\"default\",
    carrot=\"default\",
    catcoon=\"default\",
    chess=\"default\",
    day=\"onlynight\",
    deciduousmonster=\"default\",
    deerclops=\"default\",
    disease_delay=\"default\",
    dragonfly=\"default\",
    flint=\"default\",
    flowers=\"default\",
    frograin=\"default\",
    goosemoose=\"default\",
    grass=\"default\",
    houndmound=\"default\",
    hounds=\"default\",
    hunt=\"default\",
    krampus=\"default\",
    layout_mode=\"LinkNodesByKeys\",
    liefs=\"default\",
    lightning=\"default\",
    lightninggoat=\"default\",
    loop=\"default\",
    lureplants=\"default\",
    marshbush=\"default\",
    merm=\"default\",
    meteorshowers=\"default\",
    meteorspawner=\"default\",
    moles=\"default\",
    mushroom=\"default\",
    penguins=\"default\",
    perd=\"default\",
    petrification=\"default\",
    pigs=\"default\",
    ponds=\"default\",
    prefabswaps_start=\"default\",
    rabbits=\"default\",
    reeds=\"default\",
    regrowth=\"default\",
    roads=\"default\",
    rock=\"default\",
    rock_ice=\"default\",
    sapling=\"default\",
    season_start=\"default\",
    specialevent=\"default\",
    spiders=\"default\",
    spring=\"default\",
    start_location=\"default\",
    summer=\"default\",
    tallbirds=\"default\",
    task_set=\"default\",
    tentacles=\"default\",
    touchstone=\"default\",
    trees=\"default\",
    tumbleweed=\"default\",
    walrus=\"default\",
    weather=\"default\",
    wildfires=\"default\",
    winter=\"default\",
    world_size=\"default\",
    wormhole_prefab=\"wormhole\" 
  },
  random_set_pieces={
    \"Sculptures_2\",
    \"Sculptures_3\",
    \"Sculptures_4\",
    \"Sculptures_5\",
    \"Chessy_1\",
    \"Chessy_2\",
    \"Chessy_3\",
    \"Chessy_4\",
    \"Chessy_5\",
    \"Chessy_6\",
    \"Maxwell1\",
    \"Maxwell2\",
    \"Maxwell3\",
    \"Maxwell4\",
    \"Maxwell6\",
    \"Maxwell7\",
    \"Warzone_1\",
    \"Warzone_2\",
    \"Warzone_3\" 
  },
  required_prefabs={ \"multiplayer_portal\" },
  substitutes={  },
  version=3 
}" > "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/leveldataoverride.lua";;
        4)
		setmasterworld;;
		5)
		echo "return {
  desc=\"The standard Don't Starve experience.\",
  hideminimap=false,
  id=\"SURVIVAL_TOGETHER\",
  location=\"forest\",
  max_playlist_position=999,
  min_playlist_position=0,
  name=\"Default\",
  numrandom_set_pieces=4,
  ordered_story_setpieces={ \"Sculptures_1\", \"Maxwell5\" },
  override_level_string=false,
  overrides={
    alternatehunt=\"default\",
    angrybees=\"default\",
    autumn=\"default\",
    bearger=\"default\",
    beefalo=\"default\",
    beefaloheat=\"default\",
    bees=\"default\",
    berrybush=\"default\",
    birds=\"default\",
    boons=\"default\",
    branching=\"default\",
    butterfly=\"default\",
    buzzard=\"default\",
    cactus=\"default\",
    carrot=\"default\",
    catcoon=\"default\",
    chess=\"default\",
    day=\"default\",
    deciduousmonster=\"default\",
    deerclops=\"default\",
    disease_delay=\"default\",
    dragonfly=\"default\",
    flint=\"default\",
    flowers=\"default\",
    frograin=\"default\",
    goosemoose=\"default\",
    grass=\"default\",
    houndmound=\"default\",
    hounds=\"default\",
    hunt=\"default\",
    krampus=\"default\",
    layout_mode=\"LinkNodesByKeys\",
    liefs=\"default\",
    lightning=\"default\",
    lightninggoat=\"default\",
    loop=\"default\",
    lureplants=\"default\",
    marshbush=\"default\",
    merm=\"default\",
    meteorshowers=\"default\",
    meteorspawner=\"default\",
    moles=\"default\",
    mushroom=\"default\",
    penguins=\"default\",
    perd=\"default\",
    petrification=\"default\",
    pigs=\"default\",
    ponds=\"default\",
    prefabswaps_start=\"default\",
    rabbits=\"default\",
    reeds=\"default\",
    regrowth=\"default\",
    roads=\"default\",
    rock=\"default\",
    rock_ice=\"default\",
    sapling=\"default\",
    season_start=\"default\",
    specialevent=\"default\",
    spiders=\"default\",
    spring=\"default\",
    start_location=\"default\",
    summer=\"default\",
    tallbirds=\"default\",
    task_set=\"default\",
    tentacles=\"default\",
    touchstone=\"default\",
    trees=\"default\",
    tumbleweed=\"default\",
    walrus=\"default\",
    weather=\"default\",
    wildfires=\"default\",
    winter=\"default\",
    world_size=\"default\",
    wormhole_prefab=\"wormhole\" 
  },
  random_set_pieces={
    \"Sculptures_2\",
    \"Sculptures_3\",
    \"Sculptures_4\",
    \"Sculptures_5\",
    \"Chessy_1\",
    \"Chessy_2\",
    \"Chessy_3\",
    \"Chessy_4\",
    \"Chessy_5\",
    \"Chessy_6\",
    \"Maxwell1\",
    \"Maxwell2\",
    \"Maxwell3\",
    \"Maxwell4\",
    \"Maxwell6\",
    \"Maxwell7\",
    \"Warzone_1\",
    \"Warzone_2\",
    \"Warzone_3\" 
  },
  required_prefabs={ \"multiplayer_portal\" },
  substitutes={  },
  version=3 
}" > "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/leveldataoverride.lua";;
    esac
    echo -e "\e[92m请选择要更改的洞穴世界设置：（当前服务器不开洞穴直接选默认）\e[0m"
	echo -e "\e[92m         1.洞穴增强（危机四伏）\e[0m"
	echo -e "\e[92m         2.自定义（随心所欲）\e[0m"
	echo -e "\e[92m         3.默认 \e[0m"
	read cavesset
	case $cavesset in
		1)
		echo "return {
  background_node_range={ 0, 1 },
  desc=\"A darker, more arachnid-y cave experience.\",
  hideminimap=false,
  id=\"DST_CAVE_PLUS\",
  location=\"cave\",
  max_playlist_position=999,
  min_playlist_position=0,
  name=\"Caves Plus\",
  numrandom_set_pieces=0,
  override_level_string=false,
  overrides={
    banana=\"default\",
    bats=\"default\",
    berrybush=\"rare\",
    boons=\"often\",
    branching=\"default\",
    bunnymen=\"default\",
	carrot=\"rare\",
    cave_ponds=\"default\",
    cave_spiders=\"often\",
    cavelight=\"default\",
    chess=\"default\",
    disease_delay=\"default\",
    earthquakes=\"default\",
    fern=\"default\",
    fissure=\"default\",
    flint=\"default\",
    flower_cave=\"rare\",
    grass=\"default\",
    layout_mode=\"RestrictNodesByKey\",
    lichen=\"default\",
    liefs=\"default\",
    loop=\"default\",
    marshbush=\"default\",
    monkey=\"default\",
    mushroom=\"default\",
    mushtree=\"default\",
    petrification=\"default\",
    prefabswaps_start=\"default\",
	rabbits=\"rare\",
    reeds=\"default\",
    regrowth=\"default\",
    roads=\"never\",
    rock=\"default\",
    rocky=\"default\",
    sapling=\"default\",
    season_start=\"default\",
    slurper=\"default\",
    slurtles=\"default\",
    start_location=\"caves\",
    task_set=\"cave_default\",
    tentacles=\"default\",
    touchstone=\"default\",
    trees=\"default\",
    weather=\"default\",
    world_size=\"default\",
    wormattacks=\"default\",
    wormhole_prefab=\"tentacle_pillar\",
    wormlights=\"rare\",
    worms=\"default\" 
  },
  required_prefabs={ \"multiplayer_portal\" },
  substitutes={  },
  version=3 
}" > "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/leveldataoverride.lua";;
		2)
		setcavesworld;;
		3)
		echo "return {
  background_node_range={ 0, 1 },
  desc=\"Delve into the caves... together!\",
  hideminimap=false,
  id=\"DST_CAVE\",
  location=\"cave\",
  max_playlist_position=999,
  min_playlist_position=0,
  name=\"The Caves\",
  numrandom_set_pieces=0,
  override_level_string=false,
  overrides={
    banana=\"default\",
    bats=\"default\",
    berrybush=\"default\",
    boons=\"default\",
    branching=\"default\",
    bunnymen=\"default\",
    cave_ponds=\"default\",
    cave_spiders=\"default\",
    cavelight=\"default\",
    chess=\"default\",
    disease_delay=\"default\",
    earthquakes=\"default\",
    fern=\"default\",
    fissure=\"default\",
    flint=\"default\",
    flower_cave=\"default\",
    grass=\"default\",
    layout_mode=\"RestrictNodesByKey\",
    lichen=\"default\",
    liefs=\"default\",
    loop=\"default\",
    marshbush=\"default\",
    monkey=\"default\",
    mushroom=\"default\",
    mushtree=\"default\",
    petrification=\"default\",
    prefabswaps_start=\"default\",
    reeds=\"default\",
    regrowth=\"default\",
    roads=\"never\",
    rock=\"default\",
    rocky=\"default\",
    sapling=\"default\",
    season_start=\"default\",
    slurper=\"default\",
    slurtles=\"default\",
    start_location=\"caves\",
    task_set=\"cave_default\",
    tentacles=\"default\",
    touchstone=\"default\",
    trees=\"default\",
    weather=\"default\",
    world_size=\"default\",
    wormattacks=\"default\",
    wormhole_prefab=\"tentacle_pillar\",
    wormlights=\"default\",
    worms=\"default\" 
  },
  required_prefabs={ \"multiplayer_portal\" },
  substitutes={  },
  version=3 
}" > "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/leveldataoverride.lua" ;;
	esac
	
}

function createlistfile()
{
    echo " " >>${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/adminlist.txt
	echo " " >>${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/whitelist.txt
	echo " " >>${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/blocklist.txt
}

function addlist()
{
    echo -e "\e[92m请输入你要添加的KLEIID：（提示：在输入框右键鼠标可以粘贴。）\e[0m"
	read kleiid
	if [[ $(grep "$kleiid" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/$listfile") > 0 ]] ;then 
		echo -e "\e[92m名单已经存在！\e[0m"
	else
	    echo "$kleiid" >> ${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/$listfile
	    echo -e "\e[92m名单添加完毕！\e[0m"
    fi
}

function dellist()
{
    echo "=========================================================================="
	grep "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/$listfile" -e "KU"
	echo -e "\e[92m请输入你要移除的KLEIID：（提示：在输入框右键鼠标可以粘贴。）\e[0m"
	read kleiid
	if [[ $(grep "$kleiid" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/$listfile") > 0 ]] ;then 
		sed -i "/$kleiid/d" ${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/$listfile
		echo -e "\e[92m名单已移除！\e[0m"
	else
	    echo -e "\e[92m名单不存在！\e[0m"
	fi
}

function listmanager()
{
    echo -e "\e[92m已有存档：\e[0m"
	ls -l ${DST_conf_basedir}/${DST_conf_dirname} | awk '/^d/ {print $NF}'
	echo -e "\e[92m请输入要设置的存档：（提示：在输入框右键鼠标可以粘贴。）\e[0m"
	read clustername
	cluster_name=$clustername
    echo -e "\e[92m你要设置：1.管理员  2.黑名单\e[0m"
    read list
	case $list in
	    1)
		listfile="adminlist.txt"
		echo -e "\e[92m你要：1.添加管理员  2.移除管理员\e[0m"
		read addordel
		case $addordel in
		    1)
			addlist;;
		    2)
            dellist;;
        esac			
		;;
		2)
		listfile="blacklist.txt"
		echo -e "\e[92m你要：1.添加黑名单  2.移除黑名单\e[0m"
		read addordel
		case $addordel in
		    1)
			addlist;;
		    2)
            dellist;;
        esac
		;;
	esac
}

function listusedmod()
{
	
    for i in $(grep "workshop" "${DST_conf_basedir}/${DST_conf_dirname}/$cluster_name/Master/modoverrides.lua" | cut -d '"' -f 2 | cut -d '-' -f 2)
    do
	    name=$(grep "$HOME/Steam/steamapps/common/DST_${DST_game_beta}/mods/workshop-$i/modinfo.lua" -e "name =" | cut -d '"' -f 2 | head -1)	
	    echo -e "\e[92m$i\e[0m-----------\e[33m$name\e[0m" 
    done
}

function listallmod()
{
    for i in $(ls -l "$HOME/Steam/steamapps/common/DST_${DST_game_beta}/mods" |awk '/^d/ {print $NF}' | cut -d '-' -f 2)
    do
        if [[ -f "$HOME/Steam/steamapps/common/DST_${DST_game_beta}/mods/workshop-$i/modinfo.lua" ]]; then
	        name=$(grep "$HOME/Steam/steamapps/common/DST_${DST_game_beta}/mods/workshop-$i/modinfo.lua" -e "name =" | cut -d '"' -f 2 | head -1)	
	        echo -e "\e[92m$i\e[0m----\e[33m$name\e[0m" 
	    fi
    done
}

function addmod()
{
	echo "请从以上列表选择你要启用的MODID，（鼠标选择后右键输入，不存在直接输入9位数modid"
	echo -e "\e[31m只支持启用MOD,没有图形界面实现配置太难了，要具体配置在客机配置好上传配置文件即可\e[0m"
	echo "添加完毕请输入 0 ！(默认添加脚本配套MOD和汉化MOD)"
	while :
	do
    read modid
	if [[ "$modid" = "0" ]]; then
	    echo "添加完毕 ！"
		break
	else
		if [[ $(grep "$modid" "${DST_conf_basedir}/${DST_conf_dirname}/$cluster_name/Master/modoverrides.lua") > 0 ]]
		then 
			echo "地上世界该Mod已添加"
		else
			sed -i "2i [\"workshop-$modid\"]={ configuration_options={  }, enabled=true }," ${DST_conf_basedir}/${DST_conf_dirname}/$cluster_name/Master/modoverrides.lua
		    echo "地上世界Mod添加完成"
		fi
		if [[ $(grep "$modid" "${DST_conf_basedir}/${DST_conf_dirname}/$cluster_name/Caves/modoverrides.lua") > 0 ]]
		then 
			echo "洞穴世界该Mod已添加"
		else
			sed -i "2i [\"workshop-$modid\"]={ configuration_options={  }, enabled=true }," ${DST_conf_basedir}/${DST_conf_dirname}/$cluster_name/Caves/modoverrides.lua
		    echo "洞穴世界Mod添加完成"
		fi
		echo "" >> "${DST_conf_basedir}/${DST_conf_dirname}/mods_setup.lua"
        if [[ $(grep "$modid" -c "${DST_conf_basedir}/${DST_conf_dirname}/mods_setup.lua") > 0 ]] ;then 
		    echo "" >> "${DST_conf_basedir}/${DST_conf_dirname}/mods_setup.lua"
		else	
            echo "ServerModSetup(\"$modid\")" >> "${DST_conf_basedir}/${DST_conf_dirname}/mods_setup.lua"
		fi	
    fi
    done 
}

function delmod()
{   
    echo "请从以上列表选择你要移除的MODID，（鼠标选择后右键输入）"
	echo "移除完毕请输入 0 ！"
    while :
	do
    read modid
	if [[ "$modid" == "0" ]]; then
	    echo "移除完毕！"
		break
	else
		if [[ $(grep "$modid" "${DST_conf_basedir}/${DST_conf_dirname}/$cluster_name/Master/modoverrides.lua") > 0 ]]
		then 
			sed -i "/$modid/d" ${DST_conf_basedir}/${DST_conf_dirname}/$cluster_name/Master/modoverrides.lua
			echo "地上世界Mod移除完成"
		else
			echo "地上世界该Mod未添加"
		fi
		if [[ $(grep "$modid" "${DST_conf_basedir}/${DST_conf_dirname}/$cluster_name/Caves/modoverrides.lua") > 0 ]]
		then 
			sed -i "/$modid/d" ${DST_conf_basedir}/${DST_conf_dirname}/$cluster_name/Caves/modoverrides.lua
			echo "洞穴世界Mod移除完成"
		else
			echo "洞穴世界该Mod未添加"
		fi 
    fi
	done

}

function modadd()
{
    echo "return {
[\"workshop-367546858\"]={ configuration_options={  }, enabled=true },
[\"workshop-572538624\"]={ configuration_options={  }, enabled=true },
[\"workshop-815489374\"]={ configuration_options={  }, enabled=true }
}" > ${DST_conf_basedir}/${DST_conf_dirname}/$cluster_name/Master/modoverrides.lua
	echo "return {
[\"workshop-367546858\"]={ configuration_options={  }, enabled=true },
[\"workshop-572538624\"]={ configuration_options={  }, enabled=true },
[\"workshop-815489374\"]={ configuration_options={  }, enabled=true }
}" > ${DST_conf_basedir}/${DST_conf_dirname}/$cluster_name/Caves/modoverrides.lua	
}

function console()
{
    clear
}

function rebootannounce()
{
    if [[ $(screen -ls | grep -c "DST_Master") > 0 ]]; then   									        
	    screen -S "DST_Master" -p 0 -X stuff "c_announce(\"服务器设置因做了改动需要重启，预计耗时三分钟，给你带来的不便还请谅解！\")$(printf \\r)"	
	fi
	if [[ $(screen -ls | grep -c "DST_Caves") > 0 ]]; then						        
		screen -S "DST_Caves" -p 0 -X stuff "c_announce(\"服务器设置因做了改动需要重启，预计耗时三分钟，给你带来的不便还请谅解！\")$(printf \\r)"
	fi
}

function deldir()
{
    echo -e "\e[92m已有存档：\e[0m"
	ls -l ${DST_conf_basedir}/${DST_conf_dirname} |awk '/^d/ {print $NF}'
	echo -e "\e[92m请输入要删除的存档[请谨慎选择]：（提示：在输入框右键鼠标可以粘贴。）\e[0m"
	read clustername
	rm -rf ${DST_conf_basedir}/${DST_conf_dirname}/$clustername
	echo -e "\e[92m存档删除完毕！\e[0m"
}

function openswap()
{
    sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
    sudo mkswap /swapfile
    sudo swapon /swapfile
	sudo chmod 0646 /etc/fstab
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
	clear
    echo -e "\e[92m虚拟内存已开启！\e[0m"
}

function menu()
{    
    while :
    do
	    echo -e "\e[33m================欢迎使用饥荒联机版独立服务器脚本[Ubuntu-Steam]==================\e[0m"
        echo
		echo -e "\e[33m作者SteamID:Tendy http://steamcommunity.com/id/linweiqing2016/\e[0m"
		echo -e "\e[33mBug反馈：QQ1113787381\e[0m"
		echo -e "\e[33m更新地址：http://pan.baidu.com/s/1eR79l5K\e[0m"
		echo -e "\e[33m本脚本一切权利归作者所有。未经许可禁止使用本脚本进行任何的商业活动！\e[0m"
		echo
		echo -e "\e[31m首次使用请将本地电脑上的MOD上传到\e[0m"
		echo -e "\e[31m云服务器$HOME/Steam/steamapps/common/DST_*/mods目录下\e[0m"
		echo
        echo -e "\e[92m[1]启动服务器           [2]关闭服务器         [3]重启服务器\e[0m"  
        echo -e "\e[92m[4]查看游戏服务器状态   [5]添加或移除MOD      [6]设置管理员和黑名单\e[0m"
		echo -e "\e[92m[7]控制台               [8]查看自动更新进程   [9]退出本脚本\e[0m"
		echo -e "\e[92m[10]删除存档            [11]开启虚拟内存（单服务器开洞穴使用）\e[0m"
        echo
        echo -e "\e[33m================================================================================\e[0m"
        echo -e "\e[92m请输入命令代号：\e[0m"
        read cmd  
		    case $cmd in
			    1)startserver
				break;;
			    2)closeserver
				sudo killall screen
				menu
                break;;
				3)rebootannounce
				sleep 10
				closeserver				
				./rebootserver.sh
				menu
				break;;
			    4)checkserver
			    break;;	
                5)echo -e "\e[92m设置完成后，须重启服务器才会生效。\e[0m"
				echo -e "\e[92m已有存档：\e[0m"
	            ls -l ${DST_conf_basedir}/${DST_conf_dirname} |awk '/^d/ {print $NF}'
	            echo -e "\e[92m请输入要设置的存档：（提示：在输入框右键鼠标可以粘贴。）\e[0m"
	            read clustername
	            cluster_name=$clustername
				echo -e "\e[92m请选择游戏版本：1.正式版  2.新的国度测试版\e[0m"
	            read isbeta
	            case $isbeta in
	                1)
		            DST_game_beta="Public" ;;
		            2)
		            DST_game_beta="ANewReignBeta" ;;
	            esac	
				echo -e "\e[92m你要：1.添加Mod  2.移除Mod\e[0m"
                read modad
	            case $modad in
	                1)
					listallmod
					addmod;;
					2)
					listusedmod
					delmod;;
				esac
				menu
			    break;;
                6)echo -e "\e[92m设置完成后，须重启服务器才会生效。\e[0m"
				listmanager
				menu
			    break;;	
				7)
				echo "作者已弃坑，不会有这功能了"
				menu
			    break;;	
                8)
				screen -r "DST_autoupdate"
			    break;;	
				9)
				exitshell
			    break;;	
                10)
				deldir
				menu
			    break;;	
                11)
				openswap
				menu
			    break;;					
		    esac
    done
}
menu