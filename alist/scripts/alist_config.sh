#!/bin/sh

source /koolshare/scripts/base.sh
# shellcheck disable=SC2046
eval $(dbus export alist_)

alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
alistBaseDir="/koolshare/alist/"
configJson=${alistBaseDir}config.json
alistVersion=${alistBaseDir}alist.version
configPort=5244                       #监听端口
configAssets=$(dbus get alist_assets) #资源文件地址
configCacheTime=60                    #缓存时间 单位分钟
configCacheCleaup=120                 #清理失效缓存间隔
configHttps=false                     #是否开启https
configCertFile=''                     #https证书cert文件路径
configKeyFile=''                      #https证书key文件路径
LOGFILE="/tmp/upload/alist_log.txt"

initData() {
  #初始化端口
  # shellcheck disable=SC2154
  if [ "${alist_port}Z" != "Z" ]; then
    configPort=$alist_port
  fi
  #初始化缓存时间
  # shellcheck disable=SC2154
  if [ "${alist_cache_time}Z" != "Z" ]; then
    configCacheTime=$alist_cache_time
  fi
  #初始化缓存清除时间
  # shellcheck disable=SC2154
  if [ "${alist_cache_cleaup}Z" != "Z" ]; then
    configCacheCleaup=$alist_cache_cleaup
  fi
  #初始化静态资源位置
  # shellcheck disable=SC2154
  if [ "${configAssets}Z" == "Z" ]; then
    configAssets='/'
    dbus set alist_assets='/'
  else
    #检测是否为饿了么CDN如果为饿了么CDN则强行替换成本地静态资源
    if [ $(echo $configAssets | grep "https://npm.elemecdn.com")Z != "Z" ]; then
      configAssets='/'
      dbus set alist_assets='/'
    fi
  fi
  #初始化https
  # shellcheck disable=SC2154
  if [ "${alist_https}" -eq "1" ] && [ "${alist_cert_file}Z" != "Z" ] && [ "${alist_key_file}Z" != "Z" ]; then
    configHttps=true
    configCertFile=$alist_cert_file
    configKeyFile=$alist_key_file
  fi
  #优化版本获取速度
  if [ ! -f $alistVersion ] || [ $(cat $alistVersion)x == "x" ]; then
    /koolshare/bin/alist -version >$alistVersion
  fi
  auto_start
  makeConfig
}

makeConfig() {
  config='{"force":false,"address":"0.0.0.0","port":'${configPort}',"assets":"'${configAssets}'","database":{"type":"sqlite3","host":"","port":0,"user":"","password":"","name":"","db_file":"/koolshare/alist/data.db","table_prefix":"x_","ssl_mode":""},"scheme":{"https":'${configHttps}',"cert_file":"'${configCertFile}'","key_file":"'${configKeyFile}'"},"cache":{"expiration":'${configCacheTime}',"cleanup_interval":'${configCacheCleaup}'},"temp_dir":"/koolshare/alist/temp"}'
  echo "$config" >$configJson
}

auto_start() {
  #echo "创建开机重启任务"
  [ ! -L "/koolshare/init.d/S99alist.sh" ] && ln -sf /koolshare/scripts/alist_config.sh /koolshare/init.d/S99alist.sh
}

start() {
  #先停止
  stop
  #检查是否开启公网转发
  public_access
  #启动进程
  /koolshare/bin/alist -conf ${configJson} // >/dev/null 2>&1 &
  dbus set alist_enable="1"
  #检查看门狗
  watchDog
}

stop() {
  killall alist >/dev/null 2>&1
  public_access stop
  dbus set alist_enable="0"
}

public_access() {
  checkiptables=$(iptables -L | grep "${alist_port}")
  if [ "$alist_publicswitch" == "0" ] || [ "$1" == "stop" ]; then
    #检查IPtables是否写入，如果未写入就不删除
    if [ "$checkiptables"x != "x" ]; then
      iptables -D INPUT -p tcp --dport ${alist_port} -j ACCEPT
    fi
  else
    #检查IPtables是否写入，如果已写入就不重复写入
    if [ "$checkiptables"x == "x" ]; then
      iptables -I INPUT -p tcp --dport ${alist_port} -j ACCEPT
    fi
  fi
}

watchDog() {
  if [ "$alist_watchdog" == "1" ] && [ "$alist_enable" == "1" ]; then
    sed -i '/alist_watchdog/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
    cru a alist_watchdog "*/${alist_watchdog_time} * * * * /bin/sh /koolshare/scripts/alist_config.sh check"
  else
    sed -i '/alist_watchdog/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
  fi
}

self_upgrade() {
  local timestamps=$(date +%s)
  local tmpDir="/tmp/upload/alist_upgrade/"
  #  versionapi="https://ghproxy.com/https://raw.githubusercontent.com/everstu/Koolcenter_alist/master/version_info?_="${timestamps}
  versionapi="https://ghproxy.com/https://raw.githubusercontent.com/everstu/Koolcenter_alist/master/version_info"
  versionapi_1="https://raw.githubusercontents.com/everstu/Koolcenter_alist/master/version_info"
  if [ "${1}" == "yes" ]; then
    echo_date "获取最新版本中..." >>$LOGFILE
  else
    echo_date "检查版本更新中..." >>$LOGFILE
  fi

  #通过接口获取新版本信息
  version_info=$(curl -s -m 10 "$versionapi")
  #如果通过第一个获取不到，则尝试通过第二个CDN获取信息
  if [ "${version_info}x" == "x" ]; then
    echo_date "获取失败，正在尝试从备选地址获取..." >>$LOGFILE
    version_info=$(curl -s -m 10 "$versionapi_1")
  fi
  new_version=$(echo "${version_info}" | jq .version)
  old_version=$(dbus get "softcenter_module_alist_version")
  #比较版本信息 如果新版本大于当前安装版本或强制更新则执行更新脚本
  if [ $(expr "$new_version" \> "$old_version") -eq 1 ] || [ "${1}" = "yes" ]; then
    mkdir -p $tmpDir
    if [ "${1}" = "yes" ]; then
      echo_date "开始强制更新,如有更新后有异常,请重新离线安装插件..." >>$LOGFILE
    else
      echo_date "新版本:${new_version}已发布,开始更新..." >>$LOGFILE
    fi
    echo_date "下载资源新版本资源..." >>$LOGFILE
    versionfile=$(echo "${version_info}" | jq .fileurl | sed 's/\"//g')
    versionfile_1=$(echo "${version_info}" | jq .fileurl_1 | sed 's/\"//g')
    #下载新版本安装包 目前是全量更新
    #    downloadUrl=${versionfile}"?_="${timestamps}
    downloadUrl=${versionfile}
    downloadUrl_1=${versionfile_1}
    wget --no-cache -O ${tmpDir}alist.tar.gz "${downloadUrl}"
    #如果通过第一个下载失败，则尝试通过第二个CDN下载文件
    if [ ! -f "${tmpDir}alist.tar.gz" ]; then
      echo_date "下载失败，正在尝试从备选地址下载..." >>$LOGFILE
      wget --no-cache -O ${tmpDir}alist.tar.gz "${downloadUrl_1}"
    fi
    #判断是否下载成功
    if [ -f "${tmpDir}alist.tar.gz" ]; then
      echo_date "新版本下载成功.." >>$LOGFILE
      newFileMd5=$(md5sum ${tmpDir}alist.tar.gz | cut -d ' ' -f1)
      echo_date "文件md5:${newFileMd5}" >>$LOGFILE
      checkMd5=$(echo "${version_info}" | jq .md5sum | sed 's/\"//g')
      echo_date "校验更新文件md5中..." >>$LOGFILE
      #校验MD5是否为打包MD5
      if [ "$newFileMd5" = "$checkMd5" ]; then
        echo_date "文件md5校验通过,开始更新插件..." >>$LOGFILE
        sleep 1
        echo_date "尝试解压安装包..." >>$LOGFILE
        sleep 1
        cd $tmpDir || exit
        #解压到临时文件夹
        tar -zxvf ${tmpDir}alist.tar.gz
        echo_date "安装包解压成功,执行更新脚本..." >>$LOGFILE
        sleep 1
        #升级脚本赋权
        chmod +x "${tmpDir}alist/upgrade.sh" >/dev/null 2>&1
        #执行升级脚本
        start-stop-daemon -S -q -x "${tmpDir}alist/upgrade.sh" 2>&1
        sleep 1
        if [ "$?" != "0" ]; then
          rm -rf $tmpDir >/dev/null 2>&1
          echo_date "更新脚本运行出错,退出更新,请离线更新或稍后再更新..." >>$LOGFILE
        else
          echo_date "更新完成,享受新版本吧~~~" >>$LOGFILE
        fi
      else
        echo_date "文件md5校验失败,退出更新,请离线更新或稍后再更新..." >>$LOGFILE
      fi
    else
      echo_date "新版本资源下载失败,退出更新,请离线更新或稍后再更新..." >>$LOGFILE
    fi
    #删除安装文件
    rm -rf $tmpDir >/dev/null 2>&1
  else
    echo_date "当前版本:v${old_version}是最新版本,无需更新!" >>$LOGFILE
  fi
  echo "ALSTBBACCEED" >>$LOGFILE
}

initData

case $1 in
start) #开机启动
  if [ "$alist_enable" == "1" ]; then
    start
    logger "[软件中心-开机自启]: Alist自启动成功！"
  else
    logger "[软件中心-开机自启]: Alist未开启，不自动启动！"
  fi
  ;;
check) #检查进程
  alist_pid=$(pidof alist)
  if [ "$alist_pid" -gt 0 ]; then
    start
    logger "[软件中心-Alist看门狗]: Alist自启动成功！"
  fi
  ;;
stop)
  stop
  ;;

*) #web提交
  #更新
  if [ "${2}" = "update" ]; then
    echo "" >$LOGFILE
    http_response "$1"
    if [ "${3}" = "1" ]; then
      #强制更新
      self_upgrade "yes"
    else
      self_upgrade "no"
    fi
    exit
  fi
  #启动
  if [ "${2}" = "start" ]; then
    start
  fi
  #关闭
  if [ "${2}" = "stop" ]; then
    stop
  fi
  #状态
  if [ "${2}" = "status" ]; then
    alist_pid=$(pidof alist)
    text="<span style='color: red'>未启用</span>"
    pwd=''
    webVersion=''
    binVersion=''
    port=${configPort}
    if [ "$alist_pid" -gt 0 ]; then
      text="<span style='color: gold'>运行中</span>"
      pwd=$(/koolshare/bin/alist -conf ${configJson} -password)
      binVersion=$(cat $alistVersion | awk '/Version:/{print $2}' | head -n 2 | tail -n 1)
      webVersion=$(cat $alistVersion | awk '/Version:/{print $2}' | tail -n 1)
    fi
    http_response "$text@$pwd@$port@$binVersion@$webVersion"
    exit
  fi
  http_response $1
  ;;
esac
