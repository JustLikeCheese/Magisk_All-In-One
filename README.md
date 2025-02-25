<div align="right">
  语言:
  🇨🇳
  <a title="英语" href="./README.en.md">🇺🇸</a>
</div>

# All-In-One / System deep optimization module
> All-In-One 是一个通用的用于优化系统性能的模块。

![GitHub Release](https://img.shields.io/github/v/release/JustLikeCheese/Magisk_All-In-One)
[![License](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

## 模块功能 / Function
模块集成了大部分优化功能，CPU 优化 / CPU 自动调控 / GPU 优化 / 提升存储空间读写速度等功能。详细可自行查看 system.prop 文件以及 service.sh 文件。

## 模块配置 / Configuration
模块配置在 `/storage/emulated/0/Android/config.yaml` 文件中。  
模块日志在 `/storage/emulated/0/Android/config.yaml.log` 文件中。  
修改配置之后，重启系统即可生效，或者进入 Magisk 管理器，点击 All-In-One 模块的执行按钮。

## 待实现功能 / Implementions
- [x] 实现模块更新保留配置
- [ ] 实现管理器 App

## 常见问题 / Q & A

### Q: 模块会不会对性能造成什么负优化啊？
A: 不会，模块只会在开机的时候对系统进行优化。例如：关闭一些没用的系统日志。

### Q: 模块适用于哪些机型？
A: 模块是一个通用的安卓优化模块，适用于所有机型。

### Q: 模块怎么下载安装？
A: 点击右侧的 [Release]([GitHub](https://github.com/JustLikeCheese/Magisk_All-In-One/releases/latest)) 按钮，找到 **All-In-One.zip** 文件，下载完后在 Magisk 管理器中安装刚刚下载的模块即可。如果你想体验测试版的模块可以直接点击上方的 **Download ZIP** 按钮下载。

### Q: 模块修改配置后是立即生效吗？
A: 不是，你需要手动重启或者是点击 **Magisk** 管理器中的 **执行** 按钮。因为 **All-In-One** 模块并不会像 **Uperf** 模块那样，写个循环一直在后台监听配置文件是否发生变化。

### Q: 我觉得温控没什么用，如何开启模块的删除温控功能？
A: 打开 [**MT 管理器**](https://mt2.cn/download/)，找到下载好的模块并打开，编辑其中的 **customize.sh** 文件，将第二行的 `# unzip -o "$ZIPFILE" 'RESOURCES/system/*' -d $MODPATH >&2` 前的 `#` 去掉，点击保存。然后打开 **Magisk** 管理器，安装修改过的模块即可

### Q: 我可以修改这个模块吗？
A: 可以的，但是必须遵守 [**AGPLv3**](https://www.gnu.org/licenses/agpl-3.0) 协议。

### Q: 我可以贩卖这个模块吗？
A: `All-In-One` 模块是免费且开源的。如果你非要贩卖可以参考这个链接 [怎么贩卖 All-In-One 模块](https://www.baidu.com/s?ie=utf-8&wd=%E6%88%B7%E5%8F%A3%E6%9C%AC%E5%B0%B1%E6%88%91%E4%B8%80%E4%B8%AA%E4%BA%BA%E6%80%8E%E4%B9%88%E5%8A%9E)。


