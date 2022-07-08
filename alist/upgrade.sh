#!/bin/sh
# shellcheck disable=SC2039
source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
LOGFILE="/tmp/upload/alist_log.txt"
MODEL=
UI_TYPE=ASUSWRT
FW_TYPE_CODE=
FW_TYPE_NAME=

get_model() {
  # shellcheck disable=SC2155
  local ODMPID=$(nvram get odmpid)
  # shellcheck disable=SC2155
  local PRODUCTID=$(nvram get productid)
  if [ -n "${ODMPID}" ]; then
    MODEL="${ODMPID}"
  else
    MODEL="${PRODUCTID}"
  fi
}

get_ui_type(){
	# default value
	[ "${MODEL}" == "RT-AC86U" ] && local ROG_RTAC86U=0
	[ "${MODEL}" == "GT-AC2900" ] && local ROG_GTAC2900=1
	[ "${MODEL}" == "GT-AC5300" ] && local ROG_GTAC5300=1
	[ "${MODEL}" == "GT-AX11000" ] && local ROG_GTAX11000=1
	[ "${MODEL}" == "GT-AXE11000" ] && local ROG_GTAXE11000=1
	[ "${MODEL}" == "GT-AX6000" ] && local ROG_GTAX6000=1
	local KS_TAG=$(nvram get extendno|grep koolshare)
	local EXT_NU=$(nvram get extendno)
	local EXT_NU=$(echo ${EXT_NU%_*} | grep -Eo "^[0-9]{1,10}$")
	local BUILDNO=$(nvram get buildno)
	[ -z "${EXT_NU}" ] && EXT_NU="0"
	# RT-AC86U
	if [ -n "${KS_TAG}" -a "${MODEL}" == "RT-AC86U" -a "${EXT_NU}" -lt "81918" -a "${BUILDNO}" != "386" ];then
		# RT-AC86U的官改固件，在384_81918之前的固件都是ROG皮肤，384_81918及其以后的固件（包括386）为ASUSWRT皮肤
		ROG_RTAC86U=1
	fi
	# GT-AC2900
	if [ "${MODEL}" == "GT-AC2900" ] && [ "${FW_TYPE_CODE}" == "3" -o "${FW_TYPE_CODE}" == "4" ];then
		# GT-AC2900从386.1开始已经支持梅林固件，其UI是ASUSWRT
		ROG_GTAC2900=0
	fi
	# GT-AX11000
	if [ "${MODEL}" == "GT-AX11000" -o "${MODEL}" == "GT-AX11000_BO4" ] && [ "${FW_TYPE_CODE}" == "3" -o "${FW_TYPE_CODE}" == "4" ];then
		# GT-AX11000从386.2开始已经支持梅林固件，其UI是ASUSWRT
		ROG_GTAX11000=0
	fi
	# GT-AXE11000
	if [ "${MODEL}" == "GT-AXE11000" ] && [ "${FW_TYPE_CODE}" == "3" -o "${FW_TYPE_CODE}" == "4" ];then
		# GT-AXE11000从386.5开始已经支持梅林固件，其UI是ASUSWRT
		ROG_GTAXE11000=0
	fi
	# ROG UI
	if [ "${ROG_GTAC5300}" == "1" -o "${ROG_RTAC86U}" == "1" -o "${ROG_GTAC2900}" == "1" -o "${ROG_GTAX11000}" == "1" -o "${ROG_GTAXE11000}" == "1" -o "${ROG_GTAX6000}" == "1" ];then
		# GT-AC5300、RT-AC86U部分版本、GT-AC2900部分版本、GT-AX11000部分版本、GT-AXE11000官改版本， GT-AX6000 骚红皮肤
		UI_TYPE="ROG"
	fi
	# TUF UI
	if [ "${MODEL}" == "TUF-AX3000" ];then
		# 官改固件，橙色皮肤
		UI_TYPE="TUF"
	fi
}

install_ui() {
  # intall different UI
  get_ui_type
  if [ "${UI_TYPE}" == "ROG" ]; then
    echo_date "安装ROG皮肤！"
    sed -i '/asuscss/d' /koolshare/webs/Module_alist.asp >/dev/null 2>&1
  fi
  if [ "${UI_TYPE}" == "TUF" ]; then
    echo_date "安装TUF皮肤！"
    sed -i '/asuscss/d' /koolshare/webs/Module_alist.asp >/dev/null 2>&1
    sed -i 's/3e030d/3e2902/g;s/91071f/92650F/g;s/680516/D0982C/g;s/cf0a2c/c58813/g;s/700618/74500b/g;s/530412/92650F/g' /koolshare/webs/Module_alist.asp >/dev/null 2>&1
  fi
  if [ "${UI_TYPE}" == "ASUSWRT" ]; then
    echo_date "安装ASUSWRT皮肤！"
    sed -i '/rogcss/d' /koolshare/webs/Module_alist.asp >/dev/null 2>&1
  fi
}

install_now() {
  local tmpDir="/tmp/upload/alist_upgrade/"
  local new_version=$(cat ${tmpDir}"alist/version")
  echo_date "停止运行插件,开始处理旧文件..." >>$LOGFILE
  sh /koolshare/scripts/alist_config.sh stop >/dev/null 2>&1
  rm -rf /koolshare/scripts/alist_config.sh
  rm -rf /koolshare/webs/Module_alist.asp
  rm -rf /koolshare/res/*alist*
  rm -rf /koolshare/init.d/*alist.sh
  sleep 1
  # 检查jq是否安装
  echo_date "检查是否安装jq..." >>$LOGFILE
  if [ ! -x "/koolshare/bin/jq" ]; then
    echo_date "未安装，正在安装jq..." >>$LOGFILE
    cp -f ${tmpDir}/bin/jq /koolshare/bin/
    echo_date "jq安装完成..." >>$LOGFILE
  else
    echo_date "jq已安装，跳过..." >>$LOGFILE
  fi
  #jq赋权
  chmod +x /koolshare/bin/jq >/dev/null 2>&1
  echo_date "开始替换最新文件..." >>$LOGFILE
  cp -f ${tmpDir}alist/bin/alist /koolshare/bin/
  chmod 755 /koolshare/bin/alist >/dev/null 2>&1
  cp -rf ${tmpDir}alist/res/* /koolshare/res/
  cp -rf ${tmpDir}alist/scripts/* /koolshare/scripts/
  chmod 755 /koolshare/scripts/alist_config.sh >/dev/null 2>&1
  cp -rf ${tmpDir}alist/webs/* /koolshare/webs/
  cp -rf ${tmpDir}alist/uninstall.sh /koolshare/scripts/uninstall_alist.sh
  # shellcheck disable=SC2154
  #写入开机自启动
  if [ ! -L "/koolshare/init.d/S99alist.sh" ]; then
    # shellcheck disable=SC2086
    ln -sf /koolshare/scripts/alist_config.sh /koolshare/init.d/S99alist.sh
  fi
  echo_date "插件更新成功..." >>$LOGFILE
  sleep 1
  echo_date "开始写入新版本号:${new_version}..." >>$LOGFILE
  dbus set softcenter_module_alist_version="${new_version}"
  sleep 1
  echo_date "版本号写入完成" >>$LOGFILE
  sleep 1
  is_enable=$(dbus get alist_enable)
  if [ "${is_enable}" == "1" ]; then
    echo_date "插件重新启用插件中..." >>$LOGFILE
    /bin/sh /koolshare/scripts/alist.sh start >/dev/null 2>&1
    echo_date "插件启用成功..." >>$LOGFILE
  else
    echo_date "插件未启用..." >>$LOGFILE
  fi
  sleep 1
  rm -rf $tmpDir >/dev/null 2>&1
}

install() {
  get_model
  install_now
  get_ui_type
  install_ui
}

install
