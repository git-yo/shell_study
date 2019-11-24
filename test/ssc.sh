#!/bin/sh
JAVA_HOME='/data/tehang/common/jdk1.8.0_181/'
JRE_HOME='/data/tehang/common/jdk1.8.0_181/jre'
CLASS_PATH=.:${JAVA_HOME}/lib/dt.jar:${JAVA_HOME}/lib/tools.jar:${JRE_HOME}/lib
PATH=$PATH:${JAVA_HOME}/bin/:${JRE_HOME}/bin
export JAVA_HOME JRE_HOME CLASS_PATH PATH

CONFIDURL="https://staging-config-service.teyixing.com"
APPTMPDIR="/data/tehang/tmp"
APPDIR="/data/tehang/apps"
WORKPATH="/data/tehang/scripts"
BACKUPDIR="/data/tehang/backup"
BUCKET="tehang-packages/packages"
LOG="${WORKPATH/update.log}
ENV="staging"
project="tmc-customer-api-gateway"
curdate=$(date +"%Y%m%d%H%M%S")

#backup path
do_backup_current_jar(){
	[ ! -d ${BACKUPDIR}/${appname}/ ] && mkdir -p ${BACKUPDIR}/${appname}/
        
########appname#######

	cd ${BACKUPDIR}/${appname}/
	mkdir ${curdte}
	mv ${APPDIR}/tmc-customer-api-gateway.jar ${curdate}/tmc-customer-api-gateway_${currdate}.jar
}

#download update packages
download_and_exact(){
	cd ${APPTMPDIR}
	ossutil cp -f oss://${BUCKET}/${packageName} .

######packageName######

	tar zxf ${packageName}
	return 0
}

install_new_version(){
	cd ${APPTMPDIR}/${appAndVersionName}

#######appAndVersionName######

	if [ -f ${appAndVersionName}.jar ]
        then
	   cp ${appAndVersionName}.jar ${APPDIR}/${appName}.jar
	   return 0
        else
	    echo "${appAndVersionName}更新失败"
	    exit -1
	fi
}

update_version(){
	cd ${APPDIR}/${appName}/
	echo "{\"app\":\"${appAndVersionName}\",\"create_time\":\"$(date +'%Y-%m-%d %H:%M:%S')\"}" >> version.txt
	return 0
}

stop(){
    cd ${APPDIR}/${project}/
    [ -f ${project}.pid ] && pid=$(cat ${project}.pid)
    if [ ! -z ${pid} ]
    
Gradle}
