#!/bin/bash

# xmpl-tool v1.0.5
# Author: Ivan Krpan
# Date: 03.02.2018

##################################################################
# EXIT FUNCTIONS
function byebye {

	IFS=$oIFS
	unset -f installSourced
	unset -f editConfig
	unset -f installPrivateRepo
	unset -f uninstallSourced
	
	unset i repo package status git_repo XMPL_OUTPUT OPTARG OPTIND flag inputs old_inputs query flags XMPL_REPO oIFS XMPL_PACKAGE XMPL_QUERY XMPL_LAST_REPO_UPDATE XMPL_DEFAULT_REPO
	unset XMPL_PRE_RESULT XMPL_USER XMPL_HOME XMPL_MODE_QUERY XMPL_MODE_EDIT XMPL_MODE_RAW XMPL_MODE_INPUT XMPL_MODE_EXECUTE XMPL_MODE_ONLINE XMPL_MODE_HISTORY XMPL_MODE_NULL fkey version
	
	trap - INT
	echo -e "\e[39m\c" >&2
}

function escapeBreak {

	fkey="\e"
	break
}

function ctrl_c {

	exit 1
}
##################################################################
# INSTALL FUNCTIONS

function installSourced {

	#Install xmpl config
	mkdir -p ~/.xmpl
	touch ~/.xmpl/xmpl.conf
	editConfig 'XMPL_DEFAULT_REPO' 'main' ~/.xmpl/xmpl.conf
	#Install Aaliass 
	if ! grep -Fxq "alias xmpl='. xmpl'" ~/.bashrc
		then
			echo "alias xmpl='. xmpl'" >> ~/.bashrc
	fi
	
	if [ ! -f ~/.bash_profile ];then
		touch ~/.bash_profile
		echo '[ -f ~/.bashrc ] && . ~/.bashrc #XMPL' >> ~/.bash_profile
	else
		if ! grep -Fxq "[ -f ~/.bashrc ] && . ~/.bashrc #XMPL" ~/.bash_profile
		then
			echo "[ -f ~/.bashrc ] && . ~/.bashrc #XMPL" >> ~/.bash_profile
		fi
	fi
	
}

function uninstallSourced {

	if grep -Fxq "alias xmpl='. xmpl'" ~/.bashrc;then
		sed -i "/alias xmpl='. xmpl'/d" ~/.bashrc
	fi
	source ~/.bashrc	
	if grep -Fxq "[ -f ~/.bashrc ] && . ~/.bashrc #XMPL" ~/.bash_profile;then
		sed -i "/[ -f ~\/.bashrc ] && . ~\/.bashrc #XMPL/d" ~/.bash_profile
	fi
	if [ ! -s ~/.bash_profile ] ; then
	  rm ~/.bash_profile
	fi
}

function installPrivateRepo {

	rm -rf ~/.xmpl/repos/xmpl-tool/xmpl-repo
	mkdir -p ~/.xmpl/repos/xmpl-tool/xmpl-repo
	git clone https://github.com/xmpl-tool/xmpl-repo ~/.xmpl/repos/xmpl-tool/xmpl-repo
	touch ~/.xmpl/repo.conf
	editConfig 'main' 'xmpl-tool/xmpl-repo' ~/.xmpl/repo.conf
}

function checkRequirements {

	if ! [ -f /usr/bin/curl ]; then
		echo "curl is not installed!"
		return 1
	fi
	if ! [ -f /usr/bin/jq ]; then
		echo "jq is not installed!"
		return 1
	fi	
}

function installLocal {

	local osInfo packageManager f SCRIPTPATH response  

	#Check permissions
	if [[ $EUID -ne 0 ]]; then
	   echo -e "\e[33mFor xmpl-tool installation, run this command as root!\e[39m" >&2
	   return
	fi
	
	echo -e "Do you really want to install xmpl-tool $version on your local system? [Y/n]" >&2
	read response

	response=${response,,} # tolower
	if [[ $response =~ ^(yes|y| ) ]] || [[ -z $response ]]; then
		
		if ! checkRequirements > /dev/null;then
			#OS check
			declare -A osInfo;
			osInfo[/etc/redhat-release]=yum
			osInfo[/etc/arch-release]=pacman
			osInfo[/etc/gentoo-release]=emerge
			osInfo[/etc/SuSE-release]=zypp
			osInfo[/etc/debian_version]=apt-get

			for f in ${!osInfo[@]}
			do
				if [[ -f $f ]];then
					packageManager=${osInfo[$f]}
				fi
			done
			#installing requirement packages
			case $packageManager in
					"apt-get" ) 
					apt-get update && apt-get install curl jq git
					;;
					"zypp" ) 
					zypper ref && zypper in curl jq git
					;;
					"emerge" ) 
					emerge --sync && emerge -pv net-misc/curl app-misc/jq dev-vcs/git
					;;
					"pacman" ) 
					pacman -Sy curl jq git
					;;
					"yum" ) 
					yum install curl jq git
					;;
					* ) 
					echo -e "\e[33mOS not supported!\e[39m" >&2
					return
					;;
			esac
		fi
		
		#Install Script
		SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
		cp $SCRIPTPATH /usr/local/bin/xmpl
		chmod +x /usr/local/bin/xmpl

		export -f installSourced
		export -f editConfig
		
		su $XMPL_USER -c "installSourced"
		
		echo -e "\e[33mxmpl-tool $version installed successfully!\e[39m" >&2
		
		
		#Install Repo
		echo -e "Do you want to download repository and use it locally? [Y/n]" >&2
		read response

		response=${response,,} # tolower
		if [[ $response =~ ^(yes|y| ) ]] || [[ -z $response ]]; then
			export -f installPrivateRepo
			su $XMPL_USER -c "installPrivateRepo"

		fi
		
		echo -e "Do you want to create a private repository on GitHub, and share your examples with community? [Y/n]" >&2
		read  response

		response=${response,,} # tolower
		if [[ $response =~ ^(yes|y| ) ]] || [[ -z $response ]]; then

			addNewRepository '' '' 'xmpl-tool/xmpl-repo'
		fi
		 
		echo "	" >&2
		echo -e "\e[33mInstallation completed!\e[39m" >&2
		
	fi
}

function updateLocal {
	local newVersion
	#Check permissions
	if [[ $EUID -ne 0 ]]; then
	   echo -e "\e[33mTo update xmpl-tool, run this command as root!\e[39m" >&2
	   return
	fi

	echo -e "This will update xmpl-tool to latest version! Are you sure? [Y/n]" >&2
	read response	
	
	response=${response,,} # tolower
	if [[ $response =~ ^(yes|y| ) ]] || [[ -z $response ]]; then
		$(curl -o /usr/local/bin/xmpl https://raw.githubusercontent.com/xmpl-tool/xmpl-script/master/xmpl.sh)
		newVersion=`xmpl -v`
		echo -e "\e[33mxmpl-tool is updated to latest version (${newVersion##* }\e[33m)!\e[39m" >&2
	fi

}

function deinstallLocal {

	local response response2
	#Check permissions
	if [[ $EUID -ne 0 ]]; then
	   echo -e "\e[33mFor uninstalling xmpl-tool, run this command as root!\e[39m" >&2
	   return
	fi

	echo -e "This will remove xmpl-tool from your system. Are you sure? [Y/n]" >&2
	read response

	response=${response,,} # tolower
	if [[ $response =~ ^(yes|y| ) ]] || [[ -z $response ]]; then
		#Remove Aaliass 
		export -f uninstallSourced
		su $XMPL_USER -c "uninstallSourced"
		#Remove script
		rm -f /usr/local/bin/xmpl
		echo -e "Do you want to remove all your local repositories? [Y/n]" >&2
		read response2

		 response2=${response2,,} # tolower
		 if [[ $response2 =~ ^(yes|y| ) ]] || [[ -z $response2 ]]; then
			#Remove local data
			rm -rf ${XMPL_HOME}/.xmpl/
		 fi
		 
		echo -e "\e[33mUninstall completed!\e[39m" >&2
		if [ ! -z ${XMPL_HOME}/.xmpl/repo.conf ];then
			changeRepository "main"
		fi
	fi
}

##################################################################
# REPOSITORY FUNCTIONS
function getRepository {

	local repoAlias

	repoAlias=$1

	if [ -z ${repoAlias} ];then
		XMPL_CURRENT_REPO=$XMPL_DEFAULT_REPO
	else
		if [ -f ${XMPL_HOME}/.xmpl/repo.conf ] ;then
			if $(grep -oPq "$repoAlias *= *\K.*" ${XMPL_HOME}/.xmpl/repo.conf) ;then
				XMPL_CURRENT_REPO=$repoAlias
			else
				echo -e "\e[33mNo such repository alias!\e[39m" >&2
				return 1;
			fi
		else
			XMPL_CURRENT_REPO="main"
		fi
	fi
}

function changeRepository {

	local repoAlias 
	
	repoAlias=$1
	if [ -z $repoAlias ];then
		if [ -f ${XMPL_HOME}/.xmpl/repo.conf ];then
			echo -e "\e[33mCurrent repository: $XMPL_CURRENT_REPO ($XMPL_REPO)\e[32m" >&2
			cat ${XMPL_HOME}/.xmpl/repo.conf >&2
			echo -e "\e[39m\c" >&2
			return
		else
			XMPL_REPO="xmpl-tool/xmpl-repo"
			echo -e "\e[33mCurrent repository: $XMPL_CURRENT_REPO ($XMPL_REPO)\e[39m" >&2
		fi
	else
		if [ -f ${XMPL_HOME}/.xmpl/repo.conf ] ;then
			if grep -oPq "$repoAlias *= *\K.*" ${XMPL_HOME}/.xmpl/repo.conf;then
				editConfig 'XMPL_DEFAULT_REPO' $repoAlias ${XMPL_HOME}/.xmpl/xmpl.conf
				source ${XMPL_HOME}/.xmpl/xmpl.conf
				XMPL_REPO=$(grep -oP "$XMPL_DEFAULT_REPO *= *\K.*" ${XMPL_HOME}/.xmpl/repo.conf)
				echo -e "\e[33mUsing repository: $XMPL_DEFAULT_REPO ($XMPL_REPO)\e[39m" >&2
			else
				echo -e "\e[33mNo such repository alias!\e[39m" >&2
				return
			fi
		else
			XMPL_REPO="xmpl-tool/xmpl-repo"
		fi
	fi
}

function addNewRepository {

	local user repoAlias toFork repoName response validRepo
	
	user=$1
	repoAlias=$2
	toFork=$3
	repoName=$(basename $toFork)
	
	validRepo=$(curl --silent https://api.github.com/search/code?q=extension:repo+repo:$toFork --stderr - | jq '.total_count')
	if [[ "$validRepo" -ge "1" ]];then
		echo -e "\e[33mNew repository from GitHub source '$toFork'\e[39m" >&2
		while [ -z $user ];do
			echo -e "Enter GitHub username:" >&2
			read -e user	
		done

		while [ -z $repoAlias ];do
			echo -e "Enter local repository alias:" >&2
			read -e repoAlias	
		done
		
		if [ -f ${XMPL_HOME}/.xmpl/repos/$user/$repoName/commands.repo ];then
			echo -e "Repository already exist! Overwrite local repository? [y/N]" >&2
			read response
	
		else
			response="y"
		fi
			response=${response,,} # tolower
			if [[ $response =~ ^(yes|y) ]]; then
				if forkRepository $user $toFork;then
					if [[ "$XMPL_USER" != "$(whoami)" ]];then
						su $XMPL_USER -c "rm -rf ${XMPL_HOME}/.xmpl/repos/$user"
						su $XMPL_USER -c "mkdir -p ${XMPL_HOME}/.xmpl/repos/$user"
						su $XMPL_USER -c "git clone https://github.com/$user/$repoName ${XMPL_HOME}/.xmpl/repos/$user/$repoName"
						if [ $toFork == 'xmpl-tool/xmpl-repo' ];then
							su $XMPL_USER -c "cd ${XMPL_HOME}/.xmpl/repos/$user/$repoName >&2; git remote add upstream https://github.com/xmpl-tool/xmpl-repo.git >&2;"
						fi
						
						su $XMPL_USER -c "touch ${XMPL_HOME}/.xmpl/repo.conf"
						su $XMPL_USER -c "editConfig $repoAlias '$user/$repoName' ${XMPL_HOME}/.xmpl/repo.conf"
					else
						rm -rf ${XMPL_HOME}/.xmpl/repos/$user
						mkdir -p ${XMPL_HOME}/.xmpl/repos/$user
						git clone https://github.com/$user/$repoName ${XMPL_HOME}/.xmpl/repos/$user/$repoName
						if [ $toFork == 'xmpl-tool/xmpl-repo' ];then
							$(cd ${XMPL_HOME}/.xmpl/repos/$user/$repoName >&2; git remote add upstream https://github.com/xmpl-tool/xmpl-repo.git >&2;)
						fi
						
						touch ${XMPL_HOME}/.xmpl/repo.conf
						editConfig $repoAlias "$user/$repoName" ${XMPL_HOME}/.xmpl/repo.conf		
					fi
				fi
			fi
	else
		echo -e "\e[33mNot valid xmpl repository!\e[39m" >&2
	fi
}

function forkRepository {

	local user toFork repoName repoStatus1
	
	user=$1
	toFork=$2
	repoName=$(basename $toFork)

	while : ;do
		while [ -z $user ];do
			echo -e "Enter GitHub username:"
			read -e user	
		done
	
		repoStatus1=$(curl --silent  https://api.github.com/repos/$user/$repoName --stderr - | jq '.id')
		
		sleep 3
		if [ $repoStatus1 == "null" ]; then
				if curl --silent -u ${user} https://api.github.com/repos/$toFork/forks -d '' -f 1>/dev/null;then
					echo -e "\e[33mCreating fork of main repository...\e[39m" >&2
 					for i in 1 2 3; do
					#while [ $repoStatus1 == "null" ];do
							sleep 3
							repoStatus1=$(curl --silent  https://api.github.com/repos/$user/$repoName --stderr - | jq '.id')
							if [ $repoStatus1 != "null" ];then
								break
							fi
							if [ $i -eq 3 ];then
								echo -e "\e[31mFailed!\n\e[33mPlease try again\e[39m" >&2
								return 1
							fi
						
					done
					echo -e "\e[33mDone!\e[39m" >&2
					break
				else
					user=""
					echo -e "\e[33mWrong username or password!\e[39m" >&2
				fi
		else
			break
		fi
	done
}

function delLocalRepository {

	local toDel response

	toDel=$1
	
	if [ ! -z $toDel ];then
		
		if grep -oPq "$toDel *= *\K.*" ${XMPL_HOME}/.xmpl/repo.conf;then
			XMPL_CURRENT_REPO=$toDel
		else
			echo -e "\e[33mNo such repository alias!\e[39m" >&2
			return 1
		fi

		XMPL_REPO=$(grep -oP "$XMPL_CURRENT_REPO *= *\K.*" ${XMPL_HOME}/.xmpl/repo.conf)
		echo -e "Delete local repository '$XMPL_CURRENT_REPO' ($XMPL_REPO)?  [y/N]" >&2
		read response

		response=${response,,} # tolower
		if [[ $response =~ ^(yes|y) ]]; then
			if [ $XMPL_CURRENT_REPO != 'main' ];then
				sed -i "/$XMPL_CURRENT_REPO=${XMPL_REPO/\//\\\/}/d" ${XMPL_HOME}/.xmpl/repo.conf
			fi
			#repoUser=$(dirname $XMPL_REPO)
			echo "Deleting $XMPL_REPO" >&2
			if rm -rf ${XMPL_HOME}/.xmpl/repos/$XMPL_REPO ;then
				echo -e "\e[33mRepository '$XMPL_CURRENT_REPO' successfully deleted from local system!\e[39m" >&2
				changeRepository "main"
			fi
			
		fi
	else
		echo -e "\e[33mRepository alias required!\e[39m" >&2
	fi
}

function syncRepository {

	local changes tpwd status XMPL_USERNAME response fcnt cpackages commitMsg

	tpwd=$PWD
	if ! getRepository $1;then
		return
	fi

	XMPL_REPO=$(grep -oP "$XMPL_CURRENT_REPO *= *\K.*" ${XMPL_HOME}/.xmpl/repo.conf)
	XMPL_USERNAME=$(dirname $XMPL_REPO)
	cd ${XMPL_HOME}/.xmpl/repos/$XMPL_REPO
	git add . >&2
	git remote update >&2
	
	if git diff @{upstream} --quiet --;then
		status=$(curl --silent https://api.github.com/repos/xmpl-tool/xmpl-repo/compare/xmpl-tool:master...$XMPL_USERNAME:master --stderr - | jq -r '.status')
		
		if [ "$status" != "behind" ];then
			
			if [ $XMPL_USERNAME == 'xmpl-tool' ];then
				echo -e "Do you want to synchronize '$XMPL_CURRENT_REPO' repository? [Y/n]" >&2
				read response

				response=${response,,} # tolower
				if [[ $response =~ ^(yes|y| ) || -z $response ]]; then
					git pull >&2
				fi
			else
				echo -e '\e[33mRepository up to date!\e[39m' >&2
			fi
			if [ $XMPL_USERNAME == 'xmpl-tool' ];then
				editConfig 'XMPL_LAST_REPO_UPDATE' $(date +%F) ~/.xmpl/xmpl.conf
				XMPL_LAST_REPO_UPDATE=$(date +%F)
			fi
			cd $tpwd
			return
		else
			echo -e "Do you want to synchronize '$XMPL_CURRENT_REPO' repository? [Y/n]" >&2
			read response

			response=${response,,} # tolower
			if [[ $response =~ ^(yes|y| ) || -z $response ]]; then
				git pull >&2
				if grep upstream <(git remote -v ) -q; then   
					#if [ $XMPL_USERNAME != 'xmpl-tool' ];then
						git fetch upstream >&2
						git merge upstream/master >&2
					#fi
				fi
			fi
			
			if [ $XMPL_USERNAME == 'xmpl-tool' ];then
				editConfig 'XMPL_LAST_REPO_UPDATE' $(date +%F) ~/.xmpl/xmpl.conf
				XMPL_LAST_REPO_UPDATE=$(date +%F)
			fi
			cd $tpwd
			return
		fi	
	fi


	changes+="$(git diff @{upstream} --name-only)"
	fcnt=$(echo "$changes" | wc -l) 
	echo "$fcnt file/s changed!" >&2
	echo "$changes" >&2
	echo -e "Do you want to synchronize '$XMPL_CURRENT_REPO' repository? [Y/n]" >&2
	read response

	response=${response,,} # tolower
	if [[ $response =~ ^(yes|y| ) || -z $response ]]; then
		if [ $XMPL_USERNAME != 'xmpl-tool' ];then
			git pull >&2
			if grep upstream <(git remote -v ) -q; then   
				git fetch upstream >&2
				git merge upstream/master >&2
			fi
			cpackages=$(echo -e "$changes" | awk -F "/" '{print $2}' | uniq | tr "\n" " ")
			commitMsg="$(echo -e "$fcnt file/s changed (${cpackages%% })\n$changes")"
			git commit -m "${commitMsg}" >&2
			while : ;do
				git push origin master >&2 && break
					echo -e "Try again? [Y/n]" >&2
					read response
					response=${response,,} # tolower
					if [[ $response =~ ^(no|n) ]]; then
						break
					fi
			done
		fi
	fi
	if [ $XMPL_USERNAME == 'xmpl-tool' ];then
		editConfig 'XMPL_LAST_REPO_UPDATE' $(date +%F) ~/.xmpl/xmpl.conf
		XMPL_LAST_REPO_UPDATE=$(date +%F)
	fi
	cd $tpwd
	
}

function pullRepository {

	local prTitle prBody XMPL_USERNAME response
	
	if ! getRepository $1;then
		return 1
	fi

	XMPL_REPO=$(grep -oP "$XMPL_CURRENT_REPO *= *\K.*" ${XMPL_HOME}/.xmpl/repo.conf)
	XMPL_USERNAME=$(dirname $XMPL_REPO)

	#TODO: Check if pull request exists
	if grep upstream <(cd ~/.xmpl/repos/${XMPL_REPO}/ && git remote -v ) -q;then
		#TODO: Get upstream repo from git remote and use it in GitHub api
		status=$(curl --silent https://api.github.com/repos/xmpl-tool/xmpl-repo/compare/xmpl-tool:master...$XMPL_USERNAME:master --stderr - | jq -r '.status')
		
		if [ "$status" != "identical" ];then
		
			while [ -z $prTitle ];do
				echo -e "Enter pull request title:" >&2
				read -e prTitle
			done;
			
			while [ -z $prBody ] ;do
				echo -e "Enter pull request body:" >&2
				read -e prBody
			done;
			
			while : ;do
				if curl --silent -u ${XMPL_USERNAME} https://api.github.com/repos/xmpl-tool/xmpl-repo/pulls -d "{ \"title\": \"$prTitle\", \"body\": \"$prBody\", \"head\": \"$XMPL_USERNAME:master\", \"base\": \"master\" }" -f 1>/dev/null;then
					echo -e "\e[33mPull request successfull!\e[39m" >&2
					break
				else
					echo -e "Wrong password for user '$XMPL_USERNAME'!\nTry again? [Y/n]" >&2
					read response

					response=${response,,} # tolower
					if [[ $response =~ ^(no|n) ]]; then
						break
					fi
				fi
			done
		else
			echo -e "\e[33mRepositories are identical!\e[39m" >&2
		fi
	else
		echo -e "\e[33mNot possible to pull on main repository directly!\e[39m" >&2
	fi	

}

##################################################################
# QUERY FUNCTIONS
function queryExamples {

	local package query XMPL_USERNAME

	if ! getRepository $1;then
		return 1
	fi
	package=$2
	query=$3
	
	if [ -f ${XMPL_HOME}/.xmpl/repo.conf ];then
		XMPL_REPO=$(grep -oP "$XMPL_CURRENT_REPO *= *\K.*" ${XMPL_HOME}/.xmpl/repo.conf)
	else
		XMPL_REPO='xmpl-tool/xmpl-repo'
		if [ $XMPL_MODE_ONLINE == 0 ];then
			XMPL_MODE_ONLINE=1
		fi
	fi
	XMPL_USERNAME=$(dirname $XMPL_REPO)
	
	#online / offline mode switch
	if [[ $XMPL_USERNAME != 'xmpl-tool' ]]; then
		if [ $XMPL_MODE_ONLINE -ge 1 ];then
			echo -e "\e[33mOnline mode is not possible on forked repository!\e[39m" >&2
		fi
		XMPL_MODE_ONLINE=0
	else
		if [ $XMPL_MODE_ONLINE == 0 ];then
			if [ -d ${XMPL_HOME}/.xmpl/repos/$XMPL_USERNAME ]; then
				XMPL_MODE_ONLINE=0
			else
				XMPL_MODE_ONLINE=1
			fi
		else
			echo -e "\e[33mForcing online mode!\e[39m" >&2
		fi
	fi	
	
	if [[ $package == '.' ]] || [[ $package == '+' ]]; then
		package="."
		if [ $XMPL_MODE_ONLINE -ge 1 ];then
			package="+"
		fi
	fi

	if [ -z ${package} ];then
		listAllPackages $1
	else
		if [ -z ${query} ];then
			selectMode $package 	
		else
			selectMode $package $query 	
		fi
	fi
}

function listAllPackages {

		local out names paths urls i n j raw data input

		if [ $XMPL_MODE_ONLINE -ge 1 ];then
			out=$(curl --silent https://api.github.com/search/code?q=path:commands+extension:desc+repo:${XMPL_REPO} --stderr - | jq '.items[] | {name, path, html_url}') #Get results from API
			names+=($(echo "$out" | jq -r '.name' | sort | sed -E 's/.xmpl|.desc//')) #Parse names in array
			paths+=($(echo "$out" | jq -r '.path' | sort | awk -F "/" '{print $2}')) #Parse paths in array
			urls+=($(echo "$out" | jq -r '.html_url' | sort -t '/' -k 9,9 )) #Parse urls in array
		else

			#Auto sync..
			if [ $XMPL_USERNAME == 'xmpl-tool' ];then
				if [[ ${XMPL_LAST_REPO_UPDATE} != $(date +%F) ]];then
					if $(cd ${XMPL_HOME}/.xmpl/repos/${XMPL_REPO} && git diff @{upstream} --quiet >&2 );then
						echo -e "\e[33mUpdating main repository...\e[39m" >&2
						$(cd ${XMPL_HOME}/.xmpl/repos/${XMPL_REPO} && git pull >&2 )
					fi
					editConfig 'XMPL_LAST_REPO_UPDATE' $(date +%F) ~/.xmpl/xmpl.conf
					XMPL_LAST_REPO_UPDATE=$(date +%F)
				fi
			fi
		
			out=$(intersectionGrep "." "" "desc" ${XMPL_HOME}/.xmpl/repos/${XMPL_REPO} | sort)
			#dirname $out
			names+=($(echo "$out" | sed -e 's/.*\///' -e 's/.desc//'))
			paths+=($(dirname $out | sed 's/.*\///')) #Parse paths in array
			urls+=($(echo "$out" ))
		fi
		i=0
		trap escapeBreak INT
		for n in ${names[@]}; do #For each title
			
			echo -e "\e[96m\c" >&2 #Color cyan
				j=$(( $i + 1 ))
				echo -e "$j ${paths[$i]}  \c" >&2  #Print package name to stdout

			echo -e "\e[32m\c" >&2 #Color green
			if [ $XMPL_MODE_ONLINE == 1 ];then
				data=""
			elif [ $XMPL_MODE_ONLINE == 2 ];then
				raw=$(echo -e ${urls[$i]} | sed -e 's/https:\/\/github.com/https:\/\/raw.githubusercontent.com/; s/\/blob\//\//;') #Replacing html url with raw url
				data=$(curl --silent $raw --stderr - | sed '/^[[:blank:]]*#/d;s/#.*//') #Get raw data and remove commnets
			else
				data=$(cat ${urls[$i]} | sed '/^[[:blank:]]*#/d;s/#.*//') #Get raw data and remove commnets
			fi
			echo "$data" | head -1 >&2   #Print output to stdout
			echo -e "\e[39m\c" >&2 #Color default
			i=$((i+1)) #Counter + 1
		done
		trap '' INT						
				input=0 #Set input to 0	
				while ! [ "$input" -le "$j" -a "$input" -gt 0 ] 2>/dev/null; do
					#Reading user input
					if ! input=$(test -z $fkey && xmplRead "Please select package:" 1 1 $i || return 1);then
						return 1
					fi	
					#check if input is number
					if ! [[ $input =~ "^[0-9]+$" ]] ; then
						#if not find id by name
					   	input=$(printf '%s\n' "${paths[@]}" | grep -nw $input | cut -f1 -d:)
					fi
				done
				input=$((input-1)) # input = userinput - 1
				#select package
				selectMode ${names[$input]}
				
}

function selectMode {

		local package query names paths urls out i n input 

		package=$1
		query=$2
		
		if [ $XMPL_MODE_ONLINE -ge 1 ];then
			out=$(curl --silent https://api.github.com/search/code?q=${query}+path:commands/${package}+extension:xmpl+repo:${XMPL_REPO} --stderr - | jq '.items[] | {name, path, html_url}') #Get results from API
			names+=($(echo "$out" | jq -r '.name' | sort | sed -E 's/.xmpl|.desc//')) #Parse names in array
			paths+=($(echo "$out" | jq -r '.path' | sort | awk -F "/" '{print $2}')) #Parse paths in array
			urls+=($(echo "$out" | jq -r '.html_url' | sort -t '/' -k 9,9 )) #Parse urls in array
		else
			out=$(intersectionGrep "$package" "$query" "xmpl" "${XMPL_HOME}/.xmpl/repos/$XMPL_REPO" | sort) #get local results
			names+=($(echo "$out" | sed -e 's/.*\///' -e 's/.xmpl//')) #Parse names in array
			paths+=($(dirname $out 2>/dev/null | sed 's/.*\///')) #Parse paths in array
			urls+=($(echo "$out" )) #Parse urls in array
		fi
		
		i=0	#Set counter to 0
		if [ "${#names[@]}" -gt 1 ]; then #For more then 1 example result
			trap escapeBreak INT #enable ctrl-c while listing
			for n in ${names[@]}; do #For each example
				i=$((i+1)) #Counter +1
				if [[ $package == "." || $package == "+" ]];then
					echo -e "\e[96m$i ${paths[$((i-1))]} \e[32m$n\e[39m" >&2 #Print title to selection list
				else
					echo -e "\e[96m$i \e[32m$n\e[39m" >&2 #Print title to selection list	
				fi
			done
			trap '' INT #reset ctrl-c
			input=0 #Set input to 0	
			#Reading user input
			while ! [ "$input" -le "$i" -a "$input" -gt 0 ] 2>/dev/null; do
				if ! input=$(test -z $fkey && xmplRead "Please select example number:" 1 1 $i || return 1);then
					return 1
				fi	
			done
						
			input=$((input-1)) #Real input = User input - 1

		elif [ "${#names[@]}" -eq 1 ]; then	#For 1 example result 
			i=1 #Counter to 1
			input=0 #Input to 0
		else #For no results
			i=0 #Counter to 0
			input=0 #Input to 0
		fi

			if [ $i -ne 0 ]; then #If result exists
				#execute example
				executeMode ${names[$input]} ${paths[$input]} ${urls[$input]}
			else #No results message
				echo -e "\e[33mNo results found!\e[39m" >&2 # Print message
			fi
			#saving selection
			XMPL_LAST_EXAMPLE=${names[$input]}
			XMPL_LAST_PATH=${paths[$input]}
			XMPL_LAST_URL=${urls[$input]}
} 

function executeMode {

	local raw arg parm arguments a ename epath eurl
	
	ename=$1
	epath=$2
	eurl=$3
 
	if ! [ -z ${epath} ];then

			echo -e "\e[96m\c" >&2 #Color cyan
			if [ $ename == $epath ]; then
				echo -e "$epath:" >&2 #Print package name to stderr
			else
				echo -e "$epath: $ename" >&2  #Print package name and exemple title to stdout
			fi
			echo -e "\e[39m\c" >&2 #Color default
			
				if [ $XMPL_MODE_ONLINE -ge 1 ];then
					raw=$(echo -e $eurl | sed -e 's/https:\/\/github.com/https:\/\/raw.githubusercontent.com/; s/\/blob\//\//;') #Replacing html url with raw url
					
						XMPL_PRE_RESULT=$(curl --silent $raw --stderr - ) #Get example raw result 

				else
					raw=$eurl
					XMPL_PRE_RESULT=$(cat $raw)
				fi
							
				XMPL_RESULT=$(echo "$XMPL_PRE_RESULT" | sed '/^[[:blank:]]*#/d;s/#.*//' ) #Get example raw result and remove comments				
				
				if [[ $XMPL_MODE_RAW == 0 ]] ;then
					XMPL_PRE_RESULT=$(echo "$XMPL_PRE_RESULT" | sed '/^[[:blank:]]*#/d;s/#.*//' ) #Get example raw result and remove comments
				elif [[ $XMPL_MODE_RAW == 1 ]];then
					XMPL_PRE_RESULT=$(echo "$XMPL_PRE_RESULT" | awk 'NR>2') #Get example raw result and remove comments
				fi	
				
				if [[ $XMPL_MODE_INPUT == 1 ]]; then #User puts arguments
					arguments=$(echo $XMPL_PRE_RESULT | grep -Po '{:[^:]*:}') #Get all arguments from example
					
					if [[ ${arguments} != '' ]];then #If arguments exists
						echo -e "\e[93m\c" >&2 #Color yellow
						echo "$XMPL_PRE_RESULT" >&2 #Output command input preview to stderr
						echo -e "\e[39m\c" >&2 #Color default
					fi
					a=0
				
					for arg in $arguments #For each argument
					do
						if [[ ${arg} != '' ]]; then #If argument exists 
								if [[ ! -z ${XMPL_INPUTS[$a]} ]] ;then
									#use existing user inputs
									parm=${XMPL_INPUTS[$a]}
									#Review the existing user input arguments
									echo -e "\e[36m$arg:\e[39m" | sed -e 's/{://' -e 's/:}//' >&2 
									
									if [[ ! ${parm: -1} == " " ]]; then
											echo -e $parm >&2
										else
											if [[ ! "$parm" =~ "'" ]]; then
												echo -e "'$parm'" >&2
											else
												if [[ ! "$parm" =~ "\"" ]]; then
													echo -e "\"$parm\"" >&2
												else
													echo -e "$parm" >&2
												fi
											fi
										fi		
									
								else
									trap 'return' INT #return to ctrl+c for exiting read function
									echo -e "\e[36m$arg:\e[39m" | sed -e 's/{://' -e 's/:}//' >&2 #Asking user to input argument
									if [ "$XMPL_LAST_URL" == "$eurl" ];then
										if [[ ! ${old_inputs[$a]: -1} == " " ]]; then
											read -e -i "${old_inputs[$a]}" parm #read input with last input suggestion
										else
											if [[ ! "$old_inputs[$a]" =~ "'" ]]; then
												read -e -i "'${old_inputs[$a]}'" parm #read input with last input suggestion
											else
												if [[ ! "$old_inputs[$a]" =~ "\"" ]]; then
													read -e -i "\"${old_inputs[$a]}\"" parm #read input with last input suggestion
												else
													read -e -i "${old_inputs[$a]}" parm #read input with last input suggestion
												fi
											fi
										fi
									else
										read -e parm #read new input
									fi
									trap - INT
									parm=$(echo "${parm%% }") #remove last whitespace from user input (because autocomplete end with whitespace)
									if [ ${parm:0:1} == "\"" ] && [ ${parm: -1} == "\"" ];then #if value is commented with double quote
										#remove double quote
										parm=$(echo "${parm//\"/}")
										parm=$(echo "${parm%%\"}")
									elif [ ${parm:0:1} == "'" ] && [ ${parm: -1} == "'" ];then #if value is commented with single quote
										#remove single quote
										parm=$(echo "${parm//\'/}")
										parm=$(echo "${parm%%\'}")
									fi
									XMPL_INPUTS+=(${parm})
								fi

								#parms ecape chars 3x
								parm=$(echo "${parm}" | sed -e 's/\\/\\\\/g; s/ /\\ /g;' | sed -e 's/\\/\\\\\\\\/g; s/&/\\\\\\&/g;' )

								XMPL_RESULT=$(echo "$XMPL_RESULT" | sed -e 's,'"$arg"','"$parm"',') #Putting argument in command
								XMPL_PRE_RESULT=$(echo "$XMPL_PRE_RESULT" | sed -e 's,'"$arg"','"$parm"',') #Putting argument in command
							a=$((a+1))
						fi
					done
					#prepare result for execution
					XMPL_RESULT=$(echo "$XMPL_RESULT" | sed -e "s/'/\\'/g;" | sed -e 's/"/\\"/g; s/&/\\\&/g;')
					echo -e "\e[92m\c" >&2 #Color green
					XMPL_PRE_RESULT=$(echo "$XMPL_PRE_RESULT" | sed -e 's/\$/\\$/g;')
					XMPL_RESULT=$(echo "$XMPL_RESULT" | sed -e 's/\$/\\$/g;')
					if [[ $XMPL_MODE_INPUT == 1 ]] && [[ $XMPL_MODE_EXECUTE == 0 ]]; then #If input mode
						printf '%s\n' $(eval "echo \"$XMPL_PRE_RESULT\"") #Print evaled result to stdout
					else #if execute mode
						printf '%s\n' $(eval "echo \"$XMPL_RESULT\"") >&2 #Print evaled result to stderr
					fi
					
					echo -e "\e[39m\c" >&2 #Color default
						
					if [[ $XMPL_MODE_EXECUTE == 1 ]]; then

						#eval echo to convert ~ to path
						XMPL_RESULT=$(eval "echo \"$XMPL_RESULT\"" | sed '/^[[:blank:]]*#/d;s/#.*//') #Remove comments and execute pre-evaled command
						
						echo 2>/dev/null "$XMPL_RESULT" 1>&3 #Print results to stdout2 only
						trap 'return' INT
						eval "$XMPL_RESULT"
						trap - INT
						if [ $? -eq 0 ]; then
							echo -e "\e[35mEXECUTED\e[39m" >&2 #Command executed
						else
							echo -e "\e[31mERROR\e[39m" >&2 #Execution failed
						fi
					fi
					
				else
					echo -e "\e[92m\c" >&2 #Color green
					echo "$XMPL_PRE_RESULT" #Print results to stdout
					echo -e "\e[39m\c" >&2 #Color default
				fi
			
	else
		listAllPackages
	fi
					
}
##################################################################
# EDITOR FUNCTIONS

#TODO: create multiline editor function (-E)
#edit example in default editor (vi/nano)

#TODO: create function for deleteing examples

function xmplEditor {

	local input data tags title package newRepoAlias XMPL_USERNAME response response2 names paths urls outFile

	package=$1
	newRepoAlias=$2

	if ! getRepository $newRepoAlias;then
		return
	fi

	XMPL_REPO=$(grep -oP "$XMPL_CURRENT_REPO *= *\K.*" ${XMPL_HOME}/.xmpl/repo.conf)
	XMPL_USERNAME=$(dirname $XMPL_REPO)

	if [[ "$XMPL_USERNAME" == "xmpl-tool" ]];then
		echo -e "\e[33mNot possible to edit xmpl main repository directly!" >&2
		echo -e "Please use private repository!\e[39m" >&2
		return 1
	fi

	while [ -z ${package} ];do
		echo -e "Enter package name:" >&2
		read -e package
	done
	
		if [[ ! -z ${package} ]];then
			if ! [ -f ${XMPL_HOME}/.xmpl/repos/$XMPL_REPO/commands/$package/$package.desc >& /dev/null ] ;then
				echo -e "Create new package '${package}'? [Y/n]" >&2
				read response

				response=${response,,} # tolower
					if [[ $response =~ ^(yes|y| ) ]] || [[ -z ${response} ]]; then
						
						
						response2=NO
						
						while ! [[ $response2 =~ ^(yes|y) ]] 2>/dev/null; do
							input=0 #Set input to 0	
							echo -e "Please enter description for package '$package':"
							read -e input
							echo -e "Is this description correct? [y/N]"
							read response2

							response2=${response2,,} # tolower
						done
						
						mkdir -p ${XMPL_HOME}/.xmpl/repos/$XMPL_REPO/commands/$package/
						echo "#$package" > ${XMPL_HOME}/.xmpl/repos/$XMPL_REPO/commands/$package/$package.desc
						echo "$input" >> ${XMPL_HOME}/.xmpl/repos/$XMPL_REPO/commands/$package/$package.desc
					else
						return 0
					fi

			fi
			#TODO: sort examples
			names+=($(find ${XMPL_HOME}/.xmpl/repos/$XMPL_REPO/commands/$package -type f -name "*.xmpl" -exec  basename -s ".xmpl" {} \;))
			paths+=($(find ${XMPL_HOME}/.xmpl/repos/$XMPL_REPO/commands/$package -type f -name "*.xmpl" -exec sh -c "dirname {} | sed 's/.*\///'" \;))
			urls+=($(find ${XMPL_HOME}/.xmpl/repos/$XMPL_REPO/commands/$package -type f -name "*.xmpl"))
					
			if [ "${#names[@]}" -ge 1 ]; then #For 1 or more example result
			
			i=0	#Set counter to 0
			echo -e "\e[96m$i \e[32mNEW\e[39m" >&2 #Print title to selection list

				for n in ${names[@]}; do #For each example
					i=$((i+1)) #Counter +1
					echo -e "\e[96m$i \e[32m$n\e[39m" >&2 #Print title to selection list
				done
				input=-1 #Set input to -1
				while ! [ "$input" -le "$i" -a "$input" -ge 0 ] 2>/dev/null; do
					#Asking user to select example
					if ! input="$(xmplRead 'Please select example number:' 0 0 $i)";then
						return 1
					fi
				done
				
				input=$((input-1)) #Real input = User input - 1

			else #For no results
				i=0 #Counter to 0
				input=-1 #Input to -1
			fi
			#echo $input
			
			if [ $input -ge 0 ];then #if input >= 0
				title=${names[$input]}
				data=$(cat ${urls[$input]} | sed '/^[[:blank:]]*#/d;s/#.*//') #Get raw data and remove commnets
				tags=$(cat ${urls[$input]} | sed 's/#//;2q;d')
			else		

				while [ -z ${title} ];do
				response2=NO
				
					while [[ ! $response2 =~ ^(yes|y) ]]; do
						echo -e "Enter example title:" >&2
						read -e -i "$title" title 
						echo -e "Is this title correct? [y/N]" >&2
						read response2

						response2=${response2,,} # tolower
					done
				done
				
			fi
			echo -e "\e[33mEdit example '${title}'\e[39m" >&2
			
			#TODO: enable examples renaming
			
			while : ;do
			response2=NO
				while [[ ! $response2 =~ ^(yes|y) ]]; do
					echo -e "Enter command with input variable structure {:variable name:}" >&2
					read -e -i "$data" data				
					echo -e "Is this command correct? [y/N]" >&2
					read response2

					response2=${response2,,} # tolower
				done
				[ -z ${data} ] || break
			done

			while : ;do
			response2=NO
				while [[ ! $response2 =~ ^(yes|y) ]] 2>/dev/null; do
					echo -e "Edit search tags:" >&2
					read -e -i "$tags" tags		
					echo -e "Is this correct? [y/N]" >&2
					read response2

					response2=${response2,,} # tolower
				
				done
				[ -z ${tags} ] || break
			done				
			
			outFile=${title//[\/]/ }
			echo "#${title,,}" > ${XMPL_HOME}/.xmpl/repos/$XMPL_REPO/commands/$package/${outFile}.xmpl
			echo "#${tags,,}" >> ${XMPL_HOME}/.xmpl/repos/$XMPL_REPO/commands/$package/${outFile}.xmpl			
			echo "${data}" >> ${XMPL_HOME}/.xmpl/repos/$XMPL_REPO/commands/$package/${outFile}.xmpl

			echo -e "\e[33mExample '${title}' successfully modified!\e[39m" >&2
			echo -e "\e[32m" >&2
			cat ${XMPL_HOME}/.xmpl/repos/$XMPL_REPO/commands/$package/$outFile.xmpl >&2
			echo -e "\e[39m" >&2

		fi
	
}
##################################################################
# OTHER FUNCTIONS
function editConfig {

	local key data CONFIG_FILE
	
	key=$1
	data=$2
	CONFIG_FILE=$3
	
	if grep -q "$key *= *" $CONFIG_FILE; then   
	   sed -i "s,^\($key=\).*,\1$data," $CONFIG_FILE
	else
	   echo "$key=$data" >> $CONFIG_FILE
	fi
}

function intersectionGrep {

	local package query first second i filter

	package=$1
	query+=($(echo $2 | tr "+" "\n"))
	filter="*.$3"
	repo=$4
	
	first=$(grep --include=${filter} -e "${query[0]}"  -rnwl $repo/commands/$package 2>/dev/null)
	for (( i=1; i<${#query[@]}; i++))
	do
			second=$(grep --include=${filter} -e "${query[$i]}"  -rnwl $repo/commands/$package 2>/dev/null)
			first=$(awk 'NR==FNR{a[$0]=$0;next}a[$0]' <(echo "$first") <(echo "$second"))
	done
	echo "$first"
}


function xmplRead {

	local IFS final input tmp message default min max

	message=$1
	default=$2
	min=$3
	max=$4
	
	echo -e '\e[97m\c' >&2
	echo -e $message >&2 
	echo -e '\e[39m\c' >&2
	if [[ ${default} != ${min} ]];then
		final=$2
		echo -e "$final\c" >&2
	fi

	trap ctrl_c INT
	IFS=""
	while read -r -n1 -s input
	do

		if [[  ${input} == $'\e' ]];then
			read -rsn1 -t 0.1 tmp
				if [[ "$tmp" == "[" ]]; then
					read -rsn1 -t 0.1 tmp
					case "$tmp" in
						"B" ) 
							if [ ! -z $min ];then
								if [ -z $final ];then
									final=$((min-1))
								fi
								if [ "$final" -eq "$final" >& /dev/null ]; then 
									echo -e "\033[2K\c" >&2 
									final=$((final + 1))
									[ $final -gt $max ] && final=$min
									echo -e "\r$final\c" >&2
								fi
							fi
						;;
						"A" ) 
							if [ ! -z $min ];then
								if [ -z $final ];then
									final=$((min-1))
								fi
								if [ "$final" -eq "$final" >& /dev/null ]; then 
									echo -e "\033[2K\c" >&2 
									final=$((final - 1))
									[ $final -lt $min ] && final=$max
									echo -e "\r$final\c" >&2
								fi
							fi
						;;
					#	"C" )
					#		echo "Right\n" >&2
					#	"D" ) 
					#		echo "Left\n" >&2
					#	;;
						* )
							read -rsn1 -t 0.1 tmp
						;;
					esac
				else
					echo "" >&2
					return 1
				fi
		
		elif [ "${input}" == $'\177' ] || [ "${input}" == $'\b' ];then
			final="${final%?}"
			echo -e "\r\033[K${final}\c" >&2
		elif [[ ${input} == "" ]];then
			echo "$final"
			echo -e "" >&2
			return 0
		else
			if [ -z ${tmp} ];then
				final+=$input
				echo -e "$input\c" >&2
			else
				unset tmp
			fi
		fi
	done
}

function showHelp {
	echo "	"
	if [ -f ${XMPL_HOME}/.xmpl/repo.conf ];then
		echo "Full usage:"
		echo "	"
		echo -e " \e[1mxmpl\e[0m"
		echo -e "	\e[1mfilter_1 filter_2\e[0m"
		echo -e "	[--search] \e[1mfilter_1 filter_2\e[0m"
		echo -e "	[--package] [--edit] \e[1mpackage\e[0m"
		echo -e "	[--input] [--execute] [--execute-last] \e[1margument_1 argument_2\e[0m"
		echo -e "	[--new-repo] \e[1mgithub_user/repo\e[0m"
		echo -e "	[--delete-repo] [--change-repo] [--save-repo]"
		echo -e "	[--sync-repo] [--pull-request] \e[1mrepo_alias\e[0m"
		echo -e "	[--comments] [--raw] [--online] [--full-online] [--last]"
		echo -e "	[--install] [--update] [--deinstall] [--version] [--help]"
	else
		echo "No-install usage:"
		echo "	"
		echo -e " \e[1mxmpl\e[0m"
		echo -e "	\e[1mfilter_1 filter_2\e[0m"
		echo -e "	[--search] \e[1mfilter_1 filter_2\e[0m"
		echo -e "	[--package] \e[1mpackage\e[0m"
		echo -e "	[--input] [--execute] [--execute-last] \e[1margument_1 argument_2\e[0m"
		echo -e "	[--comments] [--raw] [--full-online] [--last] [--install] [--version] [--help]"
	fi	  
	echo ""
	echo ""
	echo -e " \e[1mxmpl\e[0m 					List available packages"
	echo " "
	echo "   [<query>]				Search all examples with query"
	echo "  "	  
	echo "   -s [<query>]		 --search	Search examples with query"
	echo "   -p [package]		 --package	Filter by package"		  
	echo "  "	  
	echo "   -c			 --comments	Display comments in examples"
	echo "   -C			 --raw		Display raw example"
	echo "  "	  	
	if [ -f ${XMPL_HOME}/.xmpl/repo.conf ];then
		echo "   -o 			 --online	Force online mode"
	fi
	echo "   -O 			 --full-online	Force online mode with descriptions"
	echo "   "
	echo "   -i [<arguments>]	 --input	Input mode"
	echo "   -x [<arguments>]	 --execute	Execute mode"
	echo "   "
	echo "   -l			 --last		Show last selected example"
	echo "   -X [<arguments>]	 --execute-last	Execute last selected example"
	echo "  "
    echo "   -I			 --install	Install on local system"
	if [ -f ${XMPL_HOME}/.xmpl/repo.conf ];then
		echo "   -U			 --update	Update to latest version"
		echo "   -D			 --deinstall	Deinstall from local system"
		echo "   "
		echo "   -n [github_user/repo] --new-repo	Add new private repository"	  
		echo "   -d [repo_alias]	 --delete-repo	Delete local repository"	  
		echo "   "
		echo "   -r [repo_alias]	 --change-repo	Switch repository source"	  
		echo "   -R [repo_alias]	 --save-repo	Switch and store repository source"
		echo "   "
		echo "   -e [package]		 --edit		Edit package in private repository"
		echo "   "
		echo "   -S [repo_alias]	 --sync-repo	Synchronize local and remote repository"
		echo "   -P [repo_alias]	 --pull-request	Send changes to xmpl main repository"
		echo "	"
		
	fi
	echo "   -v			 --version	Display version"
	echo "   -? / -h		 --help		Show xmpl help page"
	echo "  "

}

##################################################################
# MAIN SCRIPT

version='1.0.5'

oIFS=$IFS 	#Saving old IFS
IFS=$'\n' 	#Delimiter to new line
XMPL_USER=$USER
if ! [ -z $SUDO_USER ];then 
	XMPL_USER=$SUDO_USER
fi
XMPL_HOME=$(eval echo "~${XMPL_USER}")

#parms to nothing
XMPL_OUTPUT=""
XMPL_PACKAGE=""
XMPL_QUERY=""

#Setting working modes
XMPL_MODE_QUERY=1 	#search
XMPL_MODE_EDIT=0 	#edit
XMPL_MODE_RAW=0 	#comments
XMPL_MODE_INPUT=0 	#input
XMPL_MODE_EXECUTE=0 #execute
XMPL_MODE_ONLINE=0 	#online
XMPL_MODE_HISTORY=0 #histpry
XMPL_MODE_NULL=0 	#nothing

XMPL_DEFAULT_REPO='main' #set default repo to main

OPTIND=1 #setting option index to 1

flags=":spcCOixlXIhv-:?" #noinstal mode

#if xmpl is installed
if [ -f ${XMPL_HOME}/.xmpl/xmpl.conf ];then
	source ${XMPL_HOME}/.xmpl/xmpl.conf #load conf
	flags=":spcCoOixlXIUDndrReSPhv-:?" 		#full mode
fi
#current repo = default repo
XMPL_CURRENT_REPO=$XMPL_DEFAULT_REPO 

#if repo config installed
if [ -f ${XMPL_HOME}/.xmpl/repo.conf ];then
	#load config
	XMPL_REPO=$(grep -oP "$XMPL_CURRENT_REPO *= *\K.*" ${XMPL_HOME}/.xmpl/repo.conf)
else
	#force online mode
	XMPL_MODE_ONLINE=1
	#set xmpl main repo 
	XMPL_REPO='xmpl-tool/xmpl-repo'
fi

#getting query after command
until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}") ]]; do
		query+=($(eval "echo \${$OPTIND}"))
		shift
done

#save old inputs
old_inputs=(${XMPL_INPUTS[@]})
unset XMPL_INPUTS

# Parse options to the `xmpl` command
while getopts $flags flag; do

	if [[ "${flag}" == "-" ]];then
		case ${OPTARG} in
		"search" ) 		flag=s;;
		"package" )		flag=p;;
		"comments" ) 	flag=c;;
		"raw" )			flag=C;;
		"online" ) 		flag=o;;
		"full-online" )	flag=O;;
		"input" ) 		flag=i;;
		"execute" )		flag=x;;
		"last" ) 		flag=l;;
		"execute-last" )flag=X;;
		"install" )		flag=I;;
		"update" ) 		flag=U;;
		"deinstall" ) 	flag=D;;
		"new-repo" ) 	flag=n;;
		"delete-repo" )	flag=d;;
		"change-repo" )	flag=r;;
		"save-repo" ) 	flag=R;;
		"edit" ) 		flag=e;;
		"sync-repo" ) 	flag=S;;
		"pull-request" )flag=P;;
		"help" ) 		flag=h;;
		"version" )		flag=v;;
		*)
			#Invalid option
			echo -e "\e[33mInvalid option: --$OPTARG\e[39m" >&2
			echo "Use 'xmpl --help' or 'xmpl -?' for help" >&2
			XMPL_MODE_NULL=1
			if [ ! return >& /dev/null ];then
				exit
			fi
		;;
		esac
	fi
	
	case ${flag} in
	s )
		#Search mode
		#if no query, take query after flag
		if [ -z $query ];then
			until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}") ]]; do
					query+=($(eval "echo \${$OPTIND}"))
					shift
			done
		else
			until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}") ]]; do
					shift
			done
		fi
	;;
	p )
		#Package mode
		package=""
		#get package
		until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}") ]]; do
				package=$(eval "echo \${$OPTIND}")
				shift
		done
		if [ -z $package ];then
			XMPL_PACKAGE=""
		else
			XMPL_PACKAGE=$package
		fi
	;;
	c )
		#comments on
		XMPL_MODE_RAW=1
	;;
	C )
		#raw file on
		XMPL_MODE_RAW=2
	;;
	o )
		#force online mode
		XMPL_MODE_ONLINE=1
	;;
	O )
		#force online mode with descriptions
		XMPL_MODE_ONLINE=2
	;;
	i )
		#Input mode
		XMPL_MODE_INPUT=1
		#getting inputs
		until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}") ]]; do
				XMPL_INPUTS+=($(eval "echo \${$OPTIND}"))
				shift
		done
	;;
	x )
		#execute mode
		XMPL_MODE_INPUT=1
		XMPL_MODE_EXECUTE=1
		#getting inputs
		until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}") ]]; do
				XMPL_INPUTS+=($(eval "echo \${$OPTIND}"))
				shift
		done
		
		
	;;
	l )
		#last command
		if [ -z $XMPL_LAST_PATH ];then
			echo -e "\e[33mLast command not found for user `whoami`!\e[39m" >&2
		else
			XMPL_MODE_HISTORY=1
		fi
		XMPL_MODE_NULL=1
	;;
	X )
		#execute last command
		XMPL_MODE_INPUT=1
		XMPL_MODE_EXECUTE=1
		XMPL_MODE_NULL=1
		#getting inputs
		until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}") ]]; do
				XMPL_INPUTS+=($(eval "echo \${$OPTIND}"))
				shift
		done
		#if no inputs, use last inputs
		if [ -z $XMPL_INPUTS ];then
			XMPL_INPUTS=(${old_inputs[@]})
		fi
		#check for last command
		if [ -z $XMPL_LAST_PATH ];then
			echo -e "\e[33mLast command not found for user `whoami`!\e[39m" >&2
		else
			XMPL_MODE_HISTORY=1
		fi
	;;
	I )
		#Install local
		installLocal
		source ${XMPL_HOME}/.bashrc
		byebye #?
		if ! return >& /dev/null; then
			exit
		fi
	;;
	U )
		#Update script
		updateLocal
		byebye #?
		if ! return >& /dev/null; then
			exit
		fi
	;;
	D )
		#Deinstall local
		deinstallLocal
		byebye #?
		if ! return >& /dev/null; then
			exit
		fi
	;;
	n )
		#New repo
		#get GitHub repo
		until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}") ]];do
			git_repo=$(eval "echo \${$OPTIND}")
			shift
		done
		#if repo exists, check status
		if [ ! -z $git_repo ];then
			status=$(curl --silent  https://api.github.com/repos/$git_repo --stderr - | jq '.id')
		else
			#using main repo
			git_repo='xmpl-tool/xmpl-repo'
			status='OK'
		fi
		#if repository exist
		if [ ${status} != "null" ]; then
			addNewRepository "" "" $git_repo
		else
			echo -e "\e[33mGitHub repository does not exist!\e[39m" >&2
		fi
		byebye #?
		if ! return >& /dev/null; then
			exit
		fi
	;;
	d )
		#delete repo
		unset repo
		#get repo alias
		until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}") ]];do
			repo=$(eval "echo \${$OPTIND}")
			shift
		done
		delLocalRepository $repo
		byebye #?
		if ! return >& /dev/null; then
			exit
		fi
	;;
	r )
		#change repo
		unset repo
		#get repo alias
		until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}") ]];do
			repo=$(eval "echo \${$OPTIND}")
			shift
		done
		#switch repo
		if getRepository $repo; then
			echo -e "\e[33mUsing '$XMPL_CURRENT_REPO' repository!\e[39m" >&2
		fi
	;;
	R )
		#change and save repo
		repo=""
		#get repo alias
		until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}") ]];do
			repo=$(eval "echo \${$OPTIND}")
			shift
		done
		#switch repo
		changeRepository $repo
		XMPL_MODE_NULL=1
	;;
	e )
		#edit mode
		package=""
		#get package
		until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [[ -z $(eval "echo \${$OPTIND}") ]]; do
				package=$(eval "echo \${$OPTIND}")
				shift
		done
		XMPL_PACKAGE=$package

		XMPL_MODE_QUERY=0
		XMPL_MODE_EDIT=1
		if [ ! return >& /dev/null ];then
			exit
		fi
	;;
	S )
		#sync repo
		repo=$(eval "echo \${$OPTIND}")
		$(syncRepository $repo)
		XMPL_MODE_NULL=1
		#byebye #?
		if [ ! return >& /dev/null ];then
			exit
		fi
	;;
	P )
		#pull repo
		repo=$(eval "echo \${$OPTIND}")
		$(syncRepository $repo)
		pullRepository $repo
		XMPL_MODE_NULL=1

		if [ ! return >& /dev/null ];then
			exit
		fi
	;;
	h )
		#Show help
		XMPL_OUTPUT="$(showHelp)"
		XMPL_MODE_NULL=1
		if [ ! return >& /dev/null ];then
			exit
		fi
	;;
	v )
		#Show version
		echo -e "\e[33mxmpl-tool $version\e[39m"
		XMPL_MODE_NULL=1
		if [ ! return >& /dev/null ];then
			exit
		fi
	;;
	\? )
		#other options
		if [ "$OPTARG" == \? ];then
			#Show help
			XMPL_OUTPUT="$(showHelp)"
			XMPL_MODE_NULL=1
		else
			#Invalid option
			echo -e "\e[33mInvalid option: -$OPTARG\e[39m" >&2
			echo "Use 'xmpl -h' or 'xmpl -?' for help" >&2
		fi
		XMPL_MODE_NULL=1
		if [ ! return >& /dev/null ];then
			exit
		fi
     ;;
  esac
done

#if mode query
if [ $XMPL_MODE_NULL != 1 -a $XMPL_MODE_QUERY == 1 ];then
	for (( i=0; i<=${#query[@]}; i++)) #for each search term
	do
		if [ -z $XMPL_QUERY ];then
				XMPL_QUERY=${query[$i]}
		else
				XMPL_QUERY=$XMPL_QUERY"+"${query[$i]} #Append to query
		fi
	done

	#if no parms, all package mode
	if [ -z $XMPL_PACKAGE ] && [ ! -z $XMPL_QUERY ];then
		XMPL_PACKAGE="."
	fi

	if ! checkRequirements;then
			
		echo -e "\e[33mTry 'sudo bash `basename ${BASH_SOURCE[0]}` -I' for xmpl installation\e[39m"
		if ! return >& /dev/null; then
			exit
		fi
	fi

	#get examples
	queryExamples $XMPL_CURRENT_REPO $XMPL_PACKAGE $XMPL_QUERY

fi
#if edit mode
if [ $XMPL_MODE_NULL != 1 -a $XMPL_MODE_EDIT == 1 ];then
	if [[ $XMPL_PACKAGE == "." ]];then
		XMPL_PACKAGE=""
	fi
	#edit package
	xmplEditor "$XMPL_PACKAGE" "$XMPL_CURRENT_REPO"
fi
#if mode history
if [ $XMPL_MODE_HISTORY == 1 ];then
	#execute last example
	executeMode $XMPL_LAST_EXAMPLE $XMPL_LAST_PATH $XMPL_LAST_URL
fi
#if output exitst
if [ ! -z "$XMPL_OUTPUT" ];then
	echo "$XMPL_OUTPUT"
fi

#clean environment
byebye
