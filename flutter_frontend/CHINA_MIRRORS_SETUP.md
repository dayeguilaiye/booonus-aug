# Flutter 国内镜像源配置指南

## 问题描述
在中国大陆网络环境下，Flutter项目编译时经常卡在 `Running Gradle task 'assembleDebug'` 步骤，这是因为需要从国外服务器下载依赖包导致的网络问题。

## 解决方案

### 1. 已配置的镜像源

#### Gradle 依赖镜像源
采用双重配置策略确保兼容性：

1. **settings.gradle.kts** - 通过 `dependencyResolutionManagement` 和 `pluginManagement` 配置镜像源
2. **build.gradle.kts** - 通过 `allprojects` 配置镜像源（兼容Flutter插件）

配置的阿里云镜像源：
- `https://maven.aliyun.com/repository/google`
- `https://maven.aliyun.com/repository/central`
- `https://maven.aliyun.com/repository/gradle-plugin`
- `https://maven.aliyun.com/repository/public`

#### Gradle Wrapper 镜像源
已在 `android/gradle/wrapper/gradle-wrapper.properties` 中配置了阿里云镜像：
- `https://mirrors.aliyun.com/macports/distfiles/gradle/gradle-8.12-all.zip`

#### Flutter 镜像源
已在 `run.sh` 和 `setup_china_mirrors.sh` 中配置了Flutter中国镜像：
- `PUB_HOSTED_URL=https://pub.flutter-io.cn`
- `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`

### 2. 使用方法

#### 方法一：使用配置脚本（推荐）
```bash
# 进入项目目录
cd flutter_frontend

# 运行配置脚本
chmod +x setup_china_mirrors.sh
source ./setup_china_mirrors.sh

# 编译运行
flutter run
```

#### 方法二：使用运行脚本
```bash
# 进入项目目录
cd flutter_frontend

# 直接运行（已包含镜像源配置）
chmod +x run.sh
./run.sh
```

#### 方法三：手动设置环境变量
```bash
# 设置环境变量
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 清理缓存
flutter clean

# 获取依赖
flutter pub get

# 编译运行
flutter run
```

### 3. 验证配置

运行以下命令验证镜像源是否生效：
```bash
flutter doctor -v
```

### 4. 常见问题

#### 如果仍然很慢
1. 尝试清理所有缓存：
   ```bash
   flutter clean
   cd android && ./gradlew clean && cd ..
   flutter pub get
   ```

2. 如果遇到 "Build was configured to prefer settings repositories" 错误：
   - 已调整为 `PREFER_SETTINGS` 模式，允许项目级仓库配置
   - 使用双重配置策略确保Flutter插件兼容性
   - 镜像源优先，官方源作为备用

2. 检查网络连接，确保可以访问镜像源

3. 如果使用代理，确保代理配置正确

#### NDK 相关错误
如果遇到 "NDK did not have a source.properties file" 错误：

1. **临时解决方案**（推荐）：
   - 已在 `android/app/build.gradle.kts` 中注释了 `ndkVersion`
   - 大多数Flutter项目不需要NDK，可以正常编译

2. **完整解决方案**：
   ```bash
   # 使用Android Studio SDK Manager重新安装NDK
   # 或使用命令行：
   sdkmanager --install "ndk;25.1.8937393"
   ```

3. **检查NDK状态**：
   ```bash
   chmod +x fix_ndk_issue.sh
   ./fix_ndk_issue.sh
   ```

#### 其他镜像源选择
如果当前镜像源不稳定，可以尝试其他镜像：
- 腾讯云镜像：`https://mirrors.cloud.tencent.com/`
- 华为云镜像：`https://mirrors.huaweicloud.com/`

## 注意事项
- 首次编译可能仍需要较长时间，因为需要下载大量依赖
- 建议在稳定的网络环境下进行首次编译
- 配置完成后，后续编译速度会显著提升
