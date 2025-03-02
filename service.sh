#!/bin/sh
# 延迟执行 service.sh 脚本
# All-In-One v1.0 的 sleep 1m 在某些设备上不太实际
# 从 v1.2 版本开始采用监测文件方案判断是否开机
# while true 嵌套 sleep 1 并不会造成开机卡死
# 参考如何有效降低死循环的 CPU 占用 - sebastia - 博客园
# https://www.cnblogs.com/memoryLost/p/10907654.html

# 循环判断是否开机
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done
# 创建用于文件权限测试的文件
test_file="/sdcard/Android/.PERMISSION_TEST"
# 写入 true 到文件
true >"$test_file"
# 判断是否有权限
while [ ! -f "$test_file" ]; do
    true > "$test_file"
    sleep 2
done
# 删除测试文件
rm -f "$test_file"


# 调用 function.sh 库
MODDIR=${0%/*}
. "$MODDIR"/function.sh

# 读取 config.yaml 配置
# 性能模式
PERFORMANCE=$(read_config "性能调节" "0")
# 负载均衡
SCHEDTUNE=$(read_config "负载均衡" "0")

# 获取 CPU 应用分配
BACKGROUND=$(read_config "用户后台应用" "0-1")
SYSTEM_BACKGROUND=$(read_config "系统后台应用" "0-2")
FOREGROUND=$(read_config "前台应用" "0-7")
SYSTEM_FOREGROUND=$(read_config "上层应用" "0-7")

# 其他选项
# 王者荣耀游戏优化
OPTIMIZE_WZRY=$(read_config "王者优化" "0")
# 获取内存优化配置
OPTIMIZE_ZRAM=$(read_config "内存优化" "0")
# TCP 网络优化
OPTIMIZE_TCP=$(read_config "TCP网络优化" "1")
# 快充优化
OPTIMIZE_CHARGE=$(read_config "快充优化" "1")
# 移除小米更新验证
OPTIMIZE_MIUI_OTA=$(read_config "移除小米更新验证" "0")
# 模块日志输出
OPTIMIZE_MODULE=$(read_config "模块日志输出" "0")
# 模块调试模式
OPTIMIZE_DEBUG="$1"

# 大核调度
# 大核 提高这个值有利于性能，不利于降低功耗。
SCHED_DOWNMIGRATE=$(read_config "大核调度" "40 40")
# 小核 提高这个值有利于降低功耗，不利于性能。
SCHED_UPMIGRATE=$(read_config "小核调度" "60 60")

# 已创建文件则在末尾添加换行
[ -f "$LOG_FILE" ] && [ "$OPTIMIZE_DEBUG" != "DEBUG" ] \
&& { [ "$OPTIMIZE_MODULE" = 0 ] || [ "$OPTIMIZE_MODULE" = 1 ]; } \
&& echo "" >> "$LOG_FILE"

# 定义 module_log 输出日志函数
module_log() {
    case "$OPTIMIZE_MODULE" in
    2) case "$1" in Ciallo*) ;; *) return ;; esac ;; # 屏蔽不是 Ciallo～ (∠・ω< )⌒☆ 的日志
    3) [ "$OPTIMIZE_DEBUG" != "DEBUG" ] && return ;; # 屏蔽不是在调试模式下输出的日志 3
    esac
    if [ "$OPTIMIZE_DEBUG" = "DEBUG" ]; then
      echo "[$(date '+%m-%d %H:%M:%S.%3N')] $1"
    else
      echo "[$(date '+%m-%d %H:%M:%S.%3N')] $1" >> "$LOG_FILE"
    fi
}

# 输出日志
module_log "开机完成，正在读取 config.yaml 配置.."


# 优化 CPU 核心分配
if [ "$PERFORMANCE" = "0" ]; then
  # 输出日志
  module_log "当前模式: 性能优先（$PERFORMANCE)"
  # 设置 CPU 应用分配
  # 用户后台应用
  echo "$BACKGROUND" > /dev/cpuset/background/cpus
  # 系统后台应用
  echo "$SYSTEM_BACKGROUND" > /dev/cpuset/system-background/cpus
  # 前台应用
  echo "$FOREGROUND" > /dev/cpuset/foreground/cpus
  # 上层应用
  echo "$SYSTEM_FOREGROUND" > /dev/cpuset/top-app/cpus

  # 输出日志
  if [ "$OPTIMIZE_MODULE" = "0" ]; then
    module_log "正在设置 CPU 应用分配"
    module_log "- 用户的后台应用: $BACKGROUND"
    module_log "- 系统的后台应用: $SYSTEM_BACKGROUND"
    module_log "- 前台应用: $FOREGROUND"
    module_log "- 上层应用: $SYSTEM_FOREGROUND"
  fi

  # 大核 提高这个值有利于性能，不利于降低功耗。
  echo "$SCHED_DOWNMIGRATE" > /proc/sys/kernel/sched_downmigrate
  # 小核 提高这个值有利于降低功耗，不利于性能。
  echo "$SCHED_UPMIGRATE" > /proc/sys/kernel/sched_upmigrate
  if [ "$OPTIMIZE_MODULE" = "0" ]; then
    module_log "- CPU 大核分配: ${SCHED_DOWNMIGRATE}"
    module_log "- CPU 小核分配: ${SCHED_UPMIGRATE}"
  fi
  # 较为轻的温控方案
  # GPU 温控 115度 极限120 到120会过热保护
  echo "115000" > /sys/class/thermal/thermal_zone32/trip_point_0_temp
  # CPU 温控 修改为99度
  echo "99000" > /sys/class/thermal/thermal_zone36/trip_point_0_temp
  if [ "$OPTIMIZE_MODULE" = "0" ]; then
    module_log "- CPU/GPU 温控优化温控已开启"
  fi

  # CPU 负载均衡，改1为核心均衡，2为软件均衡，可能只会有部分生效，是因为系统限制
  echo "$SCHEDTUNE" > /dev/cpuset/sched_relax_domain_level
  echo "$SCHEDTUNE" > /dev/cpuset/system-background/sched_relax_domain_level
  echo "$SCHEDTUNE" > /dev/cpuset/background/sched_relax_domain_level
  echo "$SCHEDTUNE" > /dev/cpuset/camera-background/sched_relax_domain_level
  echo "$SCHEDTUNE" > /dev/cpuset/foreground/sched_relax_domain_level
  echo "$SCHEDTUNE" > /dev/cpuset/top-app/sched_relax_domain_level
  echo "$SCHEDTUNE" > /dev/cpuset/restricted/sched_relax_domain_level
  echo "$SCHEDTUNE" > /dev/cpuset/asopt/sched_relax_domain_level
  echo "$SCHEDTUNE" > /dev/cpuset/camera-daemon/sched_relax_domain_level
  # 输出负载均衡模式
  if [ "$OPTIMIZE_MODULE" = "0" ]; then
    if [ "$SCHEDTUNE" = "1" ]; then
      module_log "当前 CPU 负载均衡模式: 核心均衡"
    elif [ "$SCHEDTUNE" = "2" ]; then
      module_log "当前 CPU 负载均衡模式: 软件均衡"
    fi
  fi

  # CPU 调度
  CPU_SCALING="performance"
  chmod 644 /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
  echo $CPU_SCALING > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
  chmod 644 /sys/devices/system/cpu/cpu6/cpufreq/scaling_governor
  echo $CPU_SCALING > /sys/devices/system/cpu/cpu6/cpufreq/scaling_governor
  chmod 644 /sys/devices/system/cpu/cpu7/cpufreq/scaling_governor
  echo $CPU_SCALING > /sys/devices/system/cpu/cpu7/cpufreq/scaling_governor
  # 将 CPU_SCALING 模式转换为大写字符串并输出
  CPU_SCALING_UPPERCASE=$(echo "$CPU_SCALING" | tr '[:lower:]' '[:upper:]')
  [ "$OPTIMIZE_MODULE" = "0" ] && module_log "CPU 调度模式为 ${CPU_SCALING_UPPERCASE} 性能模式"
  # 启用所有离线的 CPU
  for cpu in /sys/devices/system/cpu/cpu*/online; do
    [ "$(cat "$cpu")" = "0" ] && echo "1" > "$cpu"
  done
elif [ "$PERFORMANCE" = "1" ]; then
  # 输出日志
  module_log "当前模式: 省电优先（$PERFORMANCE)"
  # 设置 CPU 应用分配
  # 用户后台应用
  echo "0" > /dev/cpuset/background/cpus
  # 系统后台应用
  echo "0" > /dev/cpuset/system-background/cpus
  # 前台应用
  echo "1-3" > /dev/cpuset/foreground/cpus
  # 上层应用
  echo "3" > /dev/cpuset/top-app/cpus

  # 输出日志
  if [ "$OPTIMIZE_MODULE" = "0" ]; then
    module_log "正在设置 CPU 应用分配"
    module_log "- 用户的后台应用: $BACKGROUND"
    module_log "- 系统的后台应用: $SYSTEM_BACKGROUND"
    module_log "- 前台应用: $FOREGROUND"
    module_log "- 上层应用: $SYSTEM_FOREGROUND"
  fi

  # 大核 提高这个值有利于性能，不利于降低功耗。
  echo "$SCHED_DOWNMIGRATE" > /proc/sys/kernel/sched_downmigrate
  # 小核 提高这个值有利于降低功耗，不利于性能。
  echo "$SCHED_UPMIGRATE" > /proc/sys/kernel/sched_upmigrate
  if [ "$OPTIMIZE_MODULE" = "0" ]; then
    module_log "- CPU 大核分配: ${SCHED_DOWNMIGRATE}"
    module_log "- CPU 小核分配: ${SCHED_UPMIGRATE}"
  fi

  # CPU 负载均衡，改1为核心均衡，2为软件均衡，可能只会有部分生效，是因为系统限制
  echo "$SCHEDTUNE" > /dev/cpuset/sched_relax_domain_level
  echo "$SCHEDTUNE" > /dev/cpuset/system-background/sched_relax_domain_level
  echo "$SCHEDTUNE" > /dev/cpuset/background/sched_relax_domain_level
  echo "$SCHEDTUNE" > /dev/cpuset/camera-background/sched_relax_domain_level
  echo "$SCHEDTUNE" > /dev/cpuset/foreground/sched_relax_domain_level
  echo "$SCHEDTUNE" > /dev/cpuset/top-app/sched_relax_domain_level
  echo "$SCHEDTUNE" > /dev/cpuset/restricted/sched_relax_domain_level
  echo "$SCHEDTUNE" > /dev/cpuset/asopt/sched_relax_domain_level
  echo "$SCHEDTUNE" > /dev/cpuset/camera-daemon/sched_relax_domain_level
  # 输出负载均衡模式
  if [ "$OPTIMIZE_MODULE" = "0" ]; then
    if [ "$SCHEDTUNE" = "1" ]; then
      module_log "当前 CPU 负载均衡模式: 核心均衡"
    elif [ "$SCHEDTUNE" = "2" ]; then
      module_log "当前 CPU 负载均衡模式: 软件均衡"
    fi
  fi

  # CPU 调度
  CPU_SCALING="powersave"
  chmod 644 /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
  echo "$CPU_SCALING" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
  chmod 644 /sys/devices/system/cpu/cpu6/cpufreq/scaling_governor
  echo "$CPU_SCALING" > /sys/devices/system/cpu/cpu6/cpufreq/scaling_governor
  chmod 644 /sys/devices/system/cpu/cpu7/cpufreq/scaling_governor
  echo "$CPU_SCALING" > /sys/devices/system/cpu/cpu7/cpufreq/scaling_governor
  # 将 CPU_SCALING 模式转换为大写字符串并输出
  CPU_SCALING_UPPERCASE=$(echo "$CPU_SCALING" | tr '[:lower:]' '[:upper:]')
  [ "$OPTIMIZE_MODULE" = "0" ] && module_log "CPU 调度模式为 ${CPU_SCALING_UPPERCASE} 性能模式"
elif [ "$PERFORMANCE" = "2" ]; then
  module_log "当前模式: 养老模式（$PERFORMANCE)"
fi








if [ "$PERFORMANCE" = "0" ]; then
  # CPU 调整
  echo "100" > /dev/stune/schedtune.boost
  echo "100" > /dev/stune/foreground/schedtune.boost
  echo "100" > /dev/stune/top-app/schedtune.boost
  echo "20" > /dev/stune/background/schedtune.boost
  echo "20" > /dev/stune/rt/schedtune.boost
  echo "50" > /dev/stune/io/schedtune.boost
  echo "50" > /dev/stune/camera-daemon/schedtune.boost
  # 禁用调度自动分组
  echo "0" > /proc/sys/kernel/sched_autogroup_enabled
  # 功耗换性能
  echo "1" > /sys/module/ged/parameters/gx_game_mode
  echo "47" > /sys/module/ged/parameters/gx_fb_dvfs_margin
  echo "1" > /sys/module/ged/parameters/enable_cpu_boost
  echo "1" > /sys/module/ged/parameters/enable_gpu_boost
  echo "1" > /sys/module/ged/parameters/gx_dfps
  echo "1" > /sys/devices/system/cpu/cpufreq/performance/boost
  echo "1" > /sys/devices/system/cpu/cpufreq/performance/max_freq_hysteresis
  echo "1" > /sys/devices/system/cpu/cpufreq/performance/align_windows
  echo "0" > /sys/module/adreno_idler/parameters/adreno_idler_active
  echo "1" > /sys/module/msm_performance/parameters/touchboost
  echo "-1" > /sys/kernel/fpsgo/fbt/thrm_limit_cpu
  echo "-1" > /sys/kernel/fpsgo/fbt/thrm_sub_cpu
  # CPU 极致优化
  # DDR
  chmod 777 /sys/devices/system/cpu/bus_dcvs/DDR/boost_freq
  echo "4224000" > /sys/devices/system/cpu/bus_dcvs/DDR/boost_freq
  chmod 444 /sys/devices/system/cpu/bus_dcvs/DDR/boost_freq
  chmod 777 /sys/devices/system/cpu/bus_dcvs/DDR/hw_min_freq
  echo "4224000" > /sys/devices/system/cpu/bus_dcvs/DDR/hw_min_freq
  chmod 444 /sys/devices/system/cpu/bus_dcvs/DDR/hw_min_freq
  # DDRQOS
  chmod 777 /sys/devices/system/cpu/bus_dcvs/DDRQOS/boost_freq
  echo "1" > /sys/devices/system/cpu/bus_dcvs/DDRQOS/boost_freq
  chmod 444 /sys/devices/system/cpu/bus_dcvs/DDRQOS/boost_freq
  chmod 777 /sys/devices/system/cpu/bus_dcvs/DDRQOS/hw_min_freq
  echo "1" > /sys/devices/system/cpu/bus_dcvs/DDRQOS/hw_min_freq
  chmod 444 /sys/devices/system/cpu/bus_dcvs/DDRQOS/hw_min_freq
  # L3
  chmod 777 /sys/devices/system/cpu/bus_dcvs/L3/boost_freq
  echo "1804800" > /sys/devices/system/cpu/bus_dcvs/L3/boost_freq
  chmod 444 /sys/devices/system/cpu/bus_dcvs/L3/boost_freq
  chmod 777 /sys/devices/system/cpu/bus_dcvs/L3/hw_min_freq
  echo "1804800" > /sys/devices/system/cpu/bus_dcvs/L3/hw_min_freq
  chmod 444 /sys/devices/system/cpu/bus_dcvs/L3/hw_min_freq
  # LLCC
  chmod 777 /sys/devices/system/cpu/bus_dcvs/LLCC/boost_freq
  echo "1066000" > /sys/devices/system/cpu/bus_dcvs/LLCC/boost_freq
  chmod 444 /sys/devices/system/cpu/bus_dcvs/LLCC/boost_freq
  chmod 777 /sys/devices/system/cpu/bus_dcvs/LLCC/hw_min_freq
  echo "1066000" > /sys/devices/system/cpu/bus_dcvs/LLCC/hw_min_freq
  chmod 444 /sys/devices/system/cpu/bus_dcvs/LLCC/hw_min_freq
  # 设定当大核忙碌程度hispeed_load到达一定值时立刻跳到设定的freq频率
  chmod 777 /sys/devices/system/cpu/cpu0/cpufreq/walt/hispeed_load
  echo "30" > /sys/devices/system/cpu/cpu0/cpufreq/walt/hispeed_load
  chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/walt/hispeed_load
  # CPU 3
  chmod 777 /sys/devices/system/cpu/cpu3/cpufreq/walt/hispeed_load
  echo "40" > /sys/devices/system/cpu/cpu3/cpufreq/walt/hispeed_load
  chmod 777 /sys/devices/system/cpu/cpu3/cpufreq/walt/hispeed_load
  # CPU 7
  chmod 777 /sys/devices/system/cpu/cpu7/cpufreq/walt/hispeed_load
  echo "55" > /sys/devices/system/cpu/cpu7/cpufreq/walt/hispeed_load
  chmod 777 /sys/devices/system/cpu/cpu7/cpufreq/walt/hispeed_load
  # CPU 0
  # 设定当大核忙碌程度hispeed_load到达一定值时立刻跳到设定的freq频率
  chmod 777 /sys/devices/system/cpu/cpu0/cpufreq/walt/hispeed_freq
  echo "2016000" > /sys/devices/system/cpu/cpu0/cpufreq/walt/hispeed_freq
  chmod 444 /sys/devices/system/cpu/cpu0/cpufreq/walt/hispeed_freq
  # CPU 3
  chmod 777 /sys/devices/system/cpu/cpu3/cpufreq/walt/hispeed_freq
  echo "2803200" > /sys/devices/system/cpu/cpu3/cpufreq/walt/hispeed_freq
  chmod 777 /sys/devices/system/cpu/cpu3/cpufreq/walt/hispeed_freq
  # CPU
  chmod 777 /sys/devices/system/cpu/cpufreq/policy0/walt/boost
  echo "1" > /sys/devices/system/cpu/cpufreq/policy0/walt/boost
  chmod 444 /sys/devices/system/cpu/cpufreq/policy0/walt/boost
  # Policy 3
  chmod 777 /sys/devices/system/cpu/cpufreq/policy3/walt/boost
  echo "1" > /sys/devices/system/cpu/cpufreq/policy3/walt/boost
  chmod 444 /sys/devices/system/cpu/cpufreq/policy3/walt/boost
  # Policy 7
  chmod 777 /sys/devices/system/cpu/cpufreq/policy7/walt/boost
  echo "1" > /sys/devices/system/cpu/cpufreq/policy7/walt/boost
  chmod 444 /sys/devices/system/cpu/cpufreq/policy7/walt/boost
  # Policy 0
  chmod 777 /sys/devices/system/cpu/cpufreq/policy0/walt/adaptive_high_freq
  echo "1" > /sys/devices/system/cpu/cpufreq/policy0/walt/adaptive_high_freq
  chmod 444 /sys/devices/system/cpu/cpufreq/policy0/walt/adaptive_high_freq
  # Policy 3
  chmod 777 /sys/devices/system/cpu/cpufreq/policy3/walt/adaptive_high_freq
  echo "1" > /sys/devices/system/cpu/cpufreq/policy3/walt/adaptive_high_freq
  chmod 444 /sys/devices/system/cpu/cpufreq/policy3/walt/adaptive_high_freq
  # Policy 7
  chmod 777 /sys/devices/system/cpu/cpufreq/policy7/walt/adaptive_high_freq
  echo "1" > /sys/devices/system/cpu/cpufreq/policy7/walt/adaptive_high_freq
  chmod 444 /sys/devices/system/cpu/cpufreq/policy7/walt/adaptive_high_freq
  # CoreCTL CPU 0
  chmod 777 /sys/devices/system/cpu/cpu0/core_ctl/offline_delay_ms
  echo "0" > /sys/devices/system/cpu/cpu0/core_ctl/offline_delay_ms
  chmod 444 /sys/devices/system/cpu/cpu0/core_ctl/offline_delay_ms
  # CoreCTL CPU 3
  chmod 777 /sys/devices/system/cpu/cpu3/core_ctl/offline_delay_ms
  echo "0" > /sys/devices/system/cpu/cpu3/core_ctl/offline_delay_ms
  chmod 444 /sys/devices/system/cpu/cpu3/core_ctl/offline_delay_ms
  # CoreCTL CPU 7
  chmod 777 /sys/devices/system/cpu/cpu7/core_ctl/offline_delay_ms
  echo "0" > /sys/devices/system/cpu/cpu7/core_ctl/offline_delay_ms
  chmod 444 /sys/devices/system/cpu/cpu7/core_ctl/offline_delay_ms
  # CoreCTL CPU 0
  chmod 777 /sys/devices/system/cpu/cpu0/core_ctl/busy_up_thres
  echo "100 100 100" > /sys/devices/system/cpu/cpu0/core_ctl/busy_up_thres
  chmod 444 /sys/devices/system/cpu/cpu0/core_ctl/busy_up_thres
  # CoreCTL CPU 3
  chmod 777 /sys/devices/system/cpu/cpu3/core_ctl/busy_up_thres
  echo "100 100 100" > /sys/devices/system/cpu/cpu3/core_ctl/busy_up_thres
  chmod 444 /sys/devices/system/cpu/cpu3/core_ctl/busy_up_thres
  # CoreCTL CPU 7
  chmod 777 /sys/devices/system/cpu/cpu7/core_ctl/busy_up_thres
  echo "100 100 100" > /sys/devices/system/cpu/cpu7/core_ctl/busy_up_thres
  chmod 444 /sys/devices/system/cpu/cpu7/core_ctl/busy_up_thres
  # CoreCTL CPU 0
  chmod 777 /sys/devices/system/cpu/cpu0/core_ctl/busy_down_thres
  echo "20 20 20" > /sys/devices/system/cpu/cpu0/core_ctl/busy_down_thres
  chmod 444 /sys/devices/system/cpu/cpu0/core_ctl/busy_down_thres
  # CoreCTL CPU 3
  chmod 777 /sys/devices/system/cpu/cpu3/core_ctl/busy_down_thres
  echo "25 25 25" > /sys/devices/system/cpu/cpu3/core_ctl/busy_down_thres
  chmod 444 /sys/devices/system/cpu/cpu3/core_ctl/busy_down_thres
  # CoreCTL CPU 7
  chmod 777 /sys/devices/system/cpu/cpu7/core_ctl/busy_down_thres
  echo "20 20 20" > /sys/devices/system/cpu/cpu7/core_ctl/busy_down_thres
  chmod 444 /sys/devices/system/cpu/cpu7/core_ctl/busy_down_thres
  # 设置 GPU 等待时间
  chmod 777 /sys/class/kgsl/kgsl-3d0/idle_timer
  echo "120" > /sys/class/kgsl/kgsl-3d0/idle_timer
  chmod 444 /sys/class/kgsl/kgsl-3d0/idle_timer
  # 关闭 CPU 动态电压调节的功能
  echo "0" > /sys/devices/system/cpu/c1dcvs/enable_c1dcvs
  # 通过DEBUG模式开启 GPU/CPU 加速
  settings put global enable_gpu_debug_layers 0
  settings put system debug.composition.type dyn
  [ "$OPTIMIZE_MODULE" = "0" ] && module_log "GPU 加速已开启 (启用DEBUG模式)"
  echo "1" > /proc/cpu_loading/debug_enable
  echo "1" > /proc/cpu_loading/uevent_enable
  echo "68" > /proc/cpu_loading/overThrhld
  echo "45" > /proc/cpu_loading/underThrhld
  echo "68" > /proc/cpu_loading/specify_overThrhld
  echo "7654" > /proc/cpu_loading/specify_cpus
  [ "$OPTIMIZE_MODULE" = "0" ] && module_log "CPU 加速已开启（启用DEBUG模式）"
  # GPU 优化
  echo "0" > /sys/class/kgsl/kgsl-3d0/default_pwrlevel
  echo "3" > /sys/class/kgsl/kgsl-3d0/devfreq/adrenoboost
  # ETO 优化
  echo "0" > /sys/module/simple_gpu_algorithm/parameters/simple_laziness
  echo "10000" > /sys/module/simple_gpu_algorithm/parameters/simple_ramp_threshold
  echo "0" > /sys/module/adreno_idler/parameters/adreno_idler_downdifferential
  echo "99" > /sys/module/adreno_idler/parameters/adreno_idler_idlewait
  echo "1000" > /sys/module/adreno_idler/parameters/adreno_idler_idleworkload
fi


# I/O STATS 优化
echo "0" > /sys/block/dm-0/queue/iostats
echo "0" > /sys/block/mmcblk0/queue/iostats
echo "0" > /sys/block/mmcblk0rpmb/queue/iostats
echo "0" > /sys/block/mmcblk1/queue/iostats
echo "0" > /sys/block/loop0/queue/iostats
echo "0" > /sys/block/loop1/queue/iostats
echo "0" > /sys/block/loop2/queue/iostats
echo "0" > /sys/block/loop3/queue/iostats
echo "0" > /sys/block/loop4/queue/iostats
echo "0" > /sys/block/loop5/queue/iostats
echo "0" > /sys/block/loop6/queue/iostats
echo "0" > /sys/block/loop7/queue/iostats
echo "0" > /sys/block/sda/queue/iostats
echo "0" > /sys/block/sdb/queue/iostats
echo "2" > /sys/block/sda/queue/rq_affinity
# 页面簇优化
echo "0" > /proc/sys/vm/page-cluster
# 内核堆优化
echo "0" > /proc/sys/kernel/randomize_va_space
# 禁止压缩不可压缩的进程
echo "0" > /proc/sys/vm/compact_unevictable_allowed
# 禁用 Android Binder 调试
echo "0" > /sys/module/binder/parameters/debug_mask
echo "0" > /sys/module/binder_alloc/parameters/debug_mask
# 禁用内核调试
echo "0" > /sys/module/msm_show_resume_irq/parameters/debug_mask
echo "N" > /sys/kernel/debug/debug_enabled
# 禁用不必要的转储
echo "0" > /sys/module/subsystem_restart/parameters/enable_ramdumps
# 禁用调度数据统计（安卓 11+）
echo "0" > /proc/sys/kernel/sched_schedstats
# 禁用F2FS IO统计（安卓 12+）
echo "0" > /dev/sys/fs/by-name/userdata/iostat_enable
# 输出简要日志
[ "$OPTIMIZE_MODULE" = "1" ] && module_log "已开启 CPU / GPU 优化"


# 王者荣耀游戏优化
if [ "$OPTIMIZE_WZRY" = "1" ]; then
  # 开启王者荣耀 O3T 优化
  # 王者荣耀配置文件夹路径
  [ "$OPTIMIZE_MODULE" = "0" ] && module_log "正在开启王者荣耀 O3T 优化"
  SHARED_PREFS="/data/data/com.tencent.tmgp.sgame/shared_prefs"
  if [ ! -d "$SHARED_PREFS" ]; then
    [ "$OPTIMIZE_MODULE" = "0" ] && module_log "- 未找到王者荣耀配置文件夹"
  else
    # 王者荣耀配置文件
    PLAYER_PREFS="$SHARED_PREFS/com.tencent.tmgp.sgame.v2.playerprefs.xml"
    # OpenGLES3Config.xml 配置文件路径
    CONFIG="$SHARED_PREFS/OpenGLES3Config.xml"
    # 更新 OpenGLES3Config.xml 配置
    echo "<?xml version='1.0'encoding='utf-8'standalone='yes'?>
<map>
    <int name=\"MemSizeForGPUSkin\"value=\"9999\"/>
    <boolean name=\"EnableGPUSkin\"value=\"false\"/>
    <boolean name=\"EnableGLES3\"value=\"false\"/>
</map>" > $CONFIG
    [ "$OPTIMIZE_MODULE" = "0" ] && module_log "- 更新王者荣耀 OpenGLES3Config.xml 配置文件"
    # 删除王者荣耀配置参数
    sed -i '/.*<int name="VulkanTryCount" value=".*" \/>/d' "$PLAYER_PREFS"
    sed -i '/.*<int name="EnableVulkan" value=".*" \/>/d' "$PLAYER_PREFS"
    sed -i '/.*<int name="EnableGLES3" value=".*" \/>/d' "$PLAYER_PREFS"
    sed -i '/.*<int name="EnableMTR" value=".*" \/>/d' "$PLAYER_PREFS"
    sed -i '/.*<int name="DisableMTR" value=".*" \/>/d' "$PLAYER_PREFS"
    sed -i '/.*<int name="sgame_ALL_HighFPS" value=".*" \/>/d' "$PLAYER_PREFS"
    sed -i '/.*<int name="EnableHWVendorOpt" value=".*" \/>/d' "$PLAYER_PREFS"
    sed -i '/.*<int name="UnityGraphicsQuality" value=".*" \/>/d' "$PLAYER_PREFS"
    sed -i '/.*<int name="EnableGPUReport" value=".*" \/>/d' "$PLAYER_PREFS"
    # 更新王者荣耀 O3T 配置参数
    sed -i '2a \ \ \ \ <int name="VulkanTryCount" value="1" \/>' "$PLAYER_PREFS"
    sed -i '3a \ \ \ \ <int name="EnableVulkan" value="3" \/>' "$PLAYER_PREFS"
    sed -i '4a \ \ \ \ <int name="EnableGLES3" value="2" \/>' "$PLAYER_PREFS"
    sed -i '5a \ \ \ \ <int name="EnableMTR" value="1" \/>' "$PLAYER_PREFS"
    sed -i '6a \ \ \ \ <int name="DisableMTR" value="3" \/>' "$PLAYER_PREFS"
    sed -i '7a \ \ \ \ <int name="sgame_ALL_HighFPS" value="1" \/>' "$PLAYER_PREFS"
    sed -i '8a \ \ \ \ <int name="EnableHWVendorOpt" value="1" \/>' "$PLAYER_PREFS"
    sed -i '9a \ \ \ \ <int name="UnityGraphicsQuality" value="1" \/>' "$PLAYER_PREFS"
    sed -i '10a \ \ \ \ <int name="EnableGPUReport" value="2" \/>' "$PLAYER_PREFS"
    [ "$OPTIMIZE_MODULE" = "0" ] && module_log "- 更新王者荣耀配置参数"
    chmod 550 $SHARED_PREFS
    chmod 440 $PLAYER_PREFS
    [ "$OPTIMIZE_MODULE" = "0" ] && module_log "- 更新配置文件权限"
    [ "$OPTIMIZE_MODULE" = "0" ] && module_log "- 已开启王者荣耀 O3T 优化"
    [ "$OPTIMIZE_MODULE" = "1" ] && module_log "已开启王者荣耀 O3T 优化"
  fi
elif [ "$OPTIMIZE_WZRY" = "2" ]; then
  # 开启王者荣耀 VT 优化
  [ "$OPTIMIZE_MODULE" = "0" ] && module_log "正在开启王者荣耀 VT 优化"
  SHARED_PREFS="/data/data/com.tencent.tmgp.sgame/shared_prefs"
  if [ ! -d "$SHARED_PREFS" ]; then
    [ "$OPTIMIZE_MODULE" = "0" ] && module_log "- 未找到王者荣耀配置文件夹"
  else
    # 王者荣耀配置文件
    PLAYER_PREFS="$SHARED_PREFS/com.tencent.tmgp.sgame.v2.playerprefs.xml"
    # OpenGLES3Config.xml 配置文件路径
    CONFIG="$SHARED_PREFS/OpenGLES3Config.xml"
    # 更新 OpenGLES3Config.xml 配置
    echo "<?xml version='1.0'encoding='utf-8'standalone='yes'?>
<map>
    <int name=\"MemSizeForGPUSkin\"value=\"9999\"/>
    <boolean name=\"EnableGPUSkin\"value=\"false\"/>
    <boolean name=\"EnableGLES3\"value=\"false\"/>
</map>" > $CONFIG
    [ "$OPTIMIZE_MODULE" = "0" ] && module_log "- 更新王者荣耀 OpenGLES3Config.xml 配置文件"
    # 删除配置参数（修正引号嵌套）
    sed -i '/.*<int name="VulkanTryCount" value=".*" \/>/d' "$PLAYER_PREFS"
    sed -i '/.*<int name="EnableVulkan" value=".*" \/>/d' "$PLAYER_PREFS"
    sed -i '/.*<int name="EnableGLES3" value=".*" \/>/d' "$PLAYER_PREFS"
    sed -i '/.*<int name="EnableMTR" value=".*" \/>/d' "$PLAYER_PREFS"
    sed -i '/.*<int name="DisableMTR" value=".*" \/>/d' "$PLAYER_PREFS"
    sed -i '/.*<int name="sgame_ALL_HighFPS" value=".*" \/>/d' "$PLAYER_PREFS"
    sed -i '/.*<int name="EnableHWVendorOpt" value=".*" \/>/d' "$PLAYER_PREFS"
    sed -i '/.*<int name="UnityGraphicsQuality" value=".*" \/>/d' "$PLAYER_PREFS"
    sed -i '/.*<int name="EnableGPUReport" value=".*" \/>/d' "$PLAYER_PREFS"
    # 更新 VT 配置参数
    sed -i '2a \ \ \ \ <int name="VulkanTryCount" value="1" \/>' "$PLAYER_PREFS"
    sed -i '3a \ \ \ \ <int name="EnableVulkan" value="2" \/>' "$PLAYER_PREFS"
    sed -i '4a \ \ \ \ <int name="EnableGLES3" value="3" \/>' "$PLAYER_PREFS"
    sed -i '5a \ \ \ \ <int name="EnableMTR" value="1" \/>' "$PLAYER_PREFS"
    sed -i '6a \ \ \ \ <int name="DisableMTR" value="3" \/>' "$PLAYER_PREFS"
    sed -i '7a \ \ \ \ <int name="sgame_ALL_HighFPS" value="1" \/>' "$PLAYER_PREFS"
    sed -i '8a \ \ \ \ <int name="EnableHWVendorOpt" value="1" \/>' "$PLAYER_PREFS"
    sed -i '9a \ \ \ \ <int name="UnityGraphicsQuality" value="1" \/>' "$PLAYER_PREFS"
    sed -i '10a \ \ \ \ <int name="EnableGPUReport" value="2" \/>' "$PLAYER_PREFS"
    [ "$OPTIMIZE_MODULE" = "0" ] && module_log "- 更新王者荣耀配置参数"
    chmod 550 $SHARED_PREFS
    chmod 440 $PLAYER_PREFS
    [ "$OPTIMIZE_MODULE" = "0" ] && module_log "- 更新配置文件权限"
    [ "$OPTIMIZE_MODULE" = "0" ] && module_log "- 已开启王者荣耀 VT 优化"
    [ "$OPTIMIZE_MODULE" = "1" ] && module_log "已开启王者荣耀 VT 优化"
  fi
elif [ "$OPTIMIZE_WZRY" = "3" ]; then
  # 删除更改后的配置, 使用默认配置参数
  SHARED_PREFS="/data/data/com.tencent.tmgp.sgame/shared_prefs"
  if [ -d "$SHARED_PREFS" ]; then
    # 王者荣耀配置文件
    PLAYER_PREFS="$SHARED_PREFS/com.tencent.tmgp.sgame.v2.playerprefs.xml"
    O3T_PREFS="<int name=\"EnableVulkan\" value=\"3\" \/>"
    VT_PREFS="<int name=\"EnableVulkan\" value=\"2\" \/>"
    STATUS_PREFS="none"
    # 判断匹配函数，匹配函数不为0，则包含给定字符
    if [ "$(grep -c "$O3T_PREFS" "$PLAYER_PREFS")" -ne "0" ]; then
      STATUS_PREFS="O3T"
    elif [ "$(grep -c "$VT_PREFS" "$PLAYER_PREFS")" -ne "0" ]; then
      STATUS_PREFS="VT"
    fi
    if [ $STATUS_PREFS != "none" ]; then
      # 删除优化参数（修正引号嵌套）
      sed -i '/.*<int name="VulkanTryCount" value=".*" \/>/d' "$PLAYER_PREFS"
      sed -i '/.*<int name="EnableVulkan" value=".*" \/>/d' "$PLAYER_PREFS"
      sed -i '/.*<int name="EnableGLES3" value=".*" \/>/d' "$PLAYER_PREFS"
      sed -i '/.*<int name="EnableMTR" value=".*" \/>/d' "$PLAYER_PREFS"
      sed -i '/.*<int name="DisableMTR" value=".*" \/>/d' "$PLAYER_PREFS"
      sed -i '/.*<int name="sgame_ALL_HighFPS" value=".*" \/>/d' "$PLAYER_PREFS"
      sed -i '/.*<int name="EnableHWVendorOpt" value=".*" \/>/d' "$PLAYER_PREFS"
      sed -i '/.*<int name="UnityGraphicsQuality" value=".*" \/>/d' "$PLAYER_PREFS"
      sed -i '/.*<int name="EnableGPUReport" value=".*" \/>/d' "$PLAYER_PREFS"
      chmod 771 "$SHARED_PREFS"
      chmod 660 "$PLAYER_PREFS"
      module_log "已还原王者荣耀 $STATUS_PREFS 配置, 已更新 config.yaml"
    else
      module_log "未找到更改的王者荣耀 O3T/VT 配置参数, 已更新 config.yaml"
    fi
  else
    module_log "未找到王者荣耀配置文件夹, 已更新 config.yaml"
  fi
  write_config "王者优化" "0"
fi


# 关闭 ZRAM 减少性能/磁盘损耗
if [ "$OPTIMIZE_ZRAM" = "1" ]; then
  swapoff /dev/block/zram0 2>/dev/null
  swapoff /dev/block/zram1 2>/dev/null
  swapoff /dev/block/zram2 2>/dev/null
  echo "1" > /sys/block/zram0/reset
  # 配置 prop
  setprop app_memory_compression 0
  setprop debug.gralloc.enable_fb_ubwc 1
  setprop persist.sys.purgeable_assets 1
  setprop zram_enabled 0
  module_log "已禁用系统 ZRAM 压缩内存"
fi


# TCP 优化
if [ "$OPTIMIZE_TCP" = "1" ]; then
  temp_file=$(mktemp)
  echo "
net.ipv4.ip_forward = 1
net.ipv4.conf.default.forwarding = 1
net.ipv6.conf.default.forwarding = 1
net.ipv6.conf.lo.forwarding = 1
net.core.netdev_max_backlog = 100000
net.core.netdev_budget = 50000
net.core.netdev_budget_usecs = 5000
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 67108864
net.core.wmem_default = 67108864
net.core.optmem_max = 65536
net.ipv4.icmp_echo_ignore_all = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.all.rp_filter = 0
net.ipv4.tcp_keepalive_time = 8
net.ipv4.tcp_keepalive_intvl = 8
net.ipv4.tcp_keepalive_probes = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_rfc1337 = 0
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 8
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
net.ipv4.tcp_mtu_probing = 0
net.ipv4.tcp_autocorking = 0
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_frto = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.neigh.default.gc_thresh3=8192
net.ipv4.neigh.default.gc_thresh2=4096
net.ipv4.neigh.default.gc_thresh1=2048
net.ipv6.neigh.default.gc_thresh3=8192
net.ipv6.neigh.default.gc_thresh2=4096
net.ipv6.neigh.default.gc_thresh1=2048
net.ipv4.tcp_max_syn_backlog = 262144
net.netfilter.nf_conntrack_max = 262144
" > "$temp_file"
  # 给予 sysctl.conf 配置文件权限
  chmod 777 "$temp_file"
  # 启用自定义配置文件
  sysctl -p "$temp_file" >/dev/null 2>&1
  # 启用 ip route 配置
  ip route | while read -r config; do
    ip route change "$config" initcwnd 20;
  done
  # 删除 wlan_logs 网络日志
  rm -rf /data/vendor/wlan_logs
  module_log "已开启 TCP 网络优化"
  # 删除缓存文件
  rm -f "$temp_file"
fi


# 快充优化
if [ "$OPTIMIZE_CHARGE" = "1" ]; then
  chmod 755 /sys/class/power_supply/*/*
  chmod 755 /sys/module/qpnp_smbcharger/*/*
  chmod 755 /sys/module/dwc3_msm/*/*
  chmod 755 /sys/module/phy_msm_usb/*/*
  echo "1" > /sys/kernel/fast_charge/force_fast_charge
  echo "1" > /sys/kernel/fast_charge/failsafe
  echo "1" > /sys/class/power_supply/battery/allow_hvdcp3
  echo "0" > /sys/class/power_supply/battery/restricted_charging
  echo "0" > /sys/class/power_supply/battery/system_temp_level
  echo "0" > /sys/class/power_supply/battery/input_current_limited
  echo "1" > /sys/class/power_supply/battery/subsystem/usb/pd_allowed
  echo "1" > /sys/class/power_supply/battery/input_current_settled
  echo "0" > /sys/class/power_supply/battery/input_suspend
  echo "1" > /sys/class/power_supply/battery/battery_charging_enabled
  echo "1" > /sys/class/power_supply/usb/boost_current
  echo "100" >/sys/class/power_supply/bms/temp_cool
  echo "600" >/sys/class/power_supply/bms/temp_warm
  echo "30000" > /sys/module/qpnp_smbcharger/parameters/default_hvdcp_icl_ma
  echo "30000" > /sys/module/qpnp_smbcharger/parameters/default_dcp_icl_ma
  echo "30000" > /sys/module/qpnp_smbcharger/parameters/default_hvdcp3_icl_ma
  echo "30000" > /sys/module/dwc3_msm/parameters/dcp_max_current
  echo "30000" > /sys/module/dwc3_msm/parameters/hvdcp_max_current
  echo "30000" > /sys/module/phy_msm_usb/parameters/dcp_max_current
  echo "30000" > /sys/module/phy_msm_usb/parameters/hvdcp_max_current
  echo "30000" > /sys/module/phy_msm_usb/parameters/lpm_disconnect_thresh
  echo "12000000" > /sys/class/power_supply/battery/fast_charge_current
  echo "12000000" > /sys/class/power_supply/battery/thermal_input_current
  echo "30000000" > /sys/class/power_supply/dc/current_max
  echo "30000000" > /sys/class/power_supply/main/current_max
  echo "30000000" > /sys/class/power_supply/parallel/current_max
  echo "30000000" > /sys/class/power_supply/pc_port/current_max
  echo "30000000" > /sys/class/power_supply/qpnp-dc/current_max
  echo "30000000" > /sys/class/power_supply/battery/current_max
  echo "30000000" > /sys/class/power_supply/battery/input_current_max
  echo "30000000" > /sys/class/power_supply/usb/current_max
  echo "30000000" > /sys/class/power_supply/usb/hw_current_max
  echo "30000000" > /sys/class/power_supply/usb/pd_current_max
  echo "30000000" > /sys/class/power_supply/usb/ctm_current_max
  echo "30000000" > /sys/class/power_supply/usb/sdp_current_max
  echo "30100000" > /sys/class/power_supply/main/constant_charge_current_max
  echo "30100000" > /sys/class/power_supply/parallel/constant_charge_current_max
  echo "30100000" > /sys/class/power_supply/battery/constant_charge_current_max
  echo "31000000" > /sys/class/qcom-battery/restricted_current
  # 开启 KVDCP 快充
  setprop persist.hvdcp.allow_opti 1
  module_log "已开启快充优化"
fi


# 移除小米更新验证
# 获取用户配置, 判断配置是否为1
if [ "$OPTIMIZE_MIUI_OTA" = "1" ]; then
  # 查找 /*/etc/device_features 文件夹及其子文件夹下的所有 *.xml 文件
  times=0
  for dir in /*/etc/device_features; do
    # 判断是否是文件夹
    if [ -d "$dir" ]; then
      # 操作文件夹下的文件
      for file in "$dir"/*.xml; do
        # 判断是否为 OTA 配置文件
        if [ -f "$file" ] && grep -q 'support_ota_validate' "$file"; then
          # 创建相关的文件夹
          mkdir -p "${MODDIR}${dir}"
          # 复制文件到目标目录
          cp -f "$file" "${MODDIR}${dir}/"
          # 修改 OTA 配置文件中的内容
          sed -i 's/"support_ota_validate">true</"support_ota_validate">false</g' "${MODDIR}${dir}/$(basename "$file")"
          times=$(( times + 1 ))
        fi
      done
    fi
  done
  if [ "$times" -gt 0 ]; then
    module_log "已移除小米更新验证"
  else
    module_log "未找到小米更新 OTA 配置文件"
  fi
fi


# Ciallo～ (∠・ω< )⌒☆
module_log "模块 service.sh 已结束"
module_log "Ciallo～ (∠・ω< )⌒☆"
