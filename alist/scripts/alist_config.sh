#!/bin/sh

source /koolshare/scripts/base.sh
# shellcheck disable=SC2046
eval $(dbus export alist_)

alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
alistBaseDir="/koolshare/alist/"
configJson=${alistBaseDir}config.json
configPort=5244                                                 #监听端口
configAssets=$(dbus get alist_assets)                           #资源文件地址
configCacheTime=60                                              #缓存时间 单位分钟
configCacheCleaup=120                                           #清理失效缓存间隔
configHttps=false                                               #是否开启https
configCertFile=''                                               #https证书cert文件路径
configKeyFile=''                                                #https证书key文件路径

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
  #初始化缓存清除时间
  # shellcheck disable=SC2154
  if [ "${configAssets}Z" == "Z" ]; then
    configAssets='https://npm.elemecdn.com/alist-web@$version/dist'
    dbus set alist_assets='https://npm.elemecdn.com/alist-web@$version/dist'
  fi
  #初始化https
  # shellcheck disable=SC2154
  if [ "${alist_https}" -eq "1" ] && [ "${alist_cert_file}Z" != "Z" ] && [ "${alist_key_file}Z" != "Z" ]; then
    configHttps=true
    configCertFile=$alist_cert_file
    configKeyFile=$alist_key_file
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
  initData
  #先停止
  stop
  #检查是否开启公网转发
  public_access
  #启动进程
  /koolshare/bin/alist -conf ${configJson} // >/dev/null 2>&1 &
  dbus set alist_enable="1"
}

stop() {
  killall alist >/dev/null 2>&1
  public_access stop
  dbus set alist_enable="0"
}

public_access() {
  if [ "$alist_publicswitch" == "0" ] || [ "$1" == "stop" ]; then
    iptables -D INPUT -p tcp --dport ${alist_port} -j ACCEPT
  else
    iptables -I INPUT -p tcp --dport ${alist_port} -j ACCEPT
  fi
}

case $1 in
start)
  if [ "$alist_enable" == "1" ]; then
    start
  fi
  ;;

*) #web提交
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
    port=5244
    if [ "$alist_pid" -gt 0 ]; then
      text="<span style='color: gold'>运行中</span>"
      pwd=$(/koolshare/bin/alist -conf ${configJson} -password)
    fi
    http_response "$text@$pwd@$port"
    exit
  fi
  http_response $1
  ;;
esac
