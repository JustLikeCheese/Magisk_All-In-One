#!/bin/sh
ui_print "- 正在释放文件"
# 默认不删除温控，非必要情况下建议保留温控
# unzip -o "$ZIPFILE" 'RESOURCES/system/*' -d $MODPATH >&2
# 复制配置文件到 /storage/emulated/0/Android/config.yaml 路径
. "$MODPATH"/function.sh
CONFIG_FILE_BAK="$CONFIG_FILE.bak"
cp -f "$CONFIG_FILE" "$CONFIG_FILE_BAK"
cp -f "$MODPATH/config.yaml" "$CONFIG_FILE"
# 更新保留旧配置
if [ -f "$CONFIG_FILE_BAK" ]; then
  keep_config(){ write_config "${2:-$1}" "$(read_config "$1" "$(read_config "$1" "" "$MODPATH"/config.yaml)" "$CONFIG_FILE_BAK")"; }
  CONFIG_ITEMS="用户后台应用 系统后台应用 前台应用 上层应用 负载均衡 性能调节 TCP网络优化 内存优化 快充优化 王者优化 移除小米更新验证 模块日志输出 大核调度 小核调度"
  for items in $CONFIG_ITEMS; do keep_config "$items"; done
fi
# 获取模块属性
MODULE_VERSION=$(grep_prop version "$MODPATH"/module.prop)
echo "[$(date '+%m-%d %H:%M:%S.%3N')] All-In-One $MODULE_VERSION 版本模块安装成功, 等待重启" >> "$LOG_FILE"
ui_print "- All-In-One 优化模块 $MODULE_VERSION 版本"
ui_print "- 对系统 CPU / GPU / 内存深度优化"
ui_print "- 模块可以释放手机的全部性能"
ui_print "- 可自行查看 service.sh 与 system.prop 文件"
ui_print "- 默认不删除温控, 关于删除温控功能请自行前往酷安查看教程"
ui_print "- 配置文件在 $CONFIG_FILE"
ui_print "- 日志文件在 $LOG_FILE"
ui_print "- 作者 QQ: 854675824 | 酷安@TheCheese"
ui_print "- 模块安装结束 重启生效"