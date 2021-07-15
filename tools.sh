#!/bin/bash

# 颜色 --------------------------------------------------------------------------------------------------------
black=$(tput setaf 0)   ; red=$(tput setaf 1)          ; green=$(tput setaf 2)   ; yellow=$(tput setaf 3);  bold=$(tput bold)
blue=$(tput setaf 4)    ; magenta=$(tput setaf 5)      ; cyan=$(tput setaf 6)    ; white=$(tput setaf 7) ;  normal=$(tput sgr0)
on_black=$(tput setab 0); on_red=$(tput setab 1)       ; on_green=$(tput setab 2); on_yellow=$(tput setab 3)
on_blue=$(tput setab 4) ; on_magenta=$(tput setab 5)   ; on_cyan=$(tput setab 6) ; on_white=$(tput setab 7)
shanshuo=$(tput blink)  ; wuguangbiao=$(tput civis)    ; guangbiao=$(tput cnorm) ; jiacu=${normal}${bold}
underline=$(tput smul)  ; reset_underline=$(tput rmul) ; dim=$(tput dim)
standout=$(tput smso)   ; reset_standout=$(tput rmso)  ; title=${standout}
baihuangse=${white}${on_yellow}; bailanse=${white}${on_blue} ; bailvse=${white}${on_green}
baiqingse=${white}${on_cyan}   ; baihongse=${white}${on_red} ; baizise=${white}${on_magenta}
heibaise=${black}${on_white}   ; heihuangse=${on_yellow}${black}
CW="${bold}${baihongse} ERROR ${jiacu}";ZY="${baihongse}${bold} ATTENTION ${jiacu}";JG="${baihongse}${bold} WARNING ${jiacu}"

function find_os(){
	echo "正在检索系统版本"
	sleep 1
	apt --version > /dev/null
	if [ $? == "0" ];then
	     #根系统
		linux_series=debian

		#发行版
		os=`cat /etc/os-release | grep ID= | grep -v VERSION_ID | awk -F \= '{print $2}'`

		#系统代号
		#release=`cat /etc/os-release | grep VERSION= | awk 'BEGIN{ FS="(" ; RS=")" } NF>1 { print $NF }'`
		release=`cat /etc/os-release | grep VERSION_CODENAME | awk -F \= '{print $2}'`

		#系统版本号
		version=`cat /etc/os-release | grep VERSION_ID | awk -F \" '{print $2}'`
	else
		echo "暂不支持非Debian系"
		exit 2
	fi
	
	echo "你的系统为$linux_series"
	echo "你的发行版为$os"
	echo "你的系统代号为$release"
	echo "你的系统版本为$version"

}



function find_hardware_information(){
    cpu_model=`cat /proc/cpuinfo | grep "model name" | uniq | awk -F : '{print $2}'`
    cpu_core_num=`cat /proc/cpuinfo | grep "cpu cores" | uniq | awk -F : '{print $2}'`
    cpu_siblings_num=`cat /proc/cpuinfo | grep "siblings" | uniq | awk -F : '{print $2}'`

	machine=$(uname -m)
	if [ $machine == "x86_64" ];then
		marchines=amd64
	else
		echo "未检测出来CPU架构"
	fi

	echo "你的CPU架构为$marchines"
}

find_country(){
	apt update && apt install -y curl
	echo "正在获取国家信息"
	country=$(curl -sSL https://api.myip.la/en?json | awk -F \" '{print $14}')
	echo $country
	if [ -z $country ];then
		echo "API获取失败"
		exit 10
	elif [ $country == "CN" ];then
		echo "你当前的网络位于中国大陆"
		ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	else 
		echo "你当前的网络位于$(curl -sSL https://api.myip.la/cn?json | awk -F \" '{print $18}')"
	fi
}

function generate_report(){
	#生成报告文件
	cat > ~/.latezly_tools_report.txt <<EOF

EOF
}

function select_source(){
    mirrors_option=$(whiptail --title "Latezly Toolbox" --radiolist "选择源  空格选择，回车确认" 15 60 8 \
    "1" "中国（mirrors.163.com）" ON \
    "2" "日本（ftp.jp.debian.org）" OFF \
    "3" "韩国（ftp.kr.debian.org）" OFF \
    "4" "美国（ftp.us.debian.org）" OFF \
    "5" "德国（ftp.de.debian.org）" OFF \
    "6" "英国（ftp.uk.debian.org）" OFF \
    "7" "法国（ftp.fr.debian.org）" OFF \
    "8" "俄罗斯（ftp.ru.debian.org）" OFF \
    3>&1 1>&2 2>&3)
    case $mirrors_option in
    1)mirrors_source_url="mirrors.163.com"
    ;;
    2)mirrors_source_url="ftp.jp.debian.org"
    ;;
    3)mirrors_source_url="ftp.kr.debian.org"
    ;;
    4)mirrors_source_url="ftp.us.debian.org"
    ;;
    5)mirrors_source_url="ftp.de.debian.org"
    ;;
    6)mirrors_source_url="ftp.uk.debian.org"
    ;;
    7)mirrors_source_url="ftp.fr.debian.org"
    ;;
    8)mirrors_source_url="ftp.ru.debian.org"
    ;;
    esac
    echo "你选择的源是"$mirrors_source_url
}

function change_source(){
	echo "正在准备换源"
	sleep 1
	http_s=http
	#debian默认没有ca证书，无法使用https。apt install apt-transport-https ca-certificates
	debian_series_source_dir=/etc/apt/sources.list
	mirrors_source_url=
	if [ $os == "debian" ];then
		cat > $debian_series_source_dir <<EOF
deb $http_s://$mirrors_source_url/$os/ $release main contrib non-free
deb $http_s://$mirrors_source_url/$os/ $release-updates main contrib non-free
deb $http_s://$mirrors_source_url/$os/ $release-backports main contrib non-free
deb $http_s://$mirrors_source_url/$os-security $release/updates main contrib non-free
EOF
	elif [ $os == "ubuntu" ];then
		cat > $debian_series_source_dir <<EOF
deb $http_s://$mirrors_source_url/$os/ $release main restricted universe multiverse
deb $http_s://$mirrors_source_url/$os/ $release-updates main restricted universe multiverse
deb $http_s://$mirrors_source_url/$os/ $release-backports main restricted universe multiverse
deb $http_s://$mirrors_source_url/$os/ $release-security main restricted universe multiverse
EOF
	fi
}
#======================================================================
# Main
function main(){
OPTION=$(whiptail --title "Latezly Toolbox" --menu "" 15 60 8 \
	"1" "检测系统  【 发行版、系统、版本号、架构、网络、磁盘 】" \
	"2" "系统设置  【 换源、时区、语言 】" \
	"3" "安装应用  【 基础环境、编译环境、虚拟化环境 】" \
	"4" "管理磁盘  【 新增分区、修改分区、删除分区 】" \
	"5" "未定义"  3>&1 1>&2 2>&3)
exitstatus=$?

if [ $exitstatus = 0 ]; then
    #正确选择
    if [ $OPTION -ne 1 ]; then
        if [ -f "~/.latezly_tools_report.txt" ]; then
            echo "已找到系统检测报告"
        else
            echo "未找到系统检测报告，请先检测系统"
            exit 1
        fi
    fi
    case $OPTION in
    1) echo 1
    ;;
    2) echo 2
    ;;
    3) echo 3
    ;;
    4) echo 4
    ;;
    5) echo 5
    ;;
    6) echo 6
    ;;
    *) echo $OPTION
    ;;
    esac
else
    #关闭菜单
    echo "已取消"
    exit 1
fi
}
echo $blue"123"