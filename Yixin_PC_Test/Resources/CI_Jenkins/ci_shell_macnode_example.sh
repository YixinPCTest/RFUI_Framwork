#! /bin/bash

# ***************************
# ci_shell_macnode_example.sh is shell script, which Used as shell scipts in Jenkins Job Build Domain -
# 'Execute Shell'/'Execute Windows batch Command' for RFUI Framework. 
# referense Jenkins Job:  http://ci.hz.netease.com/job/adamdemo_RFUITest_Mobile/configure
#                   Node: http://ci.hz.netease.com/computer/yixinplusQA_MAC_01/configure
# Steps to do:
# 1. Test environments preparations:  
#    1) fetch RFUI Framework script from Git
#    2) get latest Mobile App (Android:apk), write android_app_version to TEST_APP_VERSION_FILE 
#    3) get mobile device(DUT) info  
# 2. appium Server restart (optional)
# 3. Run RFUI cases and output reports files(.xml & .png)
#    Rerun failed cases one more time, if failed cases exiting, and merge the two round result into One
# 4. Others jobs left to do
# ***************************


# change the current dir, so this test can be run from anywhere
pushd ${0%/*}


#Varabile definition
#--------------------
#YIXIN_APK_SERVER is the server url of yixin android app nightly building, get latest test apk  
YIXIN_APK_SERVER="http://10.240.129.99/nightly/"
#TEST_APK_PATH: path of the RFUI Robotframework target app path   TEST_APK_PATH='./YX_RFUI_Framework_demo/Resources/yixin_test.apk'
TEST_APK_PATH="/Users/netease/Documents/adamwang/temp_dir/YX_Plus_RFUI/Resources/yixin_test.apk"
#TEST_APP_VERSION_FILE: the properties file, which used by Jenkins's 'inject Envrionment variables' Plugin.
TEST_APP_INFO_FILE="test_app_info.properties"
TEST_DEVICE_INFO_FILE="test_dev_info.properties"
#RFUI_TESTCASE is the scripts setting used by pybot command RFUI_TESTCASE="./Test/YX_Subscriptions/test_suite_examples.txt"
RFUI_TESTCASE="/Users/netease/Documents/adamwang/temp_dir/YX_Plus_RFUI/Test/BaseFunction/Mobile_Android/Yixinapp/自定义菜单.txt"
RFUI_TESTCASE="/Users/netease/Documents/adamwang/temp_dir/YX_Plus_RFUI/Test/BaseFunction/Mobile_Android"
#RF_FILTER_TAGS is the tags filter setting used by pybot command
RF_FILTER_TAGS="aostest"
#OUTPUT_DIR is RF result/report Dir, used by Jenkins's 'Archive the artifacts' & Publish Junit test result report, etc.  
OUTPUT_DIR="RFUI_outputs_dir"
FIRST_ROUND_OUTPUT_DIR="first_round_outputs_dir"
SECOND_ROUND_OUTPUT_DIR="second_round_outputs_dir"
#--------------------



# Don't Modify the following Until You Got All of it.
#---------------------
#0 Prepare the test environments
    CurrentDIR=`pwd`
    echo -n "CurrentDIR:  ${CurrentDIR}"
    # 0-1 获取最新测试脚步  get latest testcase scripts from gitbuget
    #git clone ssh://hzwangyangdan@git.hz.netease.com:22222/yxplusQA/YX_RFUI_Framework_demo.git
    #cd YX_RFUI_Framework_demo
    #pwd

    # 0-2 获取最新测试包（SUT）get latest test app (android apk or ios app) 
    # 最新测试包，建软链接至 脚本路径（./Resouces）
    #http://10.240.129.99/nightly/yixin_3.8.0.216_138473_20151012_test/yixin_3.8.0.216_138473_20151012_test.apk
    curl $YIXIN_APK_SERVER | grep  "yixin_.*_test" > temp.log
    apk_name=`awk -F\" '{print $2}' temp.log | awk 'END {print}'`
    #echo -n "apk_name: ${apk_name}"
    #echo ${apk_name%/*}
    # 拼接最新测试包路径
    last_yixin_apk_url=${YIXIN_APK_SERVER}${apk_name}${apk_name%/*}.apk
    echo "last_yixin_apk_url: ${last_yixin_apk_url}"
    # 下载最新测试包，同时建软连接
    curl $last_yixin_apk_url > ${apk_name%/*}.apk
    rm ${TEST_APK_PATH}
    cp ${CurrentDIR}"/"${apk_name%/*}.apk ${TEST_APK_PATH}
    #ln -s ${CurrentDIR}"/"${apk_name%/*}.apk ${TEST_APK_PATH}
    ls -l ${TEST_APK_PATH}
 
    # 0-3 获取测试包信息 和 测试机信息 TEST_APP_INFO_FILE & TEST_DEVICE_INFO_FILE
    # input the apk version info to TEST_APP_INFO_FILE
    # $ cat test_app_info.properties
    # android_app_version=yixin_4.1.0.220_148684_20151224_test
    echo "android_app_version=${apk_name%/*}" > ${TEST_APP_INFO_FILE}

    # input the dev info info to TEST_APP_INFO_FILE
    # $ cat test_dev_info.properties 
    # android_dev_name=Meitu
    # android_dev_model=Meitu M4
    # android_version=4.4.4
    adb_info=`adb shell cat /system/build.prop`
    echo "adb_info: ${adb_info}"
    dev_manufacturer=`echo "${adb_info}" | grep ro.product.manufacturer | awk -F\= '{print $2}'`
    dev_model=`echo "${adb_info}" | grep ro.product.model | awk -F\= '{print $2}'`
    device_os_version=`echo "${adb_info}" | grep ro.build.version.release | awk -F\= '{print $2}'`
    echo "\ndev_manufacturer: ${dev_manufacturer}"
    echo "dev_model: ${dev_model}"
    echo "device_os_version: ${device_os_version}"

    echo "android_dev_name=${dev_manufacturer}" > ${TEST_DEVICE_INFO_FILE}
    echo "android_dev_model=${dev_model}" >> ${TEST_DEVICE_INFO_FILE}
    echo "android_version=${device_os_version}" >> ${TEST_DEVICE_INFO_FILE}


    # 0-4 新建or清空output目录 Make output dir empty
    if [ ! -d ${OUTPUT_DIR} ]; then
        mkdir ${OUTPUT_DIR}
        echo -n "Create new OUTPUT_DIR:  ${OUTPUT_DIR}"
    else
        rm -rf ${OUTPUT_DIR}/*
    fi
    
    if [ ! -d ${FIRST_ROUND_OUTPUT_DIR} ]; then
        mkdir ${FIRST_ROUND_OUTPUT_DIR}
        echo -n "Create new FIRST_ROUND_OUTPUT_DIR:  ${FIRST_ROUND_OUTPUT_DIR}"
    else
        rm -rf ${FIRST_ROUND_OUTPUT_DIR}/*
    fi

    if [ ! -d ${SECOND_ROUND_OUTPUT_DIR} ]; then
        mkdir ${SECOND_ROUND_OUTPUT_DIR}
        echo -n "Create new SECOND_ROUND_OUTPUT_DIR:  ${SECOND_ROUND_OUTPUT_DIR}"
    else
        rm -rf ${SECOND_ROUND_OUTPUT_DIR}/*
    fi


#1. restart appium server
    proc_name="appium"
    appium_proc_id=`ps -A | grep -i ${proc_name} | grep -v "grep"|awk '{print $1}'`
    if [ -n "$appium_proc_id" ]; then 
        echo -n "appium id:  ${appium_proc_id} "
        kill ${appium_proc_id} 
    fi
    sleep 2s
    appium --native-instruments-lib &
    sleep 30s


#2. run RF cases with xunit compatiable output.xml
    #pybot --outputdir ${OUTPUT_DIR} --include=${RF_FILTER_TAGS} --xunit=xunitOutput.xml  ${RFUI_TESTCASE}
    pyresult1=`pybot --outputdir ${FIRST_ROUND_OUTPUT_DIR} --include=${RF_FILTER_TAGS}  --xunit=xunitOutput.xml ${RFUI_TESTCASE}`
    echo  "pyresult1: \n${pyresult1}\n"

    if [ `echo "${pyresult1}" | grep "FAIL"`=="" ]; then
        # in case the first round all pass, copy result files to ${OUTPUT_DIR}
        echo "[Test Finished]We run the test suite one round, and all pass. :-)!"
        cp ${FIRST_ROUND_OUTPUT_DIR}/* ${OUTPUT_DIR}/
    else
        # in case the first round have failed cases,  then rerun the failed cases again
        pyresult2=`pybot -R ${FIRST_ROUND_OUTPUT_DIR}/output.xml --outputdir ${SECOND_ROUND_OUTPUT_DIR} --include=${RF_FILTER_TAGS}  ${RFUI_TESTCASE} `
        echo "pyresult2: \n${pyresult2} \n"
        echo "[Test Finished]We run the test suite two rounds, due to some cases failed in first round! :-(!"      
        #merge two round result to one report
        rebot --outputdir ${OUTPUT_DIR}  --output output.xml --xunit=xunitOutput.xml --merge  ${FIRST_ROUND_OUTPUT_DIR}/output.xml  ${SECOND_ROUND_OUTPUT_DIR}/output.xml

        #copy the capture pics to ${OUTPUT_DIR} roughly, 存在 部分case 被覆盖错误；后续需要优化。  
        cp ${FIRST_ROUND_OUTPUT_DIR}/*.png  ${OUTPUT_DIR}/
        cp ${SECOND_ROUND_OUTPUT_DIR}/*.png  ${OUTPUT_DIR}/
    fi

#Merging re-executed tests
#http://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html#post-processing-outputs
#pybot --output original.xml tests                          # first execute all tes#ts
#pybot --rerunfailed original.xml --output rerun.xml tests  # then re-execute failin#g
#rebot --merge original.xml rerun.xml                       # finally merge results


# restore the current directory
popd

exit 0

