# Radix · 多进制工具（iOS）v2.0.2

进制转换、混合进制四则运算、机器码制、字符编码的 iOS App。SwiftUI 编写，零第三方依赖，自实现 BigInt，支持超大整数与负数。GitHub: Andy-FJC。保留所有权利。

底部五个页签：

**① 转换**
- 2 – 36 进制全部列出，输入进制直接点数字选（标签带字母：二进制(B)、八进制(O)、十进制(D)、十六进制(H)，其余用基数如「十二进制(12)」）
- 结果一次性列出 2 – 36 全部进制，点任意行复制

**② 运算**
- A、B **各自独立选进制**（可 二进制 + 十六进制 直接算，无需先转换），选 + − × ÷ 实时出结果
- 结果按 2/8/10/16 + 一个可切换的任意进制并列显示，点行复制
- 支持负数（± 键）、超大整数、整数除法（向零截断，余数单列）

**③ 码制**
- 真值 / 机器数 / 原码 / 反码 / 补码，8 / 16 / 32 位
- 输入真值看五种表示；也能从任意一种码反查真值

**④ 字符**
- ASCII 全表（0–127，可搜索/筛选，含控制字符名称）
- 汉字编码：区位码 ↔ 国标码 ↔ 机内码互转，点阵字模存储容量计算（16/24/32/48 点阵）
- Unicode / UTF-8：字符 ↔ 码点互查，UTF-8 字节序列与编码规则

**⑤ 关于**
- 版本号、GitHub（Andy-FJC）、保留所有权利

**内置键盘**
- 转换/运算页不弹出系统键盘；数字键只保留当前进制合法的，其余变灰
- 进制 ≥ 11 自动长出字母键，最多 A–Z（36 进制）；⌫ 退格、C 清空、± 换符号

---

## 编译成 IPA（用 GitHub 的 macOS 机器，不需要自己有 Mac）

整个过程约 10 分钟，其中编译只占 2–3 分钟。**公开仓库的 Actions 完全免费。**

### 第 1 步：注册 / 登录 GitHub

浏览器打开 `github.com`，没有账号就用邮箱注册一个（免费）。

### 第 2 步：新建仓库

1. 打开 `github.com/new`
2. **Repository name** 填 `radix-ios`
3. 可见性选 **Public**（公开仓库不消耗 Actions 额度）
4. 下面的 "Add a README file" 等选项**一个都不要勾**
5. 点绿色按钮 **Create repository**

### 第 3 步：上传文件

1. 把 `radix-ios.zip` 解压，得到 `radix-ios` 文件夹
2. **进入 `radix-ios` 文件夹**，按 `Ctrl + A` 全选里面的所有内容
   - 应该看到：`.github`、`Radix`、`project.yml`、`README.md`
3. 新建的仓库页面上有一行链接 **"uploading an existing file"**，点它
4. 把选中的内容**拖进**网页中间的虚线框
5. 等文件列表加载完，页面底部点绿色 **Commit changes**

> 如果 `.github` 文件夹没有上传成功（仓库首页看不到它），看下面的「备用：手动创建 workflow」。

### 第 4 步：跑编译

1. 点仓库顶部的 **Actions** 标签
2. 左边栏应该能看到 **Build Radix IPA**，点它
3. 右边有灰色提示条，点 **Run workflow** → 再点绿色 **Run workflow**
4. 刷新页面，会出现一条黄色圆点正在跑的记录，点进去
5. 展开 **Build (no signing)** 步骤，能看到 `xcodebuild` 的输出在滚动

**大约 2–3 分钟后**，整个记录变成绿色对勾。

### 第 5 步：下载 IPA

1. 在刚才那条运行记录的页面，**滚到最底部**
2. 有一个 **Artifacts** 区域，点 **Radix-unsigned-ipa**
3. 下载得到一个 `.zip`，解压里面就是 **`Radix-unsigned.ipa`**（约 1–2 MB）

### 第 6 步：签名安装到手机

这个 IPA 是**未签名**的，必须用你的证书签一次才能装：

1. 手机插线、解锁、点信任
2. 电脑上打开 AltServer，右键托盘图标 → **Sideload .ipa**
3. 选 `Radix-unsigned.ipa`
4. 输 Apple ID（会记住上次的）→ 等 30 秒
5. 手机上：设置 → 通用 → VPN 与设备管理 → 信任证书

装好后桌面就是那个双箭头图标，名字叫 **Radix**。

---

## 备用：手动创建 workflow

如果第 3 步 `.github` 文件夹没传上去，页面顶部的 Actions 标签会显示"没有 workflow"，那就手动补：

1. 仓库首页点 **Add file** → **Create new file**
2. 文件名输入框里粘贴这一整串（斜杠会自动建目录）：
   ```
   .github/workflows/build.yml
   ```
3. 打开本地的 `.github/workflows/build.yml`，把内容全选复制，粘进网页编辑框
4. 页面底部点 **Commit changes**

然后再回到第 4 步。

---

## 常见问题

**编译报错 `No such module 'SwiftUI'`**
说明 `-sdk iphoneos` 没生效。检查 `.github/workflows/build.yml` 是否被改动过。

**编译报错 `xcodegen: command not found`**
`brew install xcodegen` 那一步失败了，重新跑一次 workflow 即可（偶发网络问题）。

**Artifacts 里没有东西**
说明 `Package into IPA` 那一步失败了，展开日志能看到具体原因，通常是 `Radix.app` 路径不对 —— 日志里会打印 `build/Build/Products` 下的实际目录。

**装上去闪退**
通常是签名时 Bundle ID 冲突。在 AltServer 里换一个 Apple ID，或者用 Sideloadly 改一下 Bundle ID 再签。

**7 天后打不开**
免费 Apple ID 的证书有效期就是 7 天。到时候用同一个 IPA 重新 Sideload 一次，30 秒，数据不丢。

---

## 本地修改后重新编译

改完 Swift 代码，`git push` 上去，Actions 会自动重新跑一遍（workflow 里配了 `push` 触发）。不用手动点。
