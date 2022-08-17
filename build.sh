#!/bin/sh
if [ $1 ];then
    echo "版本号有更新,修改版本信息"
    old_version=$(cat alist/version)
    # shellcheck disable=SC2046
    if [ $(expr "$1" \> "$old_version") -eq 1 ];then
        echo "$1" > alist/version
        echo "更新版本至: v${1}"
#        update_version=1
      else
        echo "输入版本号小于当前版本号,不予修改"
    fi
  else
    echo "无版本更新"
fi
echo ""

rm -f alist.tar.gz
tar czvf alist.tar.gz alist/ > /dev/null 2>&1
echo "安装包打包成功..."

# shellcheck disable=SC2002
oldMd5=$(cat version_info | grep -o -E "\"md5[a-z]{3}\":\"[a-z0-9]{32}\"" | awk -F ":" '{print $2}'| sed 's/\"//g');
buildMd5=$(md5sum alist.tar.gz | awk '{print $1}');
buildBinMd5=$(md5sum alist/bin/alist | awk '{print $1}');

echo "校验新旧文件md5"
if [ "$oldMd5" = "$buildMd5" ];then
    echo "新旧文件md5一致,不修改发布信息"
  else
    echo "新旧文件md5不一致,发布版本信息"
    #替换版本信息中的MD5
    sed -i 's/"md5sum":".\{32\}"/"md5sum":"'"${buildMd5}"'"/g' version_info
    echo "修改version_info中插件包md5成功"
    echo ""
    #替换二进制md5
    sed -i 's/"bin_md5":".\{32\}"/"bin_md5":"'"${buildBinMd5}"'"/g' version_info
    echo "修改version_info中二进制md5成功"
    echo ""
    if [ $update_version ];then
      echo "打包文件中版本号修改完毕"
      echo "请手动修改version_info版本号并发布版本信息"
      echo "新版本号: ${1}"
    fi
fi