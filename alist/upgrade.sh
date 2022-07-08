#!/bin/sh

source /koolshare/scripts/base.sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
LOGFILE="/tmp/upload/alist_log.txt"
MODEL=
UI_TYPE=ASUSWRT
FW_TYPE_CODE=
FW_TYPE_NAME=


get_fw_type() {
  local KS_TAG=$(nvram get extendno | grep koolshare)
  if [ -d "/koolshare" ]; then
    if [ -n "${KS_TAG}" ]; then
      FW_TYPE_CODE="2"
      FW_TYPE_NAME="koolshare官改固件"
    else
      FW_TYPE_CODE="4"
      FW_TYPE_NAME="koolshare梅林改版固件"
    fi
  else
    if [ "$(uname -o | grep Merlin)" ]; then
      FW_TYPE_CODE="3"
      FW_TYPE_NAME="梅林原版固件"
    else
      FW_TYPE_CODE="1"
      FW_TYPE_NAME="华硕官方固件"
    fi
  fi
}

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

install_ui() {
  # intall different UI
  get_ui_type
  if [ "${UI_TYPE}" == "ROG" ]; then
    echo_date "安装ROG皮肤！">>$LOGFILE
    sed -i '/asuscss/d' /koolshare/webs/Module_alist.asp >/dev/null 2>&1
  fi
  if [ "${UI_TYPE}" == "TUF" ]; then
    echo_date "安装TUF皮肤！">>$LOGFILE
    sed -i '/asuscss/d' /koolshare/webs/Module_alist.asp >/dev/null 2>&1
    sed -i 's/3e030d/3e2902/g;s/91071f/92650F/g;s/680516/D0982C/g;s/cf0a2c/c58813/g;s/700618/74500b/g;s/530412/92650F/g' /koolshare/webs/Module_alist.asp >/dev/null 2>&1
  fi
  if [ "${UI_TYPE}" == "ASUSWRT" ]; then
    echo_date "安装ASUSWRT皮肤！">>$LOGFILE
    sed -i '/rogcss/d' /koolshare/webs/Module_alist.asp >/dev/null 2>&1
  fi
}

install_now() {
  local tmpDir="/tmp/upload/alist_upgrade/"
  local new_version=$(cat ${tmpDir}"alist/version")
  echo_date "停止运行插件,开始处理旧文件..." >>$LOGFILE
  is_enable=$(dbus get alist_enable)
  sh /koolshare/scripts/alist_config.sh update stop >/dev/null 2>&1
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
  #安装皮肤
  install_ui
  if [ "${is_enable}" == "1" ]; then
    echo_date "重新启用插件中..." >>$LOGFILE
    /bin/sh /koolshare/scripts/alist_config.sh update start >/dev/null 2>&1
    echo_date "插件启用成功..." >>$LOGFILE
  else
    /bin/sh /koolshare/scripts/alist_config.sh update stop >/dev/null 2>&1
  fi
  sleep 1
  rm -rf $tmpDir >/dev/null 2>&1
}

install() {
  get_model
  get_fw_type
  install_now
}

install
