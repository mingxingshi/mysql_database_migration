#!/bin/bash
#author:shimx

if [ $# -ne 7 ];then
    echo "Usage: `basename $0` <srcdb_host> <srcdb_user> <srcdb_password> <db_name> <dstdb_host> <dstdb_user> <dstdb_password>"
    exit 2
fi

HOST=$1
USER=$2
DATABASE=$4
DST_HOST=$5
DST_USER=$6
BACKUPDIR=$(cd `dirname $0`; pwd)

#检查连通性
function test_database_connectivity(){
export db_host=$1
export db_user=$2
export MYSQL_PWD=$3
mysql -h${db_host} -u${db_user} -s -e "select 1;" 1>/dev/null 2>&1
if [ X"$?" != X"0" ];then
    echo "Connect to database ${db_host} failed"
    exit 1
fi
}
test_database_connectivity ${HOST} ${USER} $3
test_database_connectivity ${DST_HOST} ${DST_USER} $7

rm -f ${BACKUPDIR}/${DATABASE}_ddl.sql ${BACKUPDIR}/${DATABASE}_dml.sql
if [ ! -f ${BACKUPDIR}/${DATABASE}.txt ];then
    echo "Not found {DATABASE}.txt"
    exit 1
elif [ X`which mysql mysqldump 1>/dev/null 2>&1 && echo $?` != X"0" ];then
    echo "Not found mysql client"
    exit 1
fi

#导出
export MYSQL_PWD=$3
CREATE_DATABASE_SQL=`mysql -h${HOST} -u${USER} -s -e "select concat('CREATE DATABASE IF NOT EXISTS ${DATABASE} DEFAULT CHARACTER SET ', DEFAULT_CHARACTER_SET_NAME, ';') from information_schema.schemata where schema_name='${DATABASE}';"` 

for table in `awk -F"," '{print $1}' ${BACKUPDIR}/${DATABASE}.txt`;do
    mysqldump -h ${HOST} -u ${USER} -q -d ${DATABASE} ${table} >> ${BACKUPDIR}/${DATABASE}_${table}_ddl.sql
    if [ X"$?" == X"0" ];then
        echo "Export structure of table $table successfully."
        cat ${BACKUPDIR}/${DATABASE}_${table}_ddl.sql >> ${BACKUPDIR}/${DATABASE}_ddl.sql && rm -f ${BACKUPDIR}/${DATABASE}_${table}_ddl.sql
        if [ `awk -F"," '{if($1=="'${table}'") print $2}' ${BACKUPDIR}/${DATABASE}.txt` == "dml" ]; then
            mysqldump -h ${HOST} -u ${USER} -q -t ${DATABASE} ${table} >> ${BACKUPDIR}/${DATABASE}_${table}_dml.sql
            if [ X"$?" == X"0" ];then
                echo "Export data of table ${table} successfully."
                cat ${BACKUPDIR}/${DATABASE}_${table}_dml.sql >> ${BACKUPDIR}/${DATABASE}_dml.sql && rm -f ${BACKUPDIR}/${DATABASE}_${table}_dml.sql
            else
                echo "Export data of table ${table} failed."
                rm -f ${BACKUPDIR}/${DATABASE}_${table}_dml.sql
                echo "$table,export data failed" >> ${DATABASE}_error.log
            fi
        fi
    else
        echo "Export structure of table $table failed."
        rm -f ${BACKUPDIR}/${DATABASE}_${table}_ddl.sql
        echo "$table,export stucture failed" >> ${DATABASE}_error.log
        continue
    fi
    mysqldump -h ${HOST} -u ${USER} -ntd -R ${DATABASE} >> ${BACKUPDIR}/${DATABASE}_ddl.sql
    if [ X"$?" == X"0" ];then
        echo "Export functions and procedures successfully"
    fi
done

#导入目标库
export MYSQL_PWD=$7
mysql -h${DST_HOST} -u${DST_USER} -s -e "${CREATE_DATABASE_SQL}" 1>/dev/null 2>&1
if [ X"$?" == X"0" ];then
    mysql -h${DST_HOST} -u${DST_USER} ${DATABASE} < ${BACKUPDIR}/${DATABASE}_ddl.sql
    if [ X"$?" == X"0" ];then
        echo "Import structure to target database successfully";
        mysql -h${DST_HOST} -u${DST_USER} ${DATABASE} < ${BACKUPDIR}/${DATABASE}_dml.sql
        if [ X"$?" == X"0" ];then
            echo "Import data to target database successfully";
        else
            echo "Import data to target database failed"
            exit 1
        fi
    else
        echo "Import structure to target database failed"
        exit 1
    fi
else
    echo "Create database ${DATABASE} failed"
    exit 1
fi
