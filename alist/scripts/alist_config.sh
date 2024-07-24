#!/bin/sh

source /koolshare/scripts/base.sh
eval $(dbus export alist_)
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
AlistBaseDir=/koolshare/alist
LOG_FILE=/tmp/upload/alist_log.txt
LOCK_FILE=/var/lock/alist.lock
configRunPath='/koolshare/alist/' #运行时db等文件存放目录 默认放到/koolshare/目录下
BASH=${0##*/}
ARGS=$@
#初始化配置变量
configPort=5244
configHttpsPort=5245
configTokenExpiresIn=48
cofigMaxConnections=0
configSiteUrl=
configDisableHttp=false
configForceHttps=false
configHttps=false
configCertFile=''
configKeyFile=''
configDelayedStart=0
configCheckSslCert=true

set_lock() {
  exec 233>${LOCK_FILE}
  flock -n 233 || {
    # bring back to original log
    http_response "$ACTION"
    exit 1
  }
}

unset_lock() {
  flock -u 233
  rm -rf ${LOCK_FILE}
}

number_test() {
  case $1 in
  '' | *[!0-9]*)
    echo 1
    ;;
  *)
    echo 0
    ;;
  esac
}

detect_url() {
  local fomart_1=$(echo $1 | grep -E "^https://|^http://")
  local fomart_2=$(echo $1 | grep -E "\.")
  if [ -n "${fomart_1}" -a -n "${fomart_2}" ]; then
    return 0
  else
    return 1
  fi
}

dbus_rm() {
  # remove key when value exist
  if [ -n "$1" ]; then
    dbus remove $1
  fi
}

detect_running_status() {
  local BINNAME=$1
  local PID
  local i=40
  until [ -n "${PID}" ]; do
    usleep 250000
    i=$(($i - 1))
    PID=$(pidof ${BINNAME})
    if [ "$i" -lt 1 ]; then
      echo_date "🔴$1进程启动失败，请检查你的配置！"
      return
    fi
  done
  echo_date "🟢$1启动成功，pid：${PID}"
}

check_usb2jffs_used_status() {
  # 查看当前/jffs的挂载点是什么设备，如/dev/mtdblock9, /dev/sda1；有usb2jffs的时候，/dev/sda1，无usb2jffs的时候，/dev/mtdblock9，出问题未正确挂载的时候，为空
  local cur_patition=$(df -h | /bin/grep /jffs | awk '{print $1}')
  local jffs_device="not mount"
  if [ -n "${cur_patition}" ]; then
    jffs_device=${cur_patition}
  fi
  local mounted_nu=$(mount | /bin/grep "${jffs_device}" | grep -E "/tmp/mnt/|/jffs" | /bin/grep -c "/dev/s")
  if [ "${mounted_nu}" -eq "2" ]; then
    echo "1" #已安装并成功挂载
  else
    echo "0" #未安装或未挂载
  fi
}

write_backup_job() {
  sed -i '/alist_backupdb/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
  echo_date "ℹ️[Tmp目录模式] 创建alist数据库备份任务"
  cru a alist_backupdb "*/1 * * * * /bin/sh /koolshare/scripts/alist_config.sh backup"
}

kill_cron_job() {
  if [ -n "$(cru l | grep alist_backupdb)" ]; then
    echo_date "ℹ️[Tmp目录模式] 删除alist数据库备份任务..."
    sed -i '/alist_backupdb/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
  fi
}

restore_alist_used_db() {
  if [ -f "/tmp/upload/run_alist/data.db" ]; then
    cp -rf /tmp/upload/run_alist/data.db* /koolshare/alist/ >/dev/null 2>&1
    echo_date "➡️[Tmp目录模式] 复制alist数据库至备份目录！"
    rm -rf /tmp/upload/run_alist/
  fi
  kill_cron_job
}

check_run_mode() {
  if [ $(check_usb2jffs_used_status) == "1" ] && [ "${1}" == "start" ]; then
    echo_date "➡️检测到已安装插件usb2jffs并成功挂载，插件可以正常启动！"
    restore_alist_used_db
  fi
}

checkDbFilePath() {
  local ACT=${1}
  check_run_mode ${ACT}
  #检查db运行目录是放在/tmp还是/koolshare
  if [ "${ACT}" = "start" ]; then
    if [ $(check_usb2jffs_used_status) != "1" ]; then #未挂载usb2jffs就检测是否需要运行在/tmp目录
      local LINUX_VER=$(uname -r | awk -F"." '{print $1$2}')
      if [ "$LINUX_VER" = 41 ]; then #内核过低就运行在Tmp目录
        echo_date "⚠️检测到内核版本过低，设置Alist为Tmp目录模式！"
        configRunPath='/tmp/upload/run_alist/'
        echo_date "⚠️安装usb2jffs插件并成功挂载可恢复正常运行模式！"
        echo_date "⚠️[Tmp目录模式] Alist将运行在/tmp目录！"
        mkdir -p /tmp/upload/run_alist/
        if [ ! -f "/tmp/upload/run_alist/data.db" ]; then
          cp -rf /koolshare/alist/data.db* /tmp/upload/run_alist/ >/dev/null 2>&1
          echo_date "➡️[Tmp目录模式] 复制alist数据库至使用目录！"
        fi
        write_backup_job
      fi
    fi
  else
    restore_alist_used_db
  fi
}

makeConfig() {
  echo_date "➡️生成alist配置文件到${AlistBaseDir}/config.json！"

  # 初始化端口
  if [ $(number_test ${alist_port}) != "0" ]; then
    dbus set alist_port=${configPort}
  else
    configPort=${alist_port}
  fi

  #初始化缓存清除时间
  if [ $(number_test ${alist_token_expires_in}) != "0" ]; then
    dbus set alist_token_expires_in=${configTokenExpiresIn}
  else
    configTokenExpiresIn=${alist_token_expires_in}
  fi

  #初始化最大并发连接数
  if [ $(number_test ${alist_max_connections}) != "0" ]; then
    dbus set alist_max_connections=${cofigMaxConnections}
  else
    cofigMaxConnections=${alist_max_connections}
  fi

  #初始化https端口
  if [ $(number_test ${alist_https_port}) != "0" ]; then
    dbus set alist_https_port=${configHttpsPort}
  else
    configHttpsPort=${alist_https_port}
  fi

  #初始化强制跳转https
  if [ $(number_test ${alist_force_https}) != "0" ]; then
    dbus set alist_force_https="0"
  fi

  #初始化强制跳转https
  if [ $(number_test ${alist_force_https}) != "0" ]; then
    dbus set alist_force_https="0"
  fi

  #	#初始化验证SSL证书
  #	if [ "${alist_check_ssl_cert}" == "0" ]; then
  #		configCheckSslCert=false
  #	fi

  #初始化延迟启动时间
  if [ $(number_test ${alist_delayed_start}) != "0" ]; then
    dbus set alist_delayed_start=0
  else
    configDelayedStart=${alist_delayed_start}
  fi

  #检查alist运行DB目录
  checkDbFilePath start

  # 静态资源CDN
  local configCdn=$(dbus get alist_cdn)
  if [ -n "${configCdn}" ]; then
    detect_url ${configCdn}
    if [ "$?" != "0" ]; then
      # 非url，清空后使用/
      echo_date "⚠️CDN格式错误！这将导致面板无法访问！"
      echo_date "⚠️本次插件启动不会将此CDN写入配置，下次请更正，继续..."
      configCdn='/'
      dbus set alist_cdn_error=1
    else
      #检测是否为饿了么CDN如果为饿了么CDN则强行替换成本地静态资源
      local MATCH_1=$(echo ${configCdn} | grep -Eo "npm.elemecdn.com")
      if [ -n "${MATCH_1}" ]; then
        echo_date "⚠️检测到你配置了饿了么CDN，当前饿了么CDN已经失效！这将导致面板无法访问！"
        echo_date "⚠️本次插件启动不会将此CDN写入配置，下次请更正，继续..."
        configCdn='/'
        dbus set alist_cdn_error=1
      fi
    fi
  else
    configCdn='/'
  fi

  # 初始化https，条件：
  # 1. 必须要开启公网访问
  # 2. https开关要打开
  # 3. 证书文件路径和密钥文件路径都不能为空
  # 4. 证书文件和密钥文件要在路由器内找得到
  # 5. 证书文件和密钥文件要是合法的
  # 6. 证书文件和密钥文件还必须得相匹配
  # 7. 继续往下的话就是验证下证书中的域名是否和URL中的域名匹配...算了太麻烦没必要做了
  if [ "${alist_publicswitch}" == "1" ]; then
    # 1. 必须要开启公网访问
    if [ "${alist_https}" == "1" ]; then
      # 2. https开关要打开
      if [ -n "${alist_cert_file}" -a -n "${alist_key_file}" ]; then
        # 3. 证书文件路径和密钥文件路径都不能为空
        if [ -f "${alist_cert_file}" -a -f "${alist_key_file}" ]; then
          # 4. 证书文件和密钥文件要在路由器内找得到
          local CER_VERFY=$(openssl x509 -noout -pubkey -in ${alist_cert_file} 2>/dev/null)
          local KEY_VERFY=$(openssl pkey -pubout -in ${alist_key_file} 2>/dev/null)
          if [ -n "${CER_VERFY}" -a -n "${KEY_VERFY}" ]; then
            # 5. 证书文件和密钥文件要是合法的
            local CER_MD5=$(echo "${CER_VERFY}" | md5sum | awk '{print $1}')
            local KEY_MD5=$(echo "${KEY_VERFY}" | md5sum | awk '{print $1}')
            if [ "${CER_MD5}" == "${KEY_MD5}" ]; then
              # 6. 证书文件和密钥文件还必须得相匹配
              echo_date "🆗证书校验通过！为alist面板启用https..."
              configHttps=true
              configCertFile=${alist_cert_file}
              configKeyFile=${alist_key_file}
            else
              echo_date "⚠️无法启用https，原因如下："
              echo_date "⚠️证书公钥:${alist_cert_file} 和证书私钥: ${alist_key_file}不匹配！"
              dbus set alist_cert_error=1
              dbus set alist_key_error=1
            fi
          else
            echo_date "⚠️无法启用https，原因如下："
            if [ -z "${CER_VERFY}" ]; then
              echo_date "⚠️证书公钥Cert文件错误，检测到这不是公钥文件！"
              dbus set alist_cert_error=1
            fi
            if [ -z "${KEY_VERFY}" ]; then
              echo_date "⚠️证书私钥Key文件错误，检测到这不是私钥文件！"
              dbus set alist_key_error=1
            fi
          fi
        else
          echo_date "⚠️无法启用https，原因如下："
          if [ ! -f "${alist_cert_file}" ]; then
            echo_date "⚠️未找到证书公钥Cert文件！"
            dbus set alist_cert_error=1
          fi
          if [ ! -f "${alist_key_file}" ]; then
            echo_date "⚠️未找到证书私钥Key文件！"
            dbus set alist_key_error=1
          fi
        fi
      else
        echo_date "⚠️无法启用https，原因如下："
        if [ -z "${alist_cert_file}" ]; then
          echo_date "⚠️证书公钥Cert文件路径未配置！"
          dbus set alist_cert_error=1
        fi
        if [ -z "${alist_key_file}" ]; then
          echo_date "⚠️证书私钥Key文件路径未配置！"
          dbus set alist_key_error=1
        fi
      fi
    fi
  fi

  #检查关闭http访问
  if [ "${configHttps}" == "true" ]; then
    if [ "${configHttpsPort}" == "${configPort}" ]; then
      configHttps=false
      configHttpsPort="-1"
      echo_date "⚠️ Alist 管理面板http和https端口相同，本次启动关闭https！"
    else
      if [ "${alist_force_https}" == "1" ]; then
        echo_date "🆗 Alist 管理面板已开启强制跳转https。"
        configForceHttps=true
      fi
    fi
  else
    configHttpsPort="-1"
  fi

  # 网站url只有在开启公网访问后才可用，且未开https的时候，网站url不能配置为https
  # 格式错误的时候，需要清空，以免面板入口用了这个URL导致无法访问
  if [ "${alist_publicswitch}" == "1" ]; then
    if [ -n "${alist_site_url}" ]; then
      detect_url ${alist_site_url}
      if [ "$?" != "0" ]; then
        echo_date "⚠️网站URL：${alist_site_url} 格式错误！"
        echo_date "⚠️本次插件启动不会将此网站URL写入配置，下次请更正，继续..."
        dbus set alist_url_error=1
      else
        local MATCH_2=$(echo "${alist_site_url}" | grep -Eo "ddnsto|kooldns|tocmcc")
        local MATCH_3=$(echo "${alist_site_url}" | grep -Eo "^https://")
        local MATCH_4=$(echo "${alist_site_url}" | grep -Eo "^http://")
        if [ -n "${MATCH_2}" ]; then
          # ddnsto，不能开https
          if [ "${configHttps}" == "true" ]; then
            echo_date "⚠️网站URL：${alist_site_url} 来自ddnsto！"
            echo_date "⚠️你需要关闭alist的https，不然将导致无法访问面板！"
            echo_date "⚠️本次插件启动不会将此网站URL写入配置，下次请更正，继续..."
            dbus set alist_url_error=1
          else
            configSiteUrl=${alist_site_url}
          fi
        else
          # ddns，根据情况判断
          if [ -n "${MATCH_3}" -a "${configHttps}" != "true" ]; then
            echo_date "⚠️网站URL：${alist_site_url} 格式为https！"
            echo_date "⚠️你需要启用alist的https功能，不然会导致面alist部分功能出现问题！"
            echo_date "⚠️本次插件启动不会将此网站URL写入配置，下次请更正，继续..."
            dbus set alist_url_error=1
          elif [ -n "${MATCH_4}" -a "${configHttps}" == "true" ]; then
            echo_date "⚠️网站URL：${alist_site_url} 格式为http！"
            echo_date "⚠️你需要启用alist的https，或者更改网站URL为http协议，不然将导致无法访问面板！"
            echo_date "⚠️本次插件启动不会将此网站URL写入配置，下次请更正，继续..."
            dbus set alist_url_error=1
          else
            # 路由器中使用网站URL的话，还必须配置端口
            if [ -n "${MATCH_3}" ]; then
              local rightPort=$configHttpsPort
              local MATCH_5=$(echo "${alist_site_url}" | grep -Eo ":${configHttpsPort}$")
            else
              local rightPort=$configHttpsPort
              local MATCH_5=$(echo "${alist_site_url}" | grep -Eo ":${configPort}$")
            fi
            if [ -z "${MATCH_5}" ]; then
              echo_date "⚠️网站URL：${alist_site_url} 端口配置错误！"
              echo_date "⚠️你需要为网站URL配置端口:${rightPort}，不然会导致面alist部分功能出现问题！"
              echo_date "⚠️本次插件启动不会将此网站URL写入配置，下次请更正，继续..."
              dbus set alist_url_error=1
            else
              configSiteUrl=${alist_site_url}
            fi
          fi
        fi
      fi
    fi
  else
    local dummy
    # 配置了网站URL，但是没有开启公网访问
    # 只有打开公网访问后配置网站URL才有意义，所以插件将不会启用网站URL...
    # 不过也不需要日志告诉用户，因为插件里关闭公网访问的时候网站URL也被隐藏了的
  fi

  # 公网/内网访问
  local BINDADDR
  local LANADDR=$(ifconfig br0 | grep -Eo "inet addr.+" | awk -F ":| " '{print $3}' 2>/dev/null)
  if [ "${alist_publicswitch}" != "1" ]; then
    if [ -n "${LANADDR}" ]; then
      BINDADDR=${LANADDR}
    else
      BINDADDR="0.0.0.0"
    fi
  else
    BINDADDR="0.0.0.0"
  fi

  config='{
			"force":false,
			"jwt_secret":"random generated",
			"token_expires_in":'${configTokenExpiresIn}',
			"site_url":"'${configSiteUrl}'",
			"cdn":"'${configCdn}'",
			"database":
				{
					"type":"sqlite3",
					"host":"","port":0,
					"user":"",
					"password":"",
					"name":"",
					"db_file":"'${configRunPath}'data.db",
					"table_prefix":"x_",
					"ssl_mode":""
				},
			"scheme":
				{
					"address":"'${BINDADDR}'",
					"http_port":'${configPort}',
					"https_port":'${configHttpsPort}',
					"force_https":'${configForceHttps}',
					"cert_file":"'${configCertFile}'",
					"key_file":"'${configKeyFile}'",
					"unix_file":""
				},
			"temp_dir":"'${configRunPath}'temp",
			"bleve_dir":"'${configRunPath}'bleve",
			"log":
				{
					"enable":false,
					"name":"'${configRunPath}'alist.log",
					"max_size":10,
					"max_backups":5,
					"max_age":28,
					"compress":false
				},
			"delayed_start": '${configDelayedStart}',
			"max_connections":'${cofigMaxConnections}',
			"tls_insecure_skip_verify": '${configCheckSslCert}'
			}'
  echo "${config}" >${AlistBaseDir}/config.json
}

#检查已开启插件
check_enable_plugin() {
  echo_date "ℹ️当前已开启如下插件："
  echo_date "➡️"$(dbus listall | grep 'enable=1' | awk -F '_' '!a[$1]++' | awk -F '_' '{print "dbus get softcenter_module_"$1"_title"|"bash"}' | tr '\n' ',' | sed 's/,$/ /')
}

#检查内存是否合规
check_memory() {
  local swap_size=$(free | grep Swap | awk '{print $2}')
  echo_date "ℹ️检查系统内存是否合规！"
  if [ "$swap_size" != "0" ]; then
    echo_date "✅️当前系统已经启用虚拟内存！容量：${swap_size}KB"
  else
    local memory_size=$(free | grep Mem | awk '{print $2}')
    if [ "$memory_size" != "0" ]; then
      if [ $memory_size -le 750000 ]; then
        echo_date "❌️插件启动异常！"
        echo_date "❌️检测到系统内存为：${memory_size}KB，需挂载虚拟内存！"
        echo_date "❌️Alist程序对路由器开销极大，请挂载1G及以上虚拟内存后重新启动插件！"
        stop_process
        dbus set alist_memory_error=1
        dbus set alist_enable=0
        exit
      else
        echo_date "⚠️Alist程序对路由器开销极大，建议挂载1G及以上虚拟内存，以保证稳定！"
        dbus set alist_memory_warn=1
      fi
    else
      echo_date"⚠️未查询到系统内存，请自行注意系统内存！"
    fi
  fi
  echo_date "=============================================="
}

start_process() {
  ALIST_RUN_LOG=/tmp/upload/alist_run_log.txt
  rm -rf ${ALIST_RUN_LOG}
  if [ "${alist_watchdog}" == "1" ]; then
    echo_date "🟠启动 alist 进程，开启进程实时守护..."
    mkdir -p /koolshare/perp/alist
    cat >/koolshare/perp/alist/rc.main <<-EOF
			#!/bin/sh
			source /koolshare/scripts/base.sh
			CMD="/koolshare/bin/alist --data ${AlistBaseDir} server"
			if test \${1} = 'start' ; then
				exec >${ALIST_RUN_LOG} 2>&1
				exec \$CMD
			fi
			exit 0

		EOF
    chmod +x /koolshare/perp/alist/rc.main
    chmod +t /koolshare/perp/alist/
    sync
    perpctl A alist >/dev/null 2>&1
    perpctl u alist >/dev/null 2>&1
    detect_running_status alist
  else
    echo_date "🟠启动 alist 进程..."
    rm -rf /tmp/alist.pid
    start-stop-daemon --start --quiet --make-pidfile --pidfile /tmp/alist.pid --background --startas /bin/bash -- -c "/koolshare/bin/alist --data ${AlistBaseDir} server >${ALIST_RUN_LOG} 2>&1"
    detect_running_status alist
  fi
}

start() {
  # 0. prepare folder if not exist
  mkdir -p ${AlistBaseDir}

  # 1. remove error
  dbus_rm alist_cert_error
  dbus_rm alist_key_error
  dbus_rm alist_url_error
  dbus_rm alist_cdn_error
  dbus_rm alist_memory_error
  dbus_rm alist_memory_warn

  # 2. system_check
  if [ "${alist_disablecheck}" = "1" ]; then
    echo_date "⚠️您已关闭系统检测功能，请自行留意路由器性能！"
    echo_date "⚠️插件对路由器性能的影响请您自行处理！！！"
  else
    echo_date "==================== 系统检测 ===================="
    #2.1 memory_check
    check_memory
    #2.2 enable_plugin
    check_enable_plugin
    echo_date "==================== 系统检测结束 ===================="
  fi

  # 3. stop first
  stop_process

  # 4. gen config.json
  makeConfig

  # 5. 检测首次运行，给出账号密码
  if [ ! -f "${AlistBaseDir}/data.db" ]; then
    echo_date "ℹ️检测到首次启动插件，生成用户和密码..."
    /koolshare/bin/alist --data ${AlistBaseDir} admin >${AlistBaseDir}/admin.account 2>&1
    local USER=$(cat ${AlistBaseDir}/admin.account | grep -E "^username" | awk '{print $2}')
    local PASS=$(cat ${AlistBaseDir}/admin.account | grep -E "^password" | awk '{print $2}')
    if [ -n "${USER}" -a -n "${PASS}" ]; then
      echo_date "---------------------------------"
      echo_date "😛alist面板用户：${USER}"
      echo_date "🔑alist面板密码：${PASS}"
      echo_date "---------------------------------"
      dbus set alist_user=${USER}
      dbus set alist_pass=${PASS}
    fi
  fi

  # 6. gen version info everytime
  /koolshare/bin/alist version >${AlistBaseDir}/alist.version
  local BIN_VER=$(cat ${AlistBaseDir}/alist.version | grep -Ew "^Version" | awk '{print $2}')
  local WEB_VER=$(cat ${AlistBaseDir}/alist.version | grep -Ew "^WebVersion" | awk '{print $2}')
  if [ -n "${BIN_VER}" -a -n "${WEB_VER}" ]; then
    dbus set alist_binver=${BIN_VER}
    dbus set alist_webver=${WEB_VER}
  fi

  # 7. start process
  start_process

  # 8. open port
  if [ "${alist_publicswitch}" == "1" ]; then
    close_port >/dev/null 2>&1
    open_port
  fi
}

stop_process() {
  local ALIST_PID=$(pidof alist)
  checkDbFilePath stop
  if [ -n "${ALIST_PID}" ]; then
    echo_date "⛔关闭alist进程..."
    if [ -f "/koolshare/perp/alist/rc.main" ]; then
      perpctl d alist >/dev/null 2>&1
    fi
    rm -rf /koolshare/perp/alist
    killall alist >/dev/null 2>&1
    kill -9 "${ALIST_PID}" >/dev/null 2>&1
  fi
}

stop_plugin() {
  # 1 stop alist
  stop_process

  # 2. remove log
  rm -rf /tmp/upload/alist_run_log.txt

  # 3. close port
  close_port
}

open_port() {
  local CM=$(lsmod | grep xt_comment)
  local OS=$(uname -r)
  if [ -z "${CM}" -a -f "/lib/modules/${OS}/kernel/net/netfilter/xt_comment.ko" ]; then
    echo_date "ℹ️加载xt_comment.ko内核模块！"
    insmod /lib/modules/${OS}/kernel/net/netfilter/xt_comment.ko
  fi

  if [ $(number_test ${alist_port}) != "0" ]; then
    dbus set alist_port="5244"
  fi

  if [ $(number_test ${alist_https_port}) != "0" ]; then
    dbus set alist_https_port="5245"
  fi

  # 开启IPV4防火墙端口
  local MATCH=$(iptables -t filter -S INPUT | grep "alist_rule")
  if [ -z "${MATCH}" ]; then
    if [ "${configDisableHttp}" != "true" -a "${alist_open_http_port}" == "1" ]; then
      echo_date "🧱添加防火墙入站规则，打开alist http 端口： ${alist_port}"
      iptables -I INPUT -p tcp --dport ${alist_port} -j ACCEPT -m comment --comment "alist_rule" >/dev/null 2>&1
    fi
    if [ "${alist_https}" == "1" -a "${alist_open_https_port}" == "1" ]; then
      echo_date "🧱添加防火墙入站规则，打开 alist https 端口： ${alist_https_port}"
      iptables -I INPUT -p tcp --dport ${alist_https_port} -j ACCEPT -m comment --comment "alist_rule" >/dev/null 2>&1
    fi
  fi
  # 开启IPV6防火墙端口
  local v6tables=$(which ip6tables);
  local MATCH6=$(ip6tables -t filter -S INPUT | grep "alist_rule")
  if [ -z "${MATCH6}" ] && [ -n "${v6tables}" ]; then
    if [ "${configDisableHttp}" != "true" -a "${alist_open_http_port}" == "1" ]; then
      ip6tables -I INPUT -p tcp --dport ${alist_port} -j ACCEPT -m comment --comment "alist_rule" >/dev/null 2>&1
    fi
    if [ "${alist_https}" == "1" -a "${alist_open_https_port}" == "1" ]; then
      ip6tables -I INPUT -p tcp --dport ${alist_https_port} -j ACCEPT -m comment --comment "alist_rule" >/dev/null 2>&1
    fi
  fi

}

close_port() {
  local IPTS=$(iptables -t filter -S | grep -w "alist_rule" | sed 's/-A/iptables -t filter -D/g')
  if [ -n "${IPTS}" ]; then
    echo_date "🧱关闭本插件在防火墙上打开的所有端口!"
    iptables -t filter -S | grep -w "alist_rule" | sed 's/-A/iptables -t filter -D/g' >/tmp/alist_clean.sh
    chmod +x /tmp/alist_clean.sh
    sh /tmp/alist_clean.sh >/dev/null 2>&1
    rm /tmp/alist_clean.sh
  fi
  local v6tables=$(which ip6tables);
  local IPTS6=$(ip6tables -t filter -S | grep -w "alist_rule" | sed 's/-A/ip6tables -t filter -D/g')
  if [ -n "${IPTS6}" ] && [ -n "${v6tables}" ]; then
    ip6tables -t filter -S | grep -w "alist_rule" | sed 's/-A/ip6tables -t filter -D/g' >/tmp/alist_clean.sh
    chmod +x /tmp/alist_clean.sh
    sh /tmp/alist_clean.sh >/dev/null 2>&1
    rm /tmp/alist_clean.sh
  fi
}

start_backup() {
  if [ -d "/koolshare/alist/" ] && [ -d "/tmp/upload/run_alist/" ]; then
    cd /koolshare/alist && ls -l data.db* | awk '{print $9}' >/tmp/alist_db_file_list.tmp
    while read filename; do
      local dbfile_curr="/tmp/upload/run_alist/${filename}"
      local dbfile_save="/koolshare/alist/${filename}"
      if [ -f "${dbfile_curr}" ]; then
        if [ ! -f "${dbfile_save}" ]; then
          cp -rf ${dbpath_tmp} ${dbfile_save}
          logger "[${0##*/}]：备份Alist ${filename} 数据库!"
        else
          local new=$(md5sum ${dbfile_curr} | awk '{print $1}')
          local old=$(md5sum ${dbfile_save} | awk '{print $1}')
          if [ "${new}" != "${old}" ]; then
            cp -rf ${dbfile_curr} ${dbfile_save}
            logger "[${0##*/}]：Aist ${filename} 数据库变化，备份数据库!"
          fi
        fi
      fi
    done </tmp/alist_db_file_list.tmp
    rm -rf /tmp/alist_db_file_list.tmp
  fi
}

random_password() {
  # 1. 重新生成密码
  echo_date "🔍重新生成alist面板的用户和随机密码..."
  /koolshare/bin/alist --data ${AlistBaseDir} admin random > ${AlistBaseDir}/admin.account 2>&1
  local USER=$(cat ${AlistBaseDir}/admin.account | grep "username" | awk '{print $NF}')
  local PASS=$(cat ${AlistBaseDir}/admin.account | grep "password" | awk '{print $NF}')
  if [ -n "${USER}" -a -n "${PASS}" ]; then
    echo_date "---------------------------------"
    echo_date "😛alist面板用户：${USER}"
    echo_date "🔑alist面板密码：${PASS}"
    echo_date "---------------------------------"
    dbus set alist_user=${USER}
    dbus set alist_pass=${PASS}
  else
    echo_date "⚠️面板账号密码获取失败！请重启路由后重试！"
  fi
		#2. 关闭server进程
		echo_date "重启alist进程..."
		stop_process > /dev/null 2>&1

		# 3. 重启进程
		start > /dev/null 2>&1
		echo_date "✅重启成功！"
}

check_status() {
  local ALIST_PID=$(pidof alist)
  if [ "${alist_enable}" == "1" ]; then
    if [ -n "${ALIST_PID}" ]; then
      if [ "${alist_watchdog}" == "1" ]; then
        local alist_time=$(perpls | grep alist | grep -Eo "uptime.+-s\ " | awk -F" |:|/" '{print $3}')
        if [ -n "${alist_time}" ]; then
          http_response "alist 进程运行正常！（PID：${ALIST_PID} , 守护运行时间：${alist_time}）"
        else
          http_response "alist 进程运行正常！（PID：${ALIST_PID}）"
        fi
      else
        http_response "alist 进程运行正常！（PID：${ALIST_PID}）"
      fi
    else
      http_response "alist 进程未运行！"
    fi
  else
    http_response "Alist 插件未启用"
  fi
}

case $1 in
start)
  if [ "${alist_enable}" == "1" ]; then
    sleep 20 #延迟启动等待虚拟内存挂载
    true >${LOG_FILE}
    start | tee -a ${LOG_FILE}
    echo XU6J03M16 >>${LOG_FILE}
    logger "[软件中心-开机自启]: Alist自启动成功！"
  else
    logger "[软件中心-开机自启]: Alist未开启，不自动启动！"
  fi
  ;;
boot_up)
  if [ "${alist_enable}" == "1" ]; then
    true >${LOG_FILE}
    start | tee -a ${LOG_FILE}
    echo XU6J03M16 >>${LOG_FILE}
  fi
  ;;
start_nat)
  if [ "${alist_enable}" == "1" ]; then
    if [ "${alist_publicswitch}" == "1" ]; then
      logger "[软件中心-NAT重启]: 打开alist防火墙端口！"
      sleep 10
      close_port
      sleep 2
      open_port
    else
      logger "[软件中心-NAT重启]: Alist未开启公网访问，不打开湍口！"
    fi
  fi
  ;;
backup)
  start_backup
  ;;
stop)
  stop_plugin
  ;;
esac

case $2 in
web_submit)
  set_lock
  true >${LOG_FILE}
  http_response "$1"
  # 调试
  # echo_date "$BASH $ARGS" | tee -a ${LOG_FILE}
  # echo_date alist_enable=${alist_enable} | tee -a ${LOG_FILE}
  if [ "${alist_enable}" == "1" ]; then
    echo_date "▶️开启alist！" | tee -a ${LOG_FILE}
    start | tee -a ${LOG_FILE}
  elif [ "${alist_enable}" == "2" ]; then
    echo_date "🔁重启alist！" | tee -a ${LOG_FILE}
    dbus set alist_enable=1
    start | tee -a ${LOG_FILE}
  elif [ "${alist_enable}" == "3" ]; then
    dbus set alist_enable=1
    random_password | tee -a ${LOG_FILE}
  else
    echo_date "ℹ️停止alist！" | tee -a ${LOG_FILE}
    stop_plugin | tee -a ${LOG_FILE}
  fi
  echo XU6J03M16 | tee -a ${LOG_FILE}
  unset_lock
  ;;
status)
  check_status
  ;;
esac
