<div align="right">
  Language:
  <a title="Chinese" href="./README.md">🇨🇳</a>
  🇺🇸
</div>

# All-In-One / System Deep Optimization Module
> All-In-One is a universal module for optimizing system performance.

![GitHub Release](https://img.shields.io/github/v/release/JustLikeCheese/Magisk_All-In-One)
[![License](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

## Module Features
The module integrates various optimization features including CPU optimization / automatic CPU frequency control / GPU optimization / storage read-write speed enhancement, etc. For details, please check the system.prop and service.sh files.

## Configuration
Module configuration is located at:  
`/storage/emulated/0/Android/config.yaml`  
Module logs can be found at:  
`/storage/emulated/0/Android/config.yaml.log`  
After modifying configurations, either reboot your device or click the "Execute" button for All-In-One module in Magisk Manager.

## Planned Features
- [ ] Preserve configurations during module updates
- [ ] Develop management app

## Frequently Asked Questions

### Q: Will this module cause any negative optimization?
A: No. The module only optimizes the system during boot, such as disabling unnecessary system logging.

### Q: Which devices are compatible?
A: This is a universal Android optimization module compatible with all devices.

### Q: How to install the module?
A: Click the [Release](https://github.com/JustLikeCheese/Magisk_All-In-One/releases/latest) button on the right, find **All-In-One.zip**, download it and install via Magisk Manager. For beta versions, you can directly click the **Download ZIP** button above.

### Q: Do configuration changes take effect immediately?
A: No. You need to either reboot your device or click the "Execute" button in Magisk Manager. The All-In-One module doesn't continuously monitor configuration changes like the Uperf module does.

### Q: How to enable thermal control removal?
A: Using [MT Manager](https://mt2.cn/download/), open the module zip file, edit `customize.sh`, remove the `#` before `unzip -o "$ZIPFILE" 'RESOURCES/system/*' -d $MODPATH >&2` (line 2), save changes, then install the modified module via Magisk Manager.

### Q: Can I modify this module?
A: Sure, but you must comply with the AGPLv3 license.

### Q: Can I sell this module?
A: All-In-One is free and open-source. If you insist on selling it, please refer to [How to Sell All-In-One Module](https://www.baidu.com/s?ie=utf-8&wd=%E6%88%B7%E5%8F%A3%E6%9C%AC%E5%B0%B1%E6%88%91%E4%B8%80%E4%B8%AA%E4%BA%BA%E6%80%8E%E4%B9%88%E5%8A%9E).