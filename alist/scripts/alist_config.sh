#!/bin/sh

source /koolshare/scripts/base.sh
eval $(dbus export alist_)

alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
AlistBaseDir=/koolshare/alist
LOG_FILE=/tmp/upload/alist_log.txt
LOCK_FILE=/var/lock/alist.lock
BASH=${0##*/}
ARGS=$@

set_lock(){
	exec 233>${LOCK_FILE}
	flock -n 233 || {
		# bring back to original log
		http_response "$ACTION"
		exit 1
	}
}

unset_lock(){
	flock -u 233
	rm -rf ${LOCK_FILE}
}

number_test(){
	case $1 in
		''|*[!0-9]*)
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

dbus_rm(){
	# remove key when value exist
	if [ -n "$1" ];then
		dbus remove $1
	fi
}

detect_running_status(){
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

makeConfig() {
	configPort=5244                       #监听端口
	configTokenExpiresIn=48               #登录有效时间 单位小时
	configSiteUrl=                        #清理失效缓存间隔
	configHttps=false                     #是否开启https
	configCertFile=''                     #https证书cert文件路径
	configKeyFile=''                      #https证书key文件路径

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
							echo_date "⚠️证书公钥Cert文件未配置！"
							dbus set alist_cert_error=1
						fi
						if [ -z "${KEY_VERFY}" ]; then
							echo_date "⚠️证书私钥Key文件未配置！"
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
					echo_date "⚠️证书公钥Cert文件未配置！"
					dbus set alist_cert_error=1
				fi
				if [ -z "${alist_key_file}" ]; then
					echo_date "⚠️证书私钥Key文件未配置！"
					dbus set alist_key_error=1
				fi
			fi
		fi
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
						local MATCH_5=$(echo "${alist_site_url}" | grep -Eo ":${configPort}$")
						if [ -z "${MATCH_5}" ]; then
							echo_date "⚠️网站URL：${alist_site_url} 端口配置错误！"
							echo_date "⚠️你需要为网站URL配置端口:${configPort}，不然会导致面alist部分功能出现问题！"
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
	local LANADDR=$(ifconfig br0|grep -Eo "inet addr.+"|awk -F ":| " '{print $3}' 2>/dev/null)
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
			"address":"'${BINDADDR}'",
			"port":'${configPort}',
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
					"db_file":"/koolshare/alist/data.db",
					"table_prefix":"x_",
					"ssl_mode":""
				},
			"scheme":
				{
					"https":'${configHttps}',
					"cert_file":"'${configCertFile}'",
					"key_file":"'${configKeyFile}'"
				},
			"temp_dir":"/koolshare/alist/temp",
			"log":
				{
					"enable":false,
					"name":"/koolshare/alist/alist.log",
					"max_size":10,
					"max_backups":5,
					"max_age":28,
					"compress":false
				}
			}'
	echo "${config}" >${AlistBaseDir}/config.json
}

#检查内存是否合规
check_memory(){
	local swap_size=$(free | grep Swap | awk '{print $2}');
	echo_date "ℹ️检查系统内存是否合规！"
	if [ "$swap_size" != "0" ];then
		echo_date "✅️当前系统已经启用虚拟内存！容量：${swap_size}KB"
	else
		local memory_size=$(free | grep Mem | awk '{print $2}');
		if [ "$memory_size" != "0" ];then
			if [  $memory_size -le 750000 ];then
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
}

start_process(){
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

	# 2. check_memory
	check_memory

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
	if [ "${alist_publicswitch}" == "1" ];then
		open_port 
	fi
}

stop_process(){
	local ALIST_PID=$(pidof alist)
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
	if [ -z "${CM}" -a -f "/lib/modules/${OS}/kernel/net/netfilter/xt_comment.ko" ];then
		echo_date "ℹ️加载xt_comment.ko内核模块！"
		insmod /lib/modules/${OS}/kernel/net/netfilter/xt_comment.ko
	fi
	
	local MATCH=$(iptables -t filter -S INPUT | grep "alist_rule")
	if [ -z "${MATCH}" ];then
		echo_date "🧱添加防火墙入站规则，打开alist端口：${configPort}"
		iptables -I INPUT -p tcp --dport ${configPort} -j ACCEPT -m comment --comment "alist_rule" >/dev/null 2>&1
	fi
}

close_port(){
	local IPTS=$(iptables -t filter -S | grep -w "alist_rule" | sed 's/-A/iptables -t filter -D/g')
	if [ -n "${IPTS}" ];then
		echo_date "🧱关闭本插件在防火墙上打开的所有端口!"
		iptables -t filter -S | grep -w "alist_rule" | sed 's/-A/iptables -t filter -D/g' > /tmp/clean.sh
		chmod +x /tmp/clean.sh
		sh /tmp/clean.sh > /dev/null 2>&1
		rm /tmp/clean.sh
	fi
}

show_password(){
	# 1. 关闭server进程
	# echo_date "查看密码前需要先关闭alist服务器主进程..."
	# stop_process

	# 2. 查询密码
	echo_date "🔍查询alist面板的用户和密码..."
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
	else
		echo_date "⚠️面板账号密码获取失败！请重启路由后重试！"
	fi

	# 3. 重启进程
	# start_process
}

check_status(){
	local ALIST_PID=$(pidof alist)
	if [ "${alist_enable}" == "1" ]; then
		if [ -n "${ALIST_PID}" ]; then
			if [ "${alist_watchdog}" == "1" ]; then
				local alist_time=$(perpls|grep alist|grep -Eo "uptime.+-s\ " | awk -F" |:|/" '{print $3}')
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
		start | tee -a ${LOG_FILE}
		logger "[软件中心-开机自启]: Alist自启动成功！"
	else
		logger "[软件中心-开机自启]: Alist未开启，不自动启动！"
	fi
	;;
start_nat)
	alist_pid=$(pidof alist)
	if [ "${alist_enable}" == "1" ]; then
		logger "[软件中心-NAT重启]: 打开alist防火墙端口！"
		close_port
		open_port
	fi
	;;
stop)
	stop_plugin
	;;
esac

case $2 in
web_submit)
	set_lock
	true > ${LOG_FILE}
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
		show_password | tee -a ${LOG_FILE}
	else
		echo_date "ℹ️停止alist！" | tee -a ${LOG_FILE}
		stop_plugin | tee -a ${LOG_FILE}
	fi
	echo XU6J03M6 | tee -a ${LOG_FILE}
	unset_lock
	;;
status)
	check_status
	;;
esac
