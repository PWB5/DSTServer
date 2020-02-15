#!/bin/bash
	DST_game_beta="Public"
	cluster_name="3MC"
	DST_conf_dirname="DoNotStarveTogether"  
	DST_temp_path="/root/Dstupdatecheck"
	DST_conf_basedir="/root/.klei"
	# 颜色变量
	C_RED="\E[31m"
	C_GREEN="\E[92m"
	C_YELLOW="\E[33m"
	C_BLUE="\E[36m"
	

	CState=0
	MState=0
	if [[ $(screen -ls | grep -c "DST_Master") == 0 ]]; then
		echo -e "${C_YELLOW}\nDST_Master服务器未开启!\e[0m"
		if [[ $(screen -ls | grep -c "DST_Caves") == 0 ]]; then
			echo -e "${C_RED}\nDST_Caves服务器未开启!"
			echo -e "请执行关闭服务器命令后再次尝试，并注意令牌是否成功设置且有效。\e[0m"
		else
			## Master未开启，判断Caves是否开启成功
			for ((a=1; a<=60; a++))
			do
				if [[ $CState == 4 && $(grep "Registering slave in China lobby" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_log.txt") > 0 ]]; then
					echo -e "${C_GREEN}\nDST_Caves_China服务器开启成功，和小伙伴尽情玩耍吧！\e[0m"
					CState=5
					break
				elif [[ $CState == 4 && $(grep "Registering slave in Sing lobby" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_log.txt") > 0 ]]; then
					echo -e "${C_GREEN}\nDST_Caves_Sing服务器开启成功，和小伙伴尽情玩耍吧！\e[0m"
					CState=6
					break
				elif [[ $CState == 3 && $(grep "SteamGameServer_Init success" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_log.txt") > 0 ]]; then
					echo -e "${C_YELLOW}\nSteamGameServer初始化成功！\c\e[0m"
					CState=4
				elif [[ $CState == 2 && $(grep "ModIndex: Load sequence finished successfully" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_log.txt") > 1 ]]; then
					echo -e "${C_YELLOW}\nMods加载成功！\c\e[0m"
					CState=3
				elif [[ $CState == 1 && $(grep "LOADING LUA SUCCESS" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_log.txt") > 1 ]]; then
					echo -e "${C_YELLOW}\n加载LUA成功！\c\e[0m"
					CState=2
				elif [[ $CState == 0 && $(grep "Account Communication Success" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_log.txt") > 0 ]]; then
					echo -e "${C_YELLOW}\n帐户通信成功！\c\e[0m"
					CState=1
				elif [[ $(screen -ls | grep -c "DST_Caves") == 0 ]]; then
					echo -e "${C_RED}\nDST_Caves服务器未开启!"
					echo -e "请执行关闭服务器命令后再次尝试，并注意令牌是否成功设置且有效。\e[0m"
					break
				elif [[ $a == 60 ]]; then
					echo -e "${C_RED}\nDST_Caves服务器启动检测超时!"
					echo -e "${C_BLUE}你要：1.继续自动检测 2.查看游戏服务器状态 3.检测结束\e[0m"
					read AUTOorState
					case $AUTOorState in
					    1)
					    a=1 ;;
					    2)
						if [[ $(screen -ls | grep -c "DST_Master") > 0 || $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
						    echo -e "${C_BLUE}即将跳转游戏服务器窗口，要退回本界面，在游戏服务器窗口按${C_YELLOW}“ctrl+a”+“d”${C_BLUE}再执行脚本即可。\e[0m"
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
						    echo -e "${C_YELLOW}游戏服务器未开启！\e[0m"
							menu
						fi ;;
						*)
						break ;;
					esac
				else
					echo -e "${C_YELLOW}.\c\e[0m"
					sleep 3
				fi
			done
		fi
	elif [[ $(screen -ls | grep -c "DST_Master") > 0 ]]; then
		## 判断Master是否开启成功
		for ((b=1; b<=60; b++))
		do
			if [[ $MState == 4 && $(grep "Registering master server in China lobby" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_log.txt") > 0 ]]; then
				echo -e "${C_GREEN}\nDST_Master_China服务器开启成功，和小伙伴尽情玩耍吧！\e[0m"
				MState=5
				break
			elif [[ $MState == 4 && $(grep "Registering master server in Sing lobby" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_log.txt") > 0 ]]; then
				echo -e "${C_GREEN}\nDST_Master_Sing服务器开启成功，和小伙伴尽情玩耍吧！\e[0m"
				MState=6
				break
			elif [[ $MState == 4 && $(grep "Registering slave in China lobby" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_log.txt") > 0 ]]; then
				echo -e "${C_GREEN}\nDST_Master_China多重世界服务器开启成功，和小伙伴尽情玩耍吧！\e[0m"
				MState=7
				break
			elif [[ $MState == 4 && $(grep "Registering slave in Sing lobby" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_log.txt") > 0 ]]; then
				echo -e "${C_GREEN}\nDST_Master_Sing多重世界服务器开启成功，和小伙伴尽情玩耍吧！\e[0m"
				MState=8
				break
			elif [[ $MState == 3 && $(grep "SteamGameServer_Init success" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_log.txt") > 0 ]]; then
				echo -e "${C_YELLOW}\nSteamGameServer初始化成功！\c\e[0m"
				MState=4
			elif [[ $MState == 2 && $(grep "ModIndex: Load sequence finished successfully" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_log.txt") > 1 ]]; then
				echo -e "${C_YELLOW}\nMods加载成功！\c\e[0m"
				MState=3
			elif [[ $MState == 1 && $(grep "LOADING LUA SUCCESS" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_log.txt") > 1 ]]; then
				echo -e "${C_YELLOW}\n加载LUA成功！\c\e[0m"
				MState=2
			elif [[ $MState == 0 && $(grep "Account Communication Success" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Master/server_log.txt") > 0 ]]; then
				echo -e "${C_YELLOW}\n帐户通信成功！\c\e[0m"
				MState=1
			elif [[ $(screen -ls | grep -c "DST_Master") == 0 ]]; then
				echo -e "${C_RED}\nDST_Master服务器未开启!\e[0m"
				break
			elif [[ $b == 60 ]]; then
				echo -e "${C_RED}\nDST_Master服务器启动检测超时!"
				echo -e "${C_BLUE}你要：1.继续自动检测 2.查看游戏服务器状态 3.检测结束\e[0m"
				read AUTOorState
				case $AUTOorState in
				    1)
				    b=1 ;;
				    2)
					if [[ $(screen -ls | grep -c "DST_Master") > 0 || $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
					    echo -e "${C_BLUE}即将跳转游戏服务器窗口，要退回本界面，在游戏服务器窗口按${C_YELLOW}“ctrl+a”+“d”${C_BLUE}再执行脚本即可。\e[0m"
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
					    echo -e "${C_YELLOW}游戏服务器未开启！\e[0m"
						menu
					fi ;;
					*)
					break ;;
				esac
			else
				echo -e "${C_YELLOW}.\c\e[0m"
				sleep 3
			fi
		done
		## 判断完Master后，判断Caves是否开启成功
		if [[ $(screen -ls | grep -c "DST_Caves") == 0 ]]; then
			echo -e "${C_YELLOW}\nDST_Caves服务器未开启!\e[0m"
		else
			## 判断DST_Caves服务器是否开启
			for ((c=1; c<=60; c++))
			do
				if [[ $CState == 4 && $(grep "Registering slave in China lobby" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_log.txt") > 0 ]]; then
					echo -e "${C_GREEN}\nDST_Caves服务器开启成功，和小伙伴尽情玩耍吧！\e[0m"
					CState=5
					break
				elif [[ $CState == 4 && $(grep "Registering slave in Sing lobby" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_log.txt") > 0 ]]; then
					echo -e "${C_GREEN}\nDST_Caves_Sing服务器开启成功，和小伙伴尽情玩耍吧！\e[0m"
					CState=6
					break
				elif [[ $CState == 3 && $(grep "SteamGameServer_Init success" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_log.txt") > 0 ]]; then
					echo -e "${C_YELLOW}\nSteamGameServer初始化成功！\c\e[0m"
					CState=4
				elif [[ $CState == 2 && $(grep "ModIndex: Load sequence finished successfully" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_log.txt") > 1 ]]; then
					echo -e "${C_YELLOW}\nMods加载成功！\c\e[0m"
					CState=3
				elif [[ $CState == 1 && $(grep "LOADING LUA SUCCESS" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_log.txt") > 1 ]]; then
					echo -e "${C_YELLOW}\n加载LUA成功！\c\e[0m"
					CState=2
				elif [[ $CState == 0 && $(grep "Account Communication Success" -c "${DST_conf_basedir}/${DST_conf_dirname}/${cluster_name}/Caves/server_log.txt") > 0 ]]; then
					echo -e "${C_YELLOW}\n帐户通信成功！\c\e[0m"
					CState=1
				elif [[ $(screen -ls | grep -c "DST_Caves") == 0 ]]; then
					echo -e "${C_RED}\nDST_Caves服务器可能开启失败!"
					echo -e "请执行关闭服务器命令后再次尝试，并注意令牌是否成功设置且有效。\e[0m"
					break
				elif [[ $c == 60 ]]; then
					echo -e "${C_RED}\nDST_Caves服务器启动检测超时!"
					echo -e "${C_BLUE}你要：1.继续自动检测 2.查看游戏服务器状态 3.检测结束\e[0m"
					read AUTOorState
					case $AUTOorState in
					    1)
					    c=1 ;;
					    2)
						if [[ $(screen -ls | grep -c "DST_Master") > 0 || $(screen -ls | grep -c "DST_Caves") > 0 ]]; then
						    echo -e "${C_BLUE}即将跳转游戏服务器窗口，要退回本界面，在游戏服务器窗口按${C_YELLOW}“ctrl+a”+“d”${C_BLUE}再执行脚本即可。\e[0m"
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
						    echo -e "${C_YELLOW}游戏服务器未开启！\e[0m"
							menu
						fi ;;
						*)
						break ;;
					esac
				else
					echo -e "${C_YELLOW}.\c\e[0m"
					sleep 3
				fi
			done
		fi
	fi
	
