#!/bin/sh
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'

echo_date "插件自带脚本开始运行..."
echo_date "正在删除插件资源文件..."
rm -rf /koolshare/alist
rm -rf /koolshare/scripts/alist_config.sh
rm -rf /koolshare/webs/Module_alist.asp
rm -rf /koolshare/res/*alist*
rm -rf /koolshare/init.d/*alist.sh
rm -rf /koolshare/bin/alist >/dev/null 2>&1
sed -i '/alist_watchdog/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
echo_date "插件资源文件删除成功..."

rm -rf /koolshare/scripts/uninstall_alist.sh
echo_date "已成功移除插件... Bye~Bye~"