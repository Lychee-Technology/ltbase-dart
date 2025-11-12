# LTBase Dart Client

一个用于测试 LTBase Notes API 的命令行工具，使用 Dart 实现，支持 Ed25519 签名认证。

## 功能特性

- ✅ 支持所有 Notes API 端点（创建、读取、更新、删除、列表）
- ✅ 自动处理 Ed25519 签名认证
- ✅ 健康检查接口（DeepPing）
- ✅ 详细的请求/响应日志（`--verbose` 模式）
- ✅ 支持从文件读取数据（图片、音频）
- ✅ 使用 Dart 标准库实现（最小化第三方依赖）

## 快速开始

### 安装依赖

```bash
dart pub get
```

### 基本用法

```bash
# 显示帮助
dart run bin/ltbase_client.dart --help

# 健康检查
dart run bin/ltbase_client.dart \
  --access-key-id "AK_PSnulf1ATHSlQ5VgzV9CIg" \
  --access-secret "SK_MC4CAQAwBQYDK2VwBCIEIPro6WPVBiMoFCjDT5U8NjqJeIsPcA4PNLOta8DLnjfE" \
  deepping --echo "hello"

# 创建文本笔记
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  create-note --user-id "user123" --type text --data "测试笔记"

# 列出笔记
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  list-notes --page 1 --items-per-page 10
```

### 编译为可执行文件

```bash
dart compile exe bin/ltbase_client.dart -o ltbase
./ltbase --help
```

## 命令列表

| 命令                    | 说明                                |
| ----------------------- | ----------------------------------- |
| `deepping`              | 健康检查，验证认证和服务器连接      |
| `create-note`           | 创建新笔记（支持 text/audio/image） |
| `get-note <NOTE_ID>`    | 获取指定笔记的详细信息              |
| `list-notes`            | 列出笔记（支持分页和过滤）          |
| `update-note <NOTE_ID>` | 更新笔记摘要                        |
| `delete-note <NOTE_ID>` | 删除指定笔记                        |

## 全局参数

| 参数              | 必需 | 默认值                    | 说明                           |
| ----------------- | ---- | ------------------------- | ------------------------------ |
| `--base-url`      | 否   | `https://api.example.com` | API 基础地址                   |
| `--access-key-id` | 是   | -                         | Access Key ID (格式: `AK_xxx`) |
| `--access-secret` | 是   | -                         | Access Secret (格式: `SK_xxx`) |
| `--verbose`, `-v` | 否   | `false`                   | 显示详细输出                   |
| `--help`, `-h`    | 否   | `false`                   | 显示帮助信息                   |

## 详细文档

- [API 文档](docs/api.cn.md) - LTBase Notes API 规范
- [认证文档](docs/auth.cn.md) - Ed25519 签名认证规范
- [CLI 文档](docs/cli.cn.md) - 命令行工具完整使用指南

## 项目结构

```
├── bin/
│   └── ltbase_client.dart       # 主入口，命令行解析
├── lib/
│   ├── auth/
│   │   └── signer.dart          # Ed25519 签名生成器
│   ├── api/
│   │   └── client.dart          # HTTP 客户端（基于 dart:io）
│   └── commands/
│       └── command_handler.dart # 命令处理器
├── docs/
│   ├── api.cn.md                # API 文档
│   ├── auth.cn.md               # 认证规范
│   └── cli.cn.md                # CLI 使用指南
├── test/
│   └── ltbase_client_test.dart  # 测试文件
├── pubspec.yaml                 # 依赖配置
└── README.md                    # 本文件
```

## 依赖库

项目尽量使用 Dart 标准库，仅在必要时使用第三方库：

- **args** (^2.4.2) - Dart 官方命令行参数解析库
- **crypto** (^3.0.3) - Dart 官方加密库，用于 SHA256/SHA512 哈希
- **内置 Ed25519 实现** - 从 `package:cryptography` 提取的纯 Dart 代码，无需额外依赖

## 技术实现

### 认证流程

1. 解析 Access Secret 中的 Ed25519 私钥（DER 格式）
2. 构造签名字符串（包含 HTTP 方法、URL、查询参数、请求体哈希、时间戳、Nonce）
3. 使用 Ed25519 算法对签名字符串进行签名
4. 构造 Authorization header：`LtBase {Key ID}:{Signature}:{Timestamp}:{Nonce}`
5. 发送 HTTP 请求

### HTTP 客户端

使用 Dart 标准库 `dart:io` 的 `HttpClient` 实现，无需额外依赖。支持：
- GET、POST、PUT、DELETE 方法
- 自动处理 JSON 编解码
- 查询参数自动排序（用于签名）
- 详细的请求/响应日志

## 使用示例

### 1. 健康检查

```bash
dart run bin/ltbase_client.dart \
  --base-url "https://api.suremate.local:5000" \
  --access-key-id "AK_3ShK-hMMedDqjigeVv8OEjxJ4GxlkFu5l8pWrlYjeW8" \
  --access-secret "SK_MC4CAQAwBQYDK2VwBCIEIITEXquKFhk-DvZOb_BdU9Lc6DGaItQk4lZmYFQho8C_" \
  deepping --echo "test"
```

### 2. 创建笔记

```bash
# 文本笔记
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  create-note --user-id "user123" --type text --data "Hello World"

# 从文件创建图片笔记
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  create-note --user-id "user123" --type image --file "./photo.jpg"
```

### 3. 查询笔记

```bash
# 获取单个笔记
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  get-note "550e8400-e29b-41d4-a716-446655440000"

# 列出笔记（带过滤）
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  list-notes --page 1 --items-per-page 10 --summary "测试"
```

### 4. 更新和删除

```bash
# 更新笔记摘要
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  update-note "550e8400-e29b-41d4-a716-446655440000" --summary "新摘要"

# 删除笔记
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  delete-note "550e8400-e29b-41d4-a716-446655440000"
```

### 5. 详细输出模式

使用 `--verbose` 查看完整的请求和响应：

```bash
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  --verbose \
  list-notes
```

输出示例：
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Request: GET https://api.example.com/api/v1/notes?page=1&items_per_page=20
Authorization: LtBase xxx:yyy:1699999999999:zzz
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Response Status: 200
Response Body: {"notes":[...],"page":1,"total":10}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Found 10 note(s)
...
```

## 常见问题

**Q: 如何获取 Access Key 和 Access Secret？**

A: 请联系系统管理员为您的 Tenant 创建访问凭证。

**Q: 签名验证失败怎么办？**

A: 请确保：
1. Access Key ID 和 Access Secret 格式正确
2. 系统时间准确（时间戳验证有5分钟窗口）
3. 使用 `--verbose` 选项查看详细信息进行调试

**Q: 如何简化命令行输入？**

A: 可以使用 shell 别名：

```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
alias ltbase='dart run bin/ltbase_client.dart --access-key-id "AK_xxx" --access-secret "SK_xxx"'

# 使用
ltbase list-notes
```

## 开发

### 运行测试

```bash
dart test
```

### 代码分析

```bash
dart analyze
```

### 格式化代码

```bash
dart format .
```

## License

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
