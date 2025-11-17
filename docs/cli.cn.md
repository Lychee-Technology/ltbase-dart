# 命令行和参数

## 概述

`ltbase_client` 是一个用于测试 LTBase Notes API 的命令行工具。它支持所有 API 端点，并自动处理 Ed25519 签名认证。

## 安装和运行

### 安装依赖

```bash
dart pub get
```

### 运行方式

```bash
# 直接运行
dart run bin/ltbase_client.dart [OPTIONS] <COMMAND>

# 或编译后运行
dart compile exe bin/ltbase_client.dart -o ltbase
./ltbase [OPTIONS] <COMMAND>
```

## 全局参数

所有命令都支持以下全局参数：

| 参数 | 必需 | 默认值 | 说明 |
|------|------|--------|------|
| `--base-url` | 否 | `https://api.example.com` | API 基础地址 |
| `--access-key-id` | 是 | - | Access Key ID (格式: `AK_xxx`) |
| `--access-secret` | 是 | - | Access Secret (格式: `SK_xxx`) |
| `--verbose`, `-v` | 否 | `false` | 显示详细输出（包括请求/响应详情） |
| `--help`, `-h` | 否 | `false` | 显示帮助信息 |

## 命令

### 1. deepping - 健康检查

健康检查接口，验证认证和服务器连接。

**用法:**
```bash
ltbase --access-key-id <AK> --access-secret <SK> deepping [OPTIONS]
```

**选项:**
- `--echo <STRING>` - 要回显的字符串（可选）

**示例:**
```bash
dart run bin/ltbase_client.dart \
  --access-key-id "AK_PSnulf1ATHSlQ5VgzV9CIg" \
  --access-secret "SK_MC4CAQAwBQYDK2VwBCIEIPro6WPVBiMoFCjDT5U8NjqJeIsPcA4PNLOta8DLnjfE" \
  deepping --echo "hello world"
```

**输出示例:**
```
✓ DeepPing successful
  Status: ok
  Echo: hello world
  Timestamp: 1699999999999
```

### 2. create-note - 创建笔记

创建一个新的笔记。

**用法:**
```bash
ltbase --access-key-id <AK> --access-secret <SK> create-note [OPTIONS]
```

**选项:**
- `--owner-id <ID>` - 创建者用户ID（必需）
- `--type <TYPE>` - 笔记类型：`text`|`audio`|`image`（必需）
- `--data <DATA>` - 笔记内容数据
- `--file <PATH>` - 从文件读取数据（与 `--data` 二选一）

**示例:**
```bash
# 创建文本笔记
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  create-note --owner-id "user123" --type text --data "这是一条测试笔记"

# 从文件创建图片笔记
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  create-note --owner-id "user123" --type image --file "./photo.jpg"
```

**输出示例:**
```
✓ Note created successfully
  Note ID: 550e8400-e29b-41d4-a716-446655440000
  Type: text
  Created at: 1699999999999
```

### 3. get-note - 获取笔记

根据 ID 获取单个笔记的详细信息。

**用法:**
```bash
ltbase --access-key-id <AK> --access-secret <SK> get-note <NOTE_ID>
```

**参数:**
- `<NOTE_ID>` - 笔记的 UUID（必需）

**示例:**
```bash
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  get-note "550e8400-e29b-41d4-a716-446655440000"
```

**输出示例:**
```
✓ Note retrieved successfully
{
  "note_id": "550e8400-e29b-41d4-a716-446655440000",
  "created_by": "user123",
  "created_at": 1699999999999,
  "updated_at": 1699999999999,
  "raw": {
    "type": "text",
    "data": "这是一条测试笔记"
  },
  "models": [],
  "summary": "测试笔记"
}
```

### 4. list-notes - 列出笔记

列出笔记，支持分页和过滤。

**用法:**
```bash
ltbase --access-key-id <AK> --access-secret <SK> list-notes [OPTIONS]
```

**选项:**
- `--page <NUM>` - 页码（默认: 1）
- `--items-per-page <NUM>` - 每页条目数（默认: 20）
- `--schema-name <NAME>` - 按模式名称精确匹配（可选）
- `--summary <TEXT>` - 按摘要内容包含匹配（可选）

**示例:**
```bash
# 列出第一页（默认）
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  list-notes

# 带过滤条件
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  list-notes --owner-id abc123 --page 2 --items-per-page 10 --summary "测试"
```

**输出示例:**
```
✓ Found 2 note(s)
{
  "notes": [
    {
      "note_id": "550e8400-e29b-41d4-a716-446655440000",
      "created_by": "user123",
      "summary": "测试笔记1"
    },
    {
      "note_id": "550e8400-e29b-41d4-a716-446655440001",
      "created_by": "user123",
      "summary": "测试笔记2"
    }
  ],
  "page": 1,
  "total": 2
}
```

### 5. update-note - 更新笔记摘要

更新笔记的摘要字段（其他字段不可变）。

**用法:**
```bash
ltbase --access-key-id <AK> --access-secret <SK> update-note <NOTE_ID> [OPTIONS]
```

**参数:**
- `<NOTE_ID>` - 笔记的 UUID（必需）

**选项:**
- `--summary <TEXT>` - 新的摘要内容（必需）

**示例:**
```bash
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  update-note "550e8400-e29b-41d4-a716-446655440000" \
  --summary "更新后的摘要内容"
```

**输出示例:**
```
✓ Note summary updated successfully
  Note ID: 550e8400-e29b-41d4-a716-446655440000
  New summary: 更新后的摘要内容
```

### 6. delete-note - 删除笔记

删除指定的笔记。

**用法:**
```bash
ltbase --access-key-id <AK> --access-secret <SK> delete-note <NOTE_ID>
```

**参数:**
- `<NOTE_ID>` - 笔记的 UUID（必需）

**示例:**
```bash
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  delete-note "550e8400-e29b-41d4-a716-446655440000"
```

**输出示例:**
```
✓ Note deleted successfully
  Note ID: 550e8400-e29b-41d4-a716-446655440000
```

## 详细输出模式

使用 `--verbose` 或 `-v` 选项可以查看详细的请求和响应信息，包括：
- 完整的请求 URL
- Authorization header（包含签名）
- 请求体内容
- 响应状态码
- 响应体内容

**示例:**
```bash
dart run bin/ltbase_client.dart \
  --access-key-id "AK_xxx" \
  --access-secret "SK_xxx" \
  --verbose \
  deepping --echo "test"
```

**输出:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Request: GET https://api.example.com/api/v1/deepping?echo=test
Authorization: LtBase PSnulf1ATHSlQ5VgzV9CIg:abc123...:1699999999999:xyz789
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Response Status: 200
Response Body: {"status":"ok","echo":"test","timestamp":1699999999999}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ DeepPing successful
  Status: ok
  Echo: test
  Timestamp: 1699999999999
```

## 技术实现

### 依赖库

- `args: ^2.4.2` - 命令行参数解析
- `crypto: ^3.0.3` - SHA256/SHA512 哈希计算
- `内置 Ed25519 实现` - 从 `package:cryptography` 提取的纯 Dart 实现

### 认证流程

1. 解析 Access Secret 中的 Ed25519 私钥
2. 构造签名字符串（按规范，包含 HTTP 方法、URL、查询参数、请求体哈希、时间戳、Nonce）
3. 使用 Ed25519 算法对签名字符串进行签名
4. 构造 Authorization header：`LtBase {Access Key ID}:{Signature}:{Timestamp}:{Nonce}`
5. 发送 HTTP 请求

### 项目结构

```
bin/
  └── ltbase_client.dart       # 主入口，命令行解析
lib/
  ├── auth/
  │   └── signer.dart          # 签名生成器
  ├── api/
  │   └── client.dart          # HTTP 客户端
  └── commands/
      └── command_handler.dart # 命令处理器
docs/
  ├── api.cn.md                # API 文档
  ├── auth.cn.md               # 认证规范
  └── cli.cn.md                # CLI 文档（本文件）
```

## 常见问题

### Q: 如何获取 Access Key 和 Access Secret？

A: 请联系系统管理员为您的 Tenant 创建访问凭证。

### Q: 签名验证失败怎么办？

A: 请确保：
1. Access Key ID 和 Access Secret 格式正确
2. 系统时间准确（时间戳验证有5分钟窗口）
3. 使用 `--verbose` 选项查看详细的请求信息进行调试

### Q: 如何处理大文件？

A: 对于音频和图片文件，程序会自动将文件内容编码为 base64。请注意 API 限制请求体大小不超过 6MB。

### Q: 可以保存配置避免每次输入凭证吗？

A: 当前版本需要每次提供凭证。您可以使用 shell 别名或脚本来简化：

```bash
# 在 ~/.bashrc 或 ~/.zshrc 中添加
alias ltbase='dart run bin/ltbase_client.dart --access-key-id "AK_xxx" --access-secret "SK_xxx"'

# 然后就可以简化命令
ltbase list-notes
