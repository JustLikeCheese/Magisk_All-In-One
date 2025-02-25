#!/bin/sh
# 定义模块配置文件路径和日志文件路径
export CONFIG_FILE="/storage/emulated/0/Android/config.yaml"
export LOG_FILE="/storage/emulated/0/Android/config.yaml.log"
# 定义读取配置函数，若找不到匹配项，则返回默认值
read_config() {
  result=$(sed -n "s/^$1 //p" "${3:-$CONFIG_FILE}")
  echo "${result:-$2}"
}
# 定义写入配置函数
write_config() {
  sed -i "/^$1 /c$1 $2" "${3:-$CONFIG_FILE}"
}