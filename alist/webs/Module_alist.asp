<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="X-UA-Compatible" content="IE=Edge" />
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="-1" />
    <link rel="shortcut icon" href="/res/icon-alist.png" />
    <link rel="icon" href="/res/icon-alist.png" />
    <title>软件中心 - Alist文件列表</title>
    <link rel="stylesheet" type="text/css" href="index_style.css">
    <link rel="stylesheet" type="text/css" href="form_style.css">
    <link rel="stylesheet" type="text/css" href="usp_style.css">
    <link rel="stylesheet" type="text/css" href="css/element.css">
    <link rel="stylesheet" type="text/css" href="/device-map/device-map.css">
    <link rel="stylesheet" type="text/css" href="/js/table/table.css">
    <link rel="stylesheet" type="text/css" href="/res/layer/theme/default/layer.css">
    <link rel="stylesheet" type="text/css" href="/res/softcenter.css">
    <link rel="stylesheet" type="text/css" href="/res/merlinclash.css">
    <script type="text/javascript" src="/state.js"></script>
    <script type="text/javascript" src="/popup.js"></script>
    <script type="text/javascript" src="/help.js"></script>
    <script type="text/javascript" src="/js/jquery.js"></script>
    <script type="text/javascript" src="/general.js"></script>
    <script type="text/javascript" language="JavaScript" src="/js/table/table.js"></script>
    <script type="text/javascript" language="JavaScript" src="/client_function.js"></script>
    <script type="text/javascript" src="/res/mc-menu.js"></script>
    <script type="text/javascript" src="/res/softcenter.js"></script>
    <script type="text/javascript" src="/res/mc-tablednd.js"></script>
    <script type="text/javascript" src="/help.js"></script>
    <script type="text/javascript" src="/switcherplugin/jquery.iphone-switch.js"></script>
    <script type="text/javascript" src="/validator.js"></script>
    <style>
    body .layui-layer-lan .layui-layer-btn0 {border-color:#22ab39; background-color:#22ab39;color:#fff; background:#22ab39}
    body .layui-layer-lan .layui-layer-btn .layui-layer-btn1 {border-color:#1678ff; background-color:#1678ff;color:#fff;}
    body .layui-layer-lan .layui-layer-btn2 {border-color:#FF6600; background-color:#FF6600;color:#fff;}
    body .layui-layer-lan .layui-layer-title {background: #1678ff;}
    body .layui-layer-lan .layui-layer-btn a{margin:8px 8px 0;padding:5px 18px;}
    body .layui-layer-lan .layui-layer-btn {text-align:center}
    .loadingBarBlock{
        width:740px;
    }
    .popup_bar_bg_ks{
        position:fixed;
        margin: auto;
        top: 0;
        left: 0;
        width:100%;
        height:100%;
        z-index:99;
        /*background-color: #444F53;*/
        filter:alpha(opacity=90);  /*IE5、IE5.5、IE6、IE7*/
        background-repeat: repeat;
        visibility:hidden;
        overflow:hidden;
        /*background: url(/images/New_ui/login_bg.png);*/
        background:rgba(68, 79, 83, 0.85) none repeat scroll 0 0 !important;
        background-position: 0 0;
        background-size: cover;
        opacity: .94;
    }
    .show-btn{
        border-radius: 5px 5px 0px 0px;
        font-size:10pt;
        color: #fff;
        padding: 12.5px 3.75px;
        width:13.45601%;
        border: 1px solid #222;
        background: linear-gradient(to bottom, #919fa4 0%, #67767d 100%);
        border: 1px solid #91071f; /* W3C rogcss*/
        background: none; /* W3C rogcss*/
    }
    .active {
        background: linear-gradient(to bottom, #61b5de 0%, #279fd9 100%);
        border: 1px solid #222;
        background: linear-gradient(to bottom, #cf0a2c 0%, #91071f 100%); /* W3C rogcss*/
        border: 1px solid #91071f; /* W3C rogcss*/
    }
    #log_content1 {
        width:97%;
        padding-left:4px;
        padding-right:37px;
        font-family:'Lucida Console';
        font-size:11px;
        color:#FFFFFF;
        outline:none;
        overflow-x:hidden;
        border:0px solid #222;
        background:#475A5F;
        border:1px solid #91071f; /* W3C rogcss*/
        background:transparent; /* W3C rogcss*/
    }
    </style>
    <script type="text/javascript">
        var refresh_flag
        var has_new_version = false
        var has_new_version_bin = false
        var db_alist = {}
        var changeLog;
        var count_down;
        var ghVersionInfo;

		function E(e) {
			return (typeof(e) == 'string') ? document.getElementById(e) : e;
		}
		function check_status(){
			var id = parseInt(Math.random() * 100000000);
			var postData = {"id": id, "method": "alist_config.sh", "params":['status'], "fields": ""};
			$.ajax({
				type: "POST",
				url: "/_api/",
				async: true,
				data: JSON.stringify(postData),
				success: function (response) {
					var arr = response.result.split("@");
					E("alist_status").innerHTML = arr[0];
					var alistPwd =  arr[1];
					E("alist_pwd").innerHTML = alistPwd ? alistPwd : '<span style="color: red">未启用</span>';
					var alistVersionInfo = '<span style="color: red">未启用</span>'
					if(arr[3] && arr[4])
					{
					    alistVersionInfo = '二进制：' + arr[3] + '<br>网　页：' + arr[4];
					}
					E('alist_version').innerHTML = alistVersionInfo;


					E("fileb").innerHTML = '未启用';
					if(alistPwd)
					{
                        //处理DDNSTO远程管理面板地址
                        var protocol = location.protocol;
                        var hostname = document.domain;
                        if (hostname.indexOf('.kooldns.cn') != -1 || hostname.indexOf('.ddnsto.com') != -1 || hostname.indexOf('.tocmcc.cn') != -1) {
                            if(hostname.indexOf('.kooldns.cn') != -1){
                                hostname = hostname.replace('.kooldns.cn','-alist.kooldns.cn');
                            }else if(hostname.indexOf('.ddnsto.com') != -1){
                                hostname = hostname.replace('.ddnsto.com','-alist.ddnsto.com');
                            }else{
                                hostname = hostname.replace('.tocmcc.cn','-alist.tocmcc.cn');
                            }

                            webUiHref = protocol + "//"+ hostname;
                        }else{
                            webUiHref = protocol + "//"+ location.hostname + ":" + arr[2];
                        }

                        $("#fileb").html("<a type='button' href='" + webUiHref + "' target='_blank' >访问 Alist 面板</a>");
					}
					setTimeout("check_status();", 10000);
				},
				error: function(){
					E("alist_status").innerHTML = "获取运行状态失败";
					setTimeout("check_status();", 5000);
				}
			});
		}

        function start() {
            showLoading(2);
            refreshpage(2);
            var id = parseInt(Math.random() * 100000000);
            makeDbAlist();
            var postData = { "id": id, "method": "alist_config.sh", "params": ["start"], "fields": db_alist };
            $.ajax({
                url: "/_api/",
                cache: false,
                type: "POST",
                dataType: "json",
                data: JSON.stringify(postData)
            });
        }

        function makeDbAlist()
        {
            db_alist['alist_https']            = E("alist_https").checked ? '1' : '0';
            db_alist['alist_cert_file']        = E("alist_cert_file").value;
            db_alist['alist_key_file']         = E("alist_key_file").value;
            db_alist['alist_port']             = E('alist_port').value;
            db_alist['alist_cdn']              = E('alist_cdn').value;
            db_alist['alist_token_expires_in'] = E('alist_token_expires_in').value;
            db_alist['alist_site_url']         = E('alist_site_url').value;
            db_alist['alist_publicswitch']     = E("alist_publicswitch").checked ? '1' : '0';
            db_alist['alist_watchdog']         = E("alist_watchdog").checked ? '1' : '0';
            db_alist['alist_watchdog_time']    = E("alist_watchdog_time").value;
        }

        function close() {
            if (confirm('确定马上关闭吗.?')) {
				showLoading(2);
           		refreshpage(2);
                var id = parseInt(Math.random() * 100000000);
                var postData = { "id": id, "method": "alist_config.sh", "params": ["stop"], "fields": "" };
                $.ajax({
                    url: "/_api/",
                    cache: false,
                    type: "POST",
                    dataType: "json",
                    data: JSON.stringify(postData)
                });
            }
        }

        function get_dbus_data() {
            $.ajax({
                type: "GET",
                url: "/_api/alist",
                dataType: "json",
                async: false,
                success: function (data) {
        	        generate_options();
					db_alist = data.result[0];
                    E("alist_https").checked = db_alist["alist_https"] == "1";
					E("alist_publicswitch").checked = db_alist["alist_publicswitch"] == "1";
					E("alist_watchdog").checked = db_alist["alist_watchdog"] == "1";
					if(db_alist["alist_token_expires_in"]){
						E("alist_token_expires_in").value = db_alist["alist_token_expires_in"];
					}
					if(db_alist["alist_site_url"]){
						E("alist_site_url").value = db_alist["alist_site_url"];
					}
                    if(db_alist["alist_port"]){
						E("alist_port").value = db_alist["alist_port"];
					}
                    if(db_alist["alist_cdn"]){
						E("alist_cdn").value = db_alist["alist_cdn"];
					}
                    if(db_alist["alist_cert_file"]){
						E("alist_cert_file").value = db_alist["alist_cert_file"];
					}
                    if(db_alist["alist_key_file"]){
						E("alist_key_file").value = db_alist["alist_key_file"];
					}
                    if(db_alist["alist_watchdog_time"]){
                        $("#alist_watchdog_time").val(db_alist["alist_watchdog_time"]);
					}
                    if(db_alist['alist_bin_version']){
                        checkBinVersion();
                    }
                }
            });
        }

        //检查二进制版本更新
        function checkBinVersion()
        {
            if(! has_new_version_bin)
            {
                if(! ghVersionInfo)
                {
                    setTimeout('checkBinVersion();', 500);
                }
                else{
                    $('#bin_version_update').html('检查更新中...');
                    if(db_alist['alist_bin_version'])
                    {
                        makeVersionUpdate(db_alist['alist_bin_version'], 'bin');
                    }
                    else
                    {
                        $('#bin_version_update').html('二进制暂无更新');
                        $('#bin_version_update').hide();
                        $('#bin_version_update_1').show();
                    }
                }
            }
            else
            {
                $('#bin_version_update').html('二进制更新中');
                versionUpdate(0,'bin');
            }

            $('#bin_version_update_1').hover(
                function () {
                    $(this).css("color",'#ff3300');
                    $(this).html('强行更新二进制');
                },
                function () {
                    $(this).css("color",'#00ffe4');
                    $(this).html('二进制暂无更新');
                }
            );
        }

        //检查版本更新
        function checkVersion()
        {
            if(! has_new_version)
            {
                if(! ghVersionInfo)
                {
                    setTimeout('checkVersion();', 500);
                }
                else{
                    $('#version_update').html('检查更新中...');
                    $.ajax({
                         type: "GET",
                         url: "/_api/softcenter_module_alist_version",
                         async: true,
                         cache:false,
                         dataType: 'json',
                         success: function(response) {
                             if(response['result'][0]['softcenter_module_alist_version'])
                             {
                                makeVersionUpdate(response['result'][0]['softcenter_module_alist_version']);
                             }
                             else
                             {
                                $('#version_update').html('插件暂无更新');
                                $('#version_update').hide();
                                $('#version_update_1').show();
                             }
                         }
                     });
                }
            }
            else
            {
                $('#version_update').html('插件更新中');
                versionUpdate(0);
            }

            $('#version_update_1').hover(
                function () {
                    $(this).css("color",'#ff3300');
                    $(this).html('强行更新插件');
                },
                function () {
                    $(this).css("color",'#00ffe4');
                    $(this).html('插件暂无更新');
                }
            );
        }

        function makeVersionUpdate(old_version, type = 'plugin')
        {
            if(! ghVersionInfo)
            {
                getGhVersion();
            }
            else
            {
                if(type === 'plugin')
                {
                    if(ghVersionInfo['version'])
                    {
                        var new_version = ghVersionInfo['version'];
                        if(compareVersion(new_version,old_version))
                        {
                          $('#version_update').html('<font color="yellow">有新版本:<font color="red">v' + new_version + '</font>(点击更新)</font>');
                          has_new_version = true;
                        }
                        else
                        {
                          $('#version_update').html('插件暂无更新');
                          $('#version_update').hide();
                          $('#version_update_1').show();
                        }
                    }
                    if(ghVersionInfo['change_log'])
                    {
                        changeLog = ghVersionInfo['change_log'];
                        $('#soft_change_log').click(function(){
                          viewChangelog();
                        });
                    }
                }
                else
                {
                    if(ghVersionInfo['bin_version'])
                    {
                        var new_version = ghVersionInfo['bin_version'];
                        if(compareVersion(new_version, old_version))
                        {
                          $('#bin_version_update').html('<font color="yellow">有新版本:<font color="red">v' + new_version + '</font>(点击更新)</font>');
                          has_new_version = true;
                        }
                        else
                        {
                          $('#bin_version_update').html('二进制暂无更新');
                          $('#bin_version_update').hide();
                          $('#bin_version_update_1').show();
                        }
                    }
                }
            }
        }

        function getGhVersion(source_url)
        {
            if(! ghVersionInfo)
            {
                source_url = source_url ? source_url : 'https://ghproxy.com/https://raw.githubusercontent.com/everstu/Koolcenter_alist/master/version_info';
                $.ajax({
                    type: "GET",
                    url: source_url,
                    async: true,
                    cache: false,
                    dataType: 'json',
                    success: function(response) {
                        ghVersionInfo = response;
                    },
                    error: function(res){
                        var other_url = 'https://raw.githubusercontents.com/everstu/Koolcenter_alist/master/version_info';
                        if(source_url !== other_url)
                        {
                            getGhVersion(other_url);
                        }
                    }
                });
            }
        }

        /**
        * 比较版本号的大小，serverVersion 大于 localVersion，则返回true，否则返回false
        */
        function compareVersion(serverVersion, localVersion) {
            var arr1 = curV.toString().split('.');
            var arr2 = reqV.toString().split('.');
            //将两个版本号拆成数字
            var minL = Math.min(arr1.length, arr2.length);
            var pos = 0; //当前比较位
            var diff = 0; //当前为位比较是否相等
            var flag = false;
            //逐个比较如果当前位相等则继续比较下一位
            while(pos < minL) {
                diff = parseInt(arr1[pos]) - parseInt(arr2[pos]);
                if(diff == 0) {
                    pos++;
                    continue;
                } else if(diff > 0) {
                    flag = true;
                    break;
                } else {
                    flag = false;
                    break;
                }
            }
            return flag;
        }

        //升级版本
        function versionUpdate(act,type = 'plugin')
        {
            require(['/res/layer/layer.js'], function(layer) {
                layer.confirm('在线更新功能需要路由器剩余磁盘空间较大，如在线更新失败您可以删除插件后重新离线安装。', {
                    shade: 0.8,
                }, function(index) {
                    //act 0普通更新 1强制更新
                    var id2 = parseInt(Math.random() * 100000000);
                    var updateType = type === 'plugin' ? 'update' : 'updateBin';
                    var postData = {"id": id2, "method": "alist_config.sh", "params":[updateType, act], "fields": ""};
                    $.ajax({
                        type: "POST",
                        url: "/_api/",
                        async: true,
                        data: JSON.stringify(postData),
                        success: function(response) {
                            if (response.result == id2){
                                E("loading_block_spilt").style.visibility = "visible";
                                get_realtime_log(0);
                            }
                        }
                    });
                    layer.close(index);
                    return true;
                }, function(index) {
                    layer.close(index);
                    return false;
                });
            });
        }

        //查看更新日志
        function viewChangelog()
        {
            if(changeLog)
            {
                var num = 0;
                var logHtml = '';
                E("loading_block_spilt").style.visibility = "hidden";
                E("ok_button").style.visibility = "visible";
                showLoadingBar('插件更新日志');
                var retArea = E("log_content");
                $.each(changeLog,function (k,v){
                    if(num >= 10)
                    {
                        return ;
                    }
                    var note = '';
                    $.each(v.note,function(kk,vv) {
                        note+="- " + vv + "\n";
                    });
                    logHtml += "版本号：v" + v.version + "\n" + "更新内容：\n" + note + "\n\n";
                    num++;
                });
                retArea.value = logHtml;
            }
        }

        //获取更新日志
        function get_realtime_log(flag) {
            E("ok_button").style.visibility = "hidden";
            showLoadingBar();
            $.ajax({
                url: '/_temp/alist_log.txt',
                type: 'GET',
                async: true,
                cache:false,
                dataType: 'text',
                success: function(response) {
                    var retArea = E("log_content");
                    if (response.search("ALSTBBACCEED") != -1) {
                        retArea.value = response.replace("ALSTBBACCEED", "");
                        E("ok_button").style.visibility = "visible";
                        retArea.scrollTop = retArea.scrollHeight;
                        if (flag == 1) {
                            count_down = -1;
                            refresh_flag = 0;
                        } else {
                            count_down = 6;
                            refresh_flag = 1;
                        }
                        count_down_close();
                        return false;
                    }
                    setTimeout("get_realtime_log(" + flag + ");", 200);
                    retArea.value = response.replace("ALSTBBACCEED", " ");
                    retArea.scrollTop = retArea.scrollHeight;
                },
                error: function (xhr) {
                    E("ok_button").style.visibility = "visible";
                    return false;
                }
            });
        }

        function count_down_close() {
            if (count_down == "0") {
                hideWBLoadingBar();
            }
            if (count_down < 0) {
                E("ok_button1").value = "手动关闭"
                return false;
            }
            E("ok_button1").value = "自动关闭（" + count_down + "）"
            --count_down;
            setTimeout("count_down_close();", 1000);
        }

        function showLoadingBar(title){
            document.scrollingElement.scrollTop = 0;
            E("loading_block_title").innerHTML = title ? title : "自动更新运行中，请稍后 ...";
            E("LoadingBar").style.visibility = "visible";
            var page_h = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
            var page_w = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
            var log_h = E("loadingBarBlock").clientHeight;
            var log_w = E("loadingBarBlock").clientWidth;
            var log_h_offset = (page_h - log_h) / 2;
            var log_w_offset = (page_w - log_w) / 2 + 90;
            $('#loadingBarBlock').offset({top: log_h_offset, left: log_w_offset});
        }

        function hideWBLoadingBar(){
            E("loading_block_spilt").style.visibility = "hidden";
            E("LoadingBar").style.visibility = "hidden";
            E("ok_button").style.visibility = "hidden";
            if (refresh_flag == "1"){
                var newURL = location.href.split("?")[0];
                window.history.pushState('object', document.title, newURL);
                refreshpage();
            }
        }

        function init() {
            show_menu(menu_hook);
			check_status();
            getGhVersion();
			checkVersion();
        }

        function menu_hook(title, tab) {
            tabtitle[tabtitle.length - 1] = new Array("", "Alist文件列表");
            tablink[tablink.length - 1] = new Array("", "Module_alist.asp");
        }

        $(function () {
            $('#btn_Start').click(start);
            $("#btn_Close").click(close);
            get_dbus_data();
        });

        function generate_options(){
        	for(var i = 2; i < 60; i++) {
        		$("#alist_watchdog_time").append("<option value='"  + i + "'>" + i + "</option>");
        		$("#alist_watchdog_time").val(3);
        	}
        }
    </script>
</head>
<body onload="init();">
    <div id="TopBanner"></div>
    <div id="Loading" class="popup_bg"></div>
    <div id="LoadingBar" class="popup_bar_bg_ks" style="z-index: 200;" >
        <table cellpadding="5" cellspacing="0" id="loadingBarBlock" class="loadingBarBlock" align="center">
            <tr>
                <td height="100">
                    <div id="loading_block_title" style="margin:10px auto;margin-left:10px;width:85%; font-size:12pt;"></div>
                    <div id="loading_block_spilt" style="margin:10px 0 10px 5px;" class="loading_block_spilt">
                        <li><font color="#ffcc00">请等待日志显示完毕，并出现自动关闭按钮！</font></li>
                        <li><font color="#ffcc00">在此期间请不要刷新本页面，不然可能导致问题！</font></li>
                    </div>
                    <div style="margin-left:15px;margin-right:15px;margin-top:10px;overflow:hidden">
                        <textarea cols="50" rows="25" wrap="off" readonly="readonly" id="log_content" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="border:1px solid #000;width:99%; font-family:'Lucida Console'; font-size:11px;background:transparent;color:#FFFFFF;outline: none;padding-left:3px;padding-right:22px;overflow-x:hidden"></textarea>
                    </div>
                    <div id="ok_button" class="apply_gen" style="background:#000;visibility:hidden;">
                        <input id="ok_button1" class="button_gen" type="button" onclick="hideWBLoadingBar()" value="确定">
                    </div>
                </td>
            </tr>
        </table>
    </div>
    <iframe name="hidden_frame" id="hidden_frame" width="0" height="0" frameborder="0"></iframe>
    <table class="content" align="center" cellpadding="0" cellspacing="0">
        <tr>
            <td width="17">&nbsp;</td>
            <td valign="top" width="202">
                <div id="mainMenu"></div>
                <div id="subMenu"></div>
            </td>
            <td valign="top">
                <div id="tabMenu" class="submenuBlock"></div>
                <table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
                    <tr>
                        <td align="left" valign="top">
                            <table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
                                <tr>
                                    <td bgcolor="#4D595D" colspan="3" valign="top">
                                        <div>&nbsp;</div>
                                        <div class="formfonttitle">软件中心 - Alist文件列表</div>
                                        <div style="float: right; width: 15px; height: 25px; margin-top: -20px">
                                            <img id="return_btn" alt="" onclick="reload_Soft_Center();" align="right" style="cursor: pointer; position: absolute; margin-left: -30px; margin-top: -25px;" title="返回软件中心" src="/images/backprev.png" onmouseover="this.src='/images/backprevclick.png'" onmouseout="this.src='/images/backprev.png'" />
                                        </div>
                                        <div style="margin: 10px 0 10px 5px;" class="splitLine"></div>
                                        <div class="SimpleNote">
                                            <a href="https://alist-doc.nn.ci/docs/intro" target="_blank"><em><u>Alist</u></em></a>&nbsp;一款支持多种存储的目录文件列表程序，支持 web 浏览与 webdav，后端基于gin，前端使用react。
                                            <a id="soft_change_log" type="button" style="cursor:pointer" href="javascript:void(0);"><em>【<u>插件更新日志</u>】</em></a>
                                        </div>
                                        <div id="tablets">
                                            <table style="margin:10px 0px 0px 0px;border-collapse:collapse" width="100%" height="37px">
                                                <tr width="400px">
                                                    <td colspan="4" cellpadding="0" cellspacing="0" style="padding:0" border="1" bordercolor="#000">
                                                        <a id="alist_name" class="show-btn" style="cursor:pointer" type="button">Alist文件列表</a>
                                                        <a id="version_update" class="show-btn" style="cursor:pointer" type="button" onClick="checkVersion();">检查更新中...</a>
                                                        <a id="version_update_1" class="show-btn" style="cursor:pointer;color:#00ffe4;display:none;" type="button" onClick="versionUpdate(1);">插件暂无更新</a>
                                                        <a id="bin_version_update" class="show-btn" style="cursor:pointer" type="button" onClick="checkBinVersion();">检查更新中...</a>
                                                        <a id="bin_version_update_1" class="show-btn" style="cursor:pointer;color:#00ffe4;display:none;" type="button" onClick="versionUpdate(1,'bin');">二进制暂无更新</a>
                                                    </td>
                                                </tr>
                                            </table>
                                        </div>
                                        <table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
                                            <thead>
                                                <tr>
                                                    <td colspan="2">Alist - 设置</td>
                                                </tr>
                                            </thead>
                                            <tr id="alist_tr">
                                                <th>开关</th>
                                                <td>
                                                <button id="btn_Start" class="ks_btn" style="width: 110px; cursor: pointer; float: left; ">开启</button>
                                                <button id="btn_Close" class="ks_btn" style="width: 110px; cursor: pointer; float: left; margin-left: 5px;">关闭</button>
                                                 </td>
                                            </tr>
                                            <tr id="alist_port_tr">
                                                <th>端口</th>
                                                <td>
                                                    <input type="text" id="alist_port" style="width: 50px;" maxlength="5" class="input_3_table" name="alist_port" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="5244">
                                                </td>
                                            </tr>
                                            <tr id="alist_port_tr">
                                                <th>密码</th>
                                                <td id="alist_pwd"></td>
                                            </tr>
                                            <tr>
                                                <th >状态</th>
                                                <td colspan="2"  id="alist_status"></td>
                                            </tr>
                                            <tr>
                                                <th >版本</th>
                                                <td colspan="2"  id="alist_version"></td>
                                            </tr>
                                            <tr>
                                                <th >面板</th>
                                                <td colspan="2"  id="alist_access">
                                                    <a type="button" style="vertical-align: middle; cursor:pointer;" id="fileb" class="ks_btn" target="_blank" >访问 Alist 面板</a>
                                                </td>
                                            </tr>
                                        </table>
                                        <table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
                                            <thead>
                                            <tr>
                                                <td colspan="2">公网访问设定 -- <em style="color: gold;">【请先设置相对应的<a href="./Advanced_VirtualServer_Content.asp" target="_blank"><em>端口转发</em></a>，再开启此按钮，重启插件后生效】</td>
                                            </tr>
                                            </thead>
                                            <tr id="dashboard">
                                            <th>开启公网访问</th>
                                            <td colspan="2">
                                                <div class="switch_field" style="display:table-cell;float: left;">
                                                <label for="alist_publicswitch">
                                                    <input id="alist_publicswitch" type="checkbox" name="dashboard" class="switch" style="display: none;">
                                                    <div class="switch_container" >
                                                        <div class="switch_bar"></div>
                                                        <div class="switch_circle transition_style">
                                                            <div></div>
                                                        </div>
                                                    </div>
                                                </label>
                                            </div>
                                            </td>
                                            </tr>
                                        </table>
                                        <table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
                                            <thead>
                                            <tr>
                                                <td colspan="2">看门狗设定 -- <em style="color: gold;">【看门狗会在<em>您设置的检查周期里</em></a>检查进程是否启动】</td>
                                            </tr>
                                            </thead>
                                            <tr id="dashboard">
                                            <th>开启看门狗</th>
                                            <td colspan="2">
                                                <div class="switch_field" style="display:table-cell;float: left;">
                                                <label for="alist_watchdog">
                                                    <input id="alist_watchdog" type="checkbox" name="dashboard" class="switch" style="display: none;">
                                                    <div class="switch_container" >
                                                        <div class="switch_bar"></div>
                                                        <div class="switch_circle transition_style">
                                                            <div></div>
                                                        </div>
                                                    </div>
                                                </label>
                                            </div>
                                            </td>
                                            </tr>
                                            <tr id="interval_tr">
                                                <th>检查周期</th>
                                                <td>
                                                    <select style="width:40px;margin:0px 0px 0px 2px;" id="alist_watchdog_time" name="alist_watchdog_time" class="input_option">
                                                    </select> 分钟
                                                </td>
                                            </tr>
                                        </table>
                                        <table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="filebrowser_switch_table">

                                            <thead>
                                            <tr>
                                                <td colspan="2">Alist 启动配置 -- <em style="color: gold;">【请查看<a href="https://alist-doc.nn.ci/docs/setting/config" target="_blank"><em>Alist官方文档</em></a>，不懂勿动！！！】</td>
                                            </tr>
                                            </thead>
                                        <tr>
                                            <th>用户登录过期时间</th>
                                            <td>
                                            <input onkeyup="this.value=this.value.replace(/[^1-9]+/,'2')" id="alist_token_expires_in" maxlength="8" style="color: #FFFFFF; width: 30px; height: 20px; background-color:rgba(87,109,115,0.5); font-family: Arial, Helvetica, sans-serif; font-weight:normal; font-size:12px;" value="48" ><span>&nbsp;小时</span>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th>网站URL（site_url）</th>
                                            <td>
                                            <input type="text" id="alist_site_url" style="width: 380px;" class="input_3_table" name="alist_site_url" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="">
                                            </td>
                                        </tr>
                                        <tr>
                                            <th>静态资源CDN地址</th>
                                            <td>
                                            <input type="text" id="alist_cdn" style="width: 380px;" class="input_3_table" name="alist_cdn" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="">
                                            </td>
                                        </tr>
                                        <tr>
                                            <th>是否启用Https</th>
                                            <td colspan="2">
                                                <div class="switch_field" style="display:table-cell;float: left;">
                                                    <label for="alist_https">
                                                        <input id="alist_https" class="switch" type="checkbox" style="display: none;">
                                                        <div class="switch_container" >
                                                            <div class="switch_bar"></div>
                                                            <div class="switch_circle transition_style">
                                                                <div></div>
                                                            </div>
                                                        </div>
                                                    </label>
                                                </div>
                                                <div class="SimpleNote" id="head_illustrate">
                                                </div>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th>证书Cert文件路径(绝对路径)</th>
                                            <td>
                                            <input type="text" id="alist_cert_file" style="width: 380px;" class="input_3_table" name="alist_cert_file" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="">
                                            </td>
                                        </tr>
                                        <tr>
                                            <th>证书Key文件路径(绝对路径)</th>
                                            <td>
                                            <input type="text" id="alist_key_file" style="width: 380px;" class="input_3_table" name="alist_key_file" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="">
                                            </td>
                                        </tr>
                                        </table>
                                        <div id="warning" style="font-size: 14px; margin: 20px auto;"></div>
                                        <div style="margin: 10px 0 10px 5px;" class="splitLine"></div>
                                        <div id="DEVICE_note" style="margin:10px 0 0 5px">
                                            <div><i>&nbsp;&nbsp;说明：<br>
                                            &nbsp;&nbsp;1.Alist后端管理密码请查看上面密码区；<br>
                                            &nbsp;&nbsp;2.如有不懂，请查看Alist官方文档<a href="https://alist-doc.nn.ci/docs/intro" target="_blank"><em>点这里看文档</em></a><br>
											&nbsp;&nbsp;3.如需开启HTTPS访问，请配置证书文件的全路径；<br>
											&nbsp;&nbsp;4.如若开启公网访问，切记注意公网访问安全；<br>
                                            &nbsp;&nbsp;5.长期开启公网访问有风险，请酌情使用。<br>
                                            &nbsp;&nbsp;插件使用有任何问题请加入<a href="https://t.me/xbchat" target="_blank"><em><u>koolcenter TG群</u></em></a>或<a href="https://t.me/meilinchajian" target="_blank"><em><u>Mc Chat TG群</u></em></a>联系 @fiswonder<br></i>
                                            </div>
                                            <div><i>&nbsp;</i></div>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
            </td>
            <td width="10" align="center" valign="top"></td>
        </tr>
    </table>
    <div id="footer"></div>
</body>
</html>

