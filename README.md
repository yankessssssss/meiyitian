# 每一天

一个个人使用的离线 Android 手账。书架里有日记、记账和时间钟，也可以添加自定义书本。日记支持文字、相册和拍照，记账与计时支持日、月、年统计。书房背景和天气可以自定义。

## 安装与更新

应用 ID 为 cn.meiyitian.shelf，需要 Android 6.0 及以上和支持当前页面功能的 Android System WebView。在手机的文件管理器里打开 APK 安装。有旧版时，请用同签名的新版本直接覆盖安装。正式版本的私钥请离线保管。自行生成的签名用于首次安装或更新自己同签名的版本。

## 备份与恢复

1. 在书架底部打开「备份与恢复」，点「导出备份」，把 ZIP 保存到「下载」等位置。
2. 换机时把 ZIP 传到新手机，安装应用，选择「从备份恢复」。
3. 核对书本、记录和照片数量，再确认替换。恢复后书架会重新载入。

备份是普通 ZIP，包含个人记录和照片，建议保存在自己控制的位置。恢复会替换原数据，导入前可以先导出当前记录。卸载或清除存储空间会删除应用私有数据，已经保存在应用外的备份仍可用于恢复。

备份格式第 1 版用 manifest.json 标识格式，journal.json 存书本、记录、分类、主题和计时状态，photos/ 存被记录引用的 JPEG。恢复会检查结构和校验值。当前单份备份的解包数据上限为 1 GiB。

## 从源码构建

使用 Windows PowerShell、JDK 17 或更新版本，以及 Android SDK Platform 35 和 Build Tools 35.0.1。设置 ANDROID_SDK_ROOT、JAVA_HOME 和本次使用的 MEIYITIAN_KEY_PASSWORD 环境变量。

首次为自己的安装构建时，可用以下命令创建自己的密钥：

    ./build.ps1 -CreateSigningKey

默认输出在 build/meiyitian.apk。后续构建使用原密钥并递增 app/AndroidManifest.xml 里的 versionCode。可以用 -KeyStore 和 -KeyAlias 指定签名，用 -ExpectedCertificateSha256 检查是否与旧版证书一致。

## 代码与素材

- app/src/ 放 Android 容器、拍照、文件选择和 ZIP 备份。
- app/assets/ 放离线界面、样式与随应用打包的素材。
- 玻璃屋书房和银杏窗边为项目中生成的配图。

## 许可证

本源码包供发布前审阅。仓库所有者确认许可证后，再把对应的 LICENSE 加入公开仓库。
