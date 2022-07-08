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
    <link rel="stylesheet" type="text/css" href="index_style.css" />
    <link rel="stylesheet" type="text/css" href="form_style.css" />
    <link rel="stylesheet" type="text/css" href="css/element.css">
    <link rel="stylesheet" type="text/css" href="res/softcenter.css">
    <script language="JavaScript" type="text/javascript" src="/state.js"></script>
    <script language="JavaScript" type="text/javascript" src="/help.js"></script>
    <script language="JavaScript" type="text/javascript" src="/general.js"></script>
    <script language="JavaScript" type="text/javascript" src="/popup.js"></script>
    <script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
    <script language="JavaScript" type="text/javascript" src="/validator.js"></script>
    <script type="text/javascript" src="/js/jquery.js"></script>
    <script type="text/javascript" src="/switcherplugin/jquery.iphone-switch.js"></script>
    <script type="text/javascript" src="/res/softcenter.js"></script>
    <script type="text/javascript">
        var db_alist = {}
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
					//console.log(response)
					var arr = response.result.split("@");
					E("alist_status").innerHTML = arr[0];
					var alistPwd =  arr[1].replace('your password: ','');
					E("alist_pwd").innerHTML = alistPwd ? alistPwd : '<span style="color: red">未启用</span>';
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
            db_alist['alist_https']        = E("alist_https").checked ? '1' : '0';
            db_alist['alist_port']         = E('alist_port').value;
            db_alist['alist_assets']       = E('alist_assets').value;
            db_alist['alist_cache_cleaup'] = E('alist_cache_cleaup').value;
            db_alist['alist_cache_time']   = E('alist_cache_time').value;
            db_alist['alist_publicswitch'] = E("alist_publicswitch").checked ? '1' : '0';
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
        function init() {
            show_menu(menu_hook);
			check_status();
        }

        function menu_hook(title, tab) {
            tabtitle[tabtitle.length - 1] = new Array("", "Alist文件列表");
            tablink[tablink.length - 1] = new Array("", "Module_alist.asp");
        }

        function get_dbus_data() {
            $.ajax({
                type: "GET",
                url: "/_api/alist",
                dataType: "json",
                async: false,
                success: function (data) {
                    console.log(data);
					db_alist = data.result[0];
                    E("alist_https").checked = db_alist["alist_https"] == "1";
					E("alist_publicswitch").checked = db_alist["alist_publicswitch"] == "1";
					if(db_alist["alist_cache_time"]){
						E("alist_cache_time").value = db_alist["alist_cache_time"];
					}
					if(db_alist["alist_cache_cleaup"]){
						E("alist_cache_cleaup").value = db_alist["alist_cache_cleaup"];
					}
                    if(db_alist["alist_port"]){
						E("alist_port").value = db_alist["alist_port"];
					}
                    if(db_alist["alist_assets"]){
						E("alist_assets").value = db_alist["alist_assets"];
					}
                }
            });
        }

        $(function () {
            $('#btn_Start').click(start);
            $("#btn_Close").click(close);
            get_dbus_data();
        });
    </script>
</head>
<body onload="init();">
    <div id="TopBanner"></div>
    <div id="Loading" class="popup_bg"></div>
    <div id="LoadingBar" class="popup_bar_bg">
        <table cellpadding="5" cellspacing="0" id="loadingBarBlock" class="loadingBarBlock" align="center">
            <tr>
                <td height="100">
                    <div id="loading_block3" style="margin: 10px auto; margin-left: 10px; width: 85%; font-size: 12pt;"></div>
                    <div id="loading_block2" style="margin: 10px auto; width: 95%;"></div>
                    <div id="log_content2" style="margin-left: 15px; margin-right: 15px; margin-top: 10px; overflow: hidden">
                        <textarea cols="63" rows="21" wrap="on" readonly="readonly" id="log_content3" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="border: 1px solid #000; width: 99%; font-family: 'Courier New', Courier, mono; font-size: 11px; background: #000; color: #FFFFFF;"></textarea>
                    </div>
                    <div id="ok_button" class="apply_gen" style="background: #000; display: none;">
                        <input id="ok_button1" class="button_gen" type="button" onclick="hideKPLoadingBar()" value="确定">
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
                                                <th >访问</th>
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
                                        <table style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="filebrowser_switch_table">

                                            <thead>
                                            <tr>
                                                <td colspan="2">Alist 启动配置 -- <em style="color: gold;">【请查看<a href="https://alist-doc.nn.ci/docs/setting/config" target="_blank"><em>Alist官方文档</em></a>，不懂勿动！！！】</td>
                                            </tr>
                                            </thead>
                                        <tr>
                                            <th>缓存失效时间</th>
                                            <td>
                                            <input onkeyup="this.value=this.value.replace(/[^1-9]+/,'2')" id="alist_cache_time" maxlength="1" style="color: #FFFFFF; width: 30px; height: 20px; background-color:rgba(87,109,115,0.5); font-family: Arial, Helvetica, sans-serif; font-weight:normal; font-size:12px;" value="2" ><span>&nbsp;分钟</span>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th>清理失效缓存间隔</th>
                                            <td>
                                            <input onkeyup="this.value=this.value.replace(/[^1-9]+/,'2')" id="alist_cache_cleaup" maxlength="1" style="color: #FFFFFF; width: 30px; height: 20px; background-color:rgba(87,109,115,0.5); font-family: Arial, Helvetica, sans-serif; font-weight:normal; font-size:12px;" value="2" ><span>&nbsp;分钟</span>
                                            </td>
                                        </tr>
                                        <tr>
                                            <th>静态资源位置</th>
                                            <td>
                                            <input type="text" id="alist_assets" style="width: 380px;" class="input_3_table" name="alist_assets" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="">
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

