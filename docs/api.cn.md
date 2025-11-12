# Notes API

## Authorization Header

`Authorization`

请参考 [Authorization](https://gist.github.com/iceboundrock/20ba679265ed2e912421c4b898d3efd8) .

## Notes Model

```json
{
    "note_id": "<uuid>",
    "created_by": "<user_id>",
    "created_at": <epoch millisecond>,
    "updated_at": <epoch millisecond>,
    "raw": {
        "type": "text|audio|image",
        "data": "text or url of audio/image file"
    },
    "models": [
        {
            "type": "<model/schema name>",
            "data": {
                ...
            }
        },...
    ] ,
    "summary": "<summary>"
}
```

## Create Note

创建一个Note

### URL

`POST /api/v1/notes`

### Body

Length of body must be less than 6MB.

```json
{
    "created_by": "<user_id>",
    "type": "text|audio|image",
    "data": "text | data url | raw base64 string"
}
```


## Delete Note

删除一个Note

`DELETE /api/ai/v1/notes/{note_id}`

## Update Note Summary

只能更新note的summary,其他字段不可变

`PUT /api/ai/v1/notes/{note_id}`

### Body

```json
{
    "summary": "<updated summary>"
}
```

## Get Note

`GET /api/ai/v1/notes/{note_id}`


## List Notes

List notes, results are ordered by created time.

`GET /api/v1/notes`

### Parameters

Parameters are pass

* `page`
    * optional, number, default: 1
* `items_per_page`
    * optional, number, default: 20
* `schema_name`
    * optional, text, exact match
* `summary`
    * optional, text, contains

## DeepPing API

健康检查接口，需带上 `Authorization` header（同 Notes API 的认证方式）。

`GET /api/v1/deepping?echo=<string>`

该接口会校验请求签名，如果验证成功，会返回：

```json
{
    "status": "ok",
    "echo": "<first 32 chars of echo>",
    "timestamp": <server side epoch millisecond>
}
```
