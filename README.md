【简介】
===
用于MySQL数据库的迁移，能导出表结构、表数据、视图、存储过程和函数，并自动到目标库中创建数据库并导入。

【使用方法】
===
* 在脚本所在目录创建${DATABASE}.txt（DATABASE即为要迁移的数据库名）
---
#内容参考：

`tablename1,ddl`　　　#ddl表示只迁移结构<br>
`tablename2,dml`　　　#dml表示迁移结构和数据<br>

* 执行脚本
---
sh database_migration.sh <srcdb_host> <srcdb_user> <srcdb_password> <db_name> <dstdb_host> <dstdb_user> <dstdb_password>

【参数解释】
===
`<srcdb_host>` 　　　- 源数据库<br>
`<srcdb_user>` 　　　- 源数据库用户名<br>
`<srcdb_password>` 　- 源数据库用户的密码<br>
`<db_name>`　　　　　- 库名<br>
`<dstdb_host>` 　　　- 目标数据库用户名<br>
`<dstdb_user>` 　　　- 目标数据库用户名<br>
`<dstdb_password>` 　- 目标数据库用户密码<br>