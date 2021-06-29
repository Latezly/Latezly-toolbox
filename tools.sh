#!/bin/bash

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

function generate_report(){
	#生成报告文件
	cat > ~/.latezly_tools_report.txt <<EOF

EOF
}

function select_source(){
    #选择洲
    function _mirrors_option_continent(){
        mirrors_option_continent=$(whiptail --title "Latezly Toolbox" --radiolist "选择洲  1/3（页）  空格选择，回车确认" 15 60 8 \
        "$1" "$2" ON \
        "$3" "$4" OFF \
        "$5" "$6" OFF \
        3>&1 1>&2 2>&3)
    }
        
    #选择国家
    function _mirrors_option_country(){
        mirrors_option_country=$(whiptail --title "Latezly Toolbox" --radiolist "选择国家  2/3（页）  空格选择，回车确认" 15 60 8 \
        "$1" "$2" ON \
        "$3" "$4" OFF \
        "$5" "$6" OFF \
        3>&1 1>&2 2>&3)
    }
    #选择源
    function _mirrors_option(){
        mirrors_option=$(whiptail --title "Latezly Toolbox" --radiolist "选择源  3/3（页）  空格选择，回车确认" 15 60 8 \
        "$1" "$2" ON \
        "$3" "$4" OFF \
        "$5" "$6" OFF \
        "$7" "$8" OFF \
        3>&1 1>&2 2>&3)
    }
    
    _mirrors_option_continent "1" "亚洲（中国大陆  日本  韩国）"    "2" "美洲（美国  加拿大）"    "3" "欧洲（德国  法国  英国）"
    case $mirrors_option_continent in
    1)
        #亚洲
        _mirrors_option_country "1" "中国大陆（阿里源  163源  清华源  官方源）"    "2" "日本（官方源）"    "3" "韩国（官方源）"
        case $mirrors_option_country in
        1)
            #中国
            _mirrors_option "1" "阿里源(mirrors.aliyun.com)"    "2" "163源(mirrors.163.com)"    "3" "清华源(mirrors.tsinghua.edu.cn)"    "4" "官方源(ftp.cn.debian.org)"
            case $mirrors_option in
            1) mirrors_source_url="mirrors.aliyun.com"
            ;;
            2) mirrors_source_url="mirrors.163.com"
            ;;
            3) mirrors_source_url="mirrors.tsinghua.edu.cn"
            ;;
            4) mirrors_source_url="ftp.cn.debian.org"
            ;;
            esac
        ;;
        2)
            #日本
            _mirrors_option "1" "官方源(ftp.jp.debian.org)"
            case $mirrors_option in
            1) mirrors_source_url="ftp.jp.debian.org"
            ;;
            esac
        ;;
        3)
            #韩国
            _mirrors_option "1" "官方源(ftp.kr.debian.org)"
            case $mirrors_option in
            1) mirrors_source_url="ftp.kr.debian.org"
            ;;
            esac
        ;;
        esac
    ;;
    2)
        #美洲
        _mirrors_option_country "1" "美国(官方源)"    "2" "加拿大（官方源）"
        case $mirrors_option_country in
        1)
            #美国
            _mirrors_option "1" "官方源(ftp.us.debian.org)"
            case $mirrors_option in
            1) mirrors_source_url="ftp.us.debian.org"
            ;;
            esac
        ;;
        2)
            #加拿大
            _mirrors_option "1" "官方源(ftp.ca.debian.org)"
            case $mirrors_option in
            1) mirrors_source_url="ftp.ca.debian.org"
            ;;
            esac
        ;;
        esac
    ;;
    3)
        #欧洲
        _mirrors_option_country "1" "德国（官方源）"    "2" "法国（官方源）"    "3" "英国（官方源）"
        case $mirrors_option_country in
        1)
            #德国
            _mirrors_option "1" "官方源(ftp.de.debian.org)"
            case $mirrors_option in
            1) mirrors_source_url="ftp.de.debian.org"
            ;;
            esac
        ;;
        2)
            #法国
            _mirrors_option "1" "官方源(ftp.fr.debian.org)"
            case $mirrors_option in
            1) mirrors_source_url="ftp.fr.debian.org"
            ;;
            esac
        ;;
        3)
            #英国
            _mirrors_option "1" "官方源(ftp.uk.debian.org)"
            case $mirrors_option in
            1) mirrors_source_url="ftp.uk.debian.org"
            ;;
            esac
        ;;
        esac
    ;;
    esac
    echo "你选择的源是："$mirrors_source_url
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
	"1" "检测系统" \
	"2" "系统设置" \
	"3" "安装应用" \
	"4" "管理磁盘" \
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
select_source