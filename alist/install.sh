#!/bin/sh
source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
MODEL=
UI_TYPE=ASUSWRT
FW_TYPE_CODE=
FW_TYPE_NAME=
DIR=$(
  cd $(dirname $0)
  pwd
)
module=${DIR##*/}

get_model() {
  local ODMPID=$(nvram get odmpid)
  local PRODUCTID=$(nvram get productid)
  if [ -n "${ODMPID}" ]; then
    MODEL="${ODMPID}"
  else
    MODEL="${PRODUCTID}"
  fi
}

get_fw_type() {
	local KS_TAG=$(nvram get extendno|grep koolshare)
	if [ -d "/koolshare" ];then
		if [ -n "${KS_TAG}" ];then
			FW_TYPE_CODE="2"
			FW_TYPE_NAME="koolshare官改固件"
		else
			FW_TYPE_CODE="4"
			FW_TYPE_NAME="koolshare梅林改版固件"
		fi
	else
		if [ "$(uname -o|grep Merlin)" ];then
			FW_TYPE_CODE="3"
			FW_TYPE_NAME="梅林原版固件"
		else
			FW_TYPE_CODE="1"
			FW_TYPE_NAME="华硕官方固件"
		fi
	fi
}


platform_test() {
  local LINUX_VER=$(uname -r | awk -F"." '{print $1$2}')
  if [ -d "/koolshare" -a -f "/usr/bin/skipd" -a "${LINUX_VER}" -eq "26" ] || [ -d "/koolshare" -a -f "/usr/bin/skipd" -a "${LINUX_VER}" -ge "41" ]; then
    echo_date "机型：${MODEL} ${FW_TYPE_NAME} 符合安装要求，开始安装插件！"
  else
    exit_install 1
  fi
}

get_ui_type(){
	UI_TYPE=ASUSWRT
	ROG_FLAG=$(grep -o "680516" /www/form_style.css|head -n1)
	TUF_FLAG=$(grep -o "D0982C" /www/form_style.css|head -n1)
	if [ -n "${ROG_FLAG}" ];then
		UI_TYPE="ROG"
	fi
	if [ -n "${TUF_FLAG}" ];then
		UI_TYPE="TUF"
	fi
}

exit_install() {
  local state=$1
  case $state in
  1)
    echo_date "本插件适用于【koolshare merlin armv7l 384/386】和【koolshare 梅林改/官改 hnd/axhnd/axhnd.675x】固件平台！"
    echo_date "你的固件平台不能安装！！!"
    echo_date "本插件支持机型/平台1：https://github.com/koolshare/armsoft#armsoft"
    echo_date "本插件支持机型/平台2：https://github.com/koolshare/rogsoft#rogsoft"
    echo_date "退出安装！"
    rm -rf /tmp/${module}* >/dev/null 2>&1
    exit 1
    ;;
  0 | *)
    rm -rf /tmp/${module}* >/dev/null 2>&1
    exit 0
    ;;
  esac
}

install_ui() {
  # intall different UI
  get_ui_type
  if [ "${UI_TYPE}" == "ROG" ]; then
    echo_date "安装ROG皮肤！"
    sed -i '/asuscss/d' /koolshare/webs/Module_${module}.asp >/dev/null 2>&1
  fi
  if [ "${UI_TYPE}" == "TUF" ]; then
    echo_date "安装TUF皮肤！"
    sed -i '/asuscss/d' /koolshare/webs/Module_${module}.asp >/dev/null 2>&1
    sed -i 's/3e030d/3e2902/g;s/91071f/92650F/g;s/680516/D0982C/g;s/cf0a2c/c58813/g;s/700618/74500b/g;s/530412/92650F/g' /koolshare/webs/Module_${module}.asp >/dev/null 2>&1
  fi
  if [ "${UI_TYPE}" == "ASUSWRT" ]; then
    echo_date "安装ASUSWRT皮肤！"
    sed -i '/rogcss/d' /koolshare/webs/Module_${module}.asp >/dev/null 2>&1
  fi
}

install_now() {
  # default value
  local TITLE="Alist文件列表"
  local DESCR="一款支持多种存储的目录文件列表程序，支持 web 浏览与 webdav，后端基于gin，前端使用react。"
  local PLVER=$(cat ${DIR}/version)

  # isntall file
  echo_date "安装插件相关文件..."
	# 检查jq是否安装
  echo_date "检查是否安装jq..."
	if [ ! -x "/koolshare/bin/jq" ]; then
  		echo_date "未安装，正在安装jq..."
  		cp -f /tmp/${module}/bin/jq /koolshare/bin/
  		echo_date "jq安装完成..."
  else
      echo_date "jq已安装，跳过..."
  fi
  #赋权
  chmod +x /koolshare/bin/jq >/dev/null 2>&1
  # 复制文件到目录
  cd /tmp || exit
  cp -rf /tmp/${module}/res/* /koolshare/res/
  cp -rf /tmp/${module}/scripts/* /koolshare/scripts/
  cp -rf /tmp/${module}/webs/* /koolshare/webs/
  cp -f /tmp/${module}/bin/alist /koolshare/bin/
  cp -rf /tmp/${module}/uninstall.sh /koolshare/scripts/uninstall_${module}.sh
  mkdir -p /koolshare/alist/
  cp -rf /tmp/${module}/alist/* /koolshare/alist/
  #创建开机自启任务
	[ ! -L "/koolshare/init.d/S99alist.sh" ] && ln -sf /koolshare/scripts/alist_config.sh /koolshare/init.d/S99alist.sh

  # Permissions
  chmod 755 /koolshare/${module}/* >/dev/null 2>&1
  chmod 755 /koolshare/scripts/* >/dev/null 2>&1
  chmod +x /koolshare/bin/alist >/dev/null 2>&1

  # dbus value
  echo_date "设置插件默认参数..."
  dbus set ${module}_version="${PLVER}"
  dbus set softcenter_module_${module}_version="${PLVER}"
  dbus set softcenter_module_${module}_install="1"
  dbus set softcenter_module_${module}_name="${module}"
  dbus set softcenter_module_${module}_title="${TITLE}"
  dbus set softcenter_module_${module}_description="${DESCR}"
  #default value
  dbus set ${module}_port="5244"
  dbus set ${module}_assets='https://npm.elemecdn.com/alist-web@$version/dist'
  dbus set ${module}_cache_time="60"
  dbus set ${module}_cache_cleaup="120"
  dbus set ${module}_https="0"
  dbus set ${module}_cert_file=""
  dbus set ${module}_key_file=""
  dbus set ${module}_publicswitch="0"
  dbus set ${module}_enable="0"

  # intall different UI
  install_ui

  # finish
  echo_date "${TITLE}插件安装完毕！"
  exit_install
}

install() {
  get_model
  get_fw_type
  platform_test
  install_now
}

install
