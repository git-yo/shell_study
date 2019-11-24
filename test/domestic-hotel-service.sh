#!/bin/bash
# Name: domestic-hotel-service.sh
# Author: yangjun@tehang.com
# Date: 2019-01-27 11:25:01
# Desc:
#     服务管理脚本，主要便于更新维护, OSS上存留一份

JAVA_HOME='/data/tehang/common/jdk-11.0.3/'
JRE_HOME='/data/tehang/common/jdk-11.0.3/jre'
CLASS_PATH=.:${JAVA_HOME}/lib/dt.jar:${JAVA_HOME}/lib/tools.jar:${JRE_HOME}/lib
PATH=$PATH:${JAVA_HOME}/bin:${JRE_HOME}/bin
export JAVA_HOME JRE_HOME CLASS_PATH PATH
# 配置中心地址
CONFIGURL="https://config-service.teyixing.com"
APPTMPDIR="/data/tehang/tmp"
APPDIR="/data/tehang/apps"
# 当前工作路径
WORKPATH="/data/tehang/scripts"
# 备份路径
BACKUPDIR="/data/tehang/backup"
# 阿里云OSS
BUCKET="tehang-packages/packages"
# 操作日志
LOG="${WORKPATH}/update.log"
ENV="prod"

# 初次生成的
project="domestic-hotel-service"
proname="domestic-hotel-service-v2.1.3.jar"
linkname="domestic-hotel-service.jar"

curdate=$(date +"%Y%m%d%H%M%S")

temp_backup_current_jar(){
   cd ${APPDIR}/${appName}
   [ ! -d ${BACKUPDIR}/${appAndVersionNameOld} ] && mkdir -p ${BACKUPDIR}/${appAndVersionNameOld}/tmp
   need_to_backup_jars=$(ls | grep "jar$" | grep "\-v[0-9]" |grep -v grep)
   for i in ${need_to_backup_jars[@]}
   do
        # mv $i ${BACKUPDIR}/${appAndVersionNameOld}/$i_${curdate}
        mv $i ${BACKUPDIR}/${appAndVersionNameOld}/tmp
   done
   return 0
}

# 更新失败，回滚操作
rollback_backup_current_jar(){
    cd ${BACKUPDIR}/${appAndVersionNameOld}/tmp
    appAndVersionName=
    [ ! -d ${BACKUPDIR}/${appAndVersionNameOld} ] && mkdir -p ${BACKUPDIR}/${appAndVersionNameOld}/tmp
    need_to_rollback_jars=$(ls | grep "jar$" | grep "\-v[0-9]" |grep -v grep)
    for i in ${need_to_backup_jars[@]}
    do
        cp  ${APPDIR}/${project}
    done
    # 删除临时目录
    cd ${BACKUPDIR}/${appAndVersionNameOld}
    rm -rf tmp
    return 0
}

# 实际备份操作
do_backup_current_jar(){
   cd ${BACKUPDIR}/${appAndVersionNameOld}/
   mkdir ${curdate}
   mv tmp/* ${curdate}
   rm -rf tmp
}


# 下载更新包
download_and_exact(){
    cd ${APPTMPDIR}
    ossutil cp -f oss://${BUCKET}/${packageName} .
    tar zxf ${packageName}
    return 0

}

install_new_version(){
    cd ${APPTMPDIR}/${appAndVersionName}
    if [ -f ${appAndVersionName}.jar  ]
    then
        cp ${appAndVersionName}.jar ${APPDIR}/${appName}/
        return 0
    else
        echo "${appAndVersionName}更新失败"
        exit -1
    fi
}

# 更新快捷
update_link(){
    cd ${APPDIR}/${appName}/
    # 更新当前管理脚本内容
    if [ -f "${appAndVersionName}.jar" ]
    then
        sed -i 's#^proname=".*.jar"#proname="'${appAndVersionName}'.jar"#' ${appName}.sh
        ln -sf ${appAndVersionName}.jar ${linkname}
    fi
    # 将版本号写入文件 example: domestic-hotel-service-v2.0.11
    echo "{\"app\":\"${appAndVersionName}\", \"created_time\":\"$(date +'%Y-%m-%d %H:%M:%S')\"}" > version.txt
    return 0
}

# 停止服务
stop(){
    cd ${APPDIR}/${project}/
    [ -f ${project}.pid ] && pid=$(cat ${project}.pid)
    if [ ! -z ${pid} ]
    then
        kill $pid
        [ ! -f .stop_lock} ] && touch .stop_lock
        rm ${project}.pid
    fi
    sleep 3
    echo "stopped"
    unset pid
}

# 开启服务
# 在应用内，生成带pid的文件
start() {
    echo "starting..."
    cd ${APPDIR}/${project}/
    [ ! -f .stop_lock} ] && rm .stop_lock
    # nohup java -jar ${linkname} > nohup.out 2>&1 &
    nohup java -jar ${linkname} > /dev/null 2>&1 &
    echo $! > ${project}.pid
}

# update 接收的参数为：软件版本
# 考虑因素：执行数据库脚本
update() {
    packageName=$1
    if [ -z ${packageName} ]
    then
        echo "传参错误，无法更新"
        exit -1
    fi
    ossutil ls  oss://${BUCKET} | grep ${packageName}  >/dev/null
    if [ $? -ne 0 ]
    then
        echo "更新失败，请检查OSS上是否存在该文件"
        exit
    fi
    # 获取老版本
    appAndVersionNameOld=$(cat $0 |grep "^proname" | awk -F\" '{print $2}' | awk -F".jar" '{print $1}')

    # 取得值 domestic-hotel-service-v2.0.11
    appAndVersionName=$(echo ${packageName} | awk -F".tar.gz" '{print $1}')
    # 取得值domestic-hotel-service
    appName=$(echo ${packageName} | awk -F"-v[0-9]" '{print $1}')
    # 取得配置名: tmcservices
    config=$(echo ${appName} | sed 's/-//g')
    [ -z ${config} ] && echo "配置中心的配置文件目录为空!" && exit -1

    if [ ${appAndVersionNameOld} == ${appAndVersionName} ]
    then
        echo "当前版本和需要更新的版本是一样，请检查当前需要更新的版本${appAndVersionName}是否为最新版本!"
        exit -1
    fi
    # 避免未完全关闭，故重复执行stop命令
    stop
    sleep 3
    stop

    # 下载压缩文件
    download_and_exact
    # 临时备份应用，此处为jar文件
    temp_backup_current_jar

    install_new_version
    if [ 0 -ne 0  ]
    then
        echo "还原当前操作!"
        # 还原
        rollback_backup_current_jar
        start
        exit -1
    fi
    # 备份操作
    do_backup_current_jar

    # 更新当前脚本
    update_link
    # 开启服务
    start
}

case $1 in
   "start")
      start
      ;;
   "stop")
     stop
     ;;
   "update")
     update $2
     ;;
   "restart")
     stop
     start
     ;;
   *)
    echo "Usage: $0 {start|stop|update|restart}"
    ;;
esac

