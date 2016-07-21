*** Settings ***
Suite Setup       DesktopApp测试准备
Suite Teardown    关闭Desktop远程服务器
Resource          ../PubResource-POM/元子页面关键字.txt
Library           SikuliLibrary

*** Test Cases ***
发布动态_文字
    DesktopAPP登录页_登入易信DesktopAPP
    DesktopAPP主页_朋友圈
    DesktopAPP朋友圈页_发布动态_文字    这是我的第一条动态！！ 啦啦啦。。。。。。
    DesktopAPP朋友圈页_关闭
    DesktopAPP主页_点击下拉菜单
    DesktopAPP菜单页_注销

发布动态_文字+表情
    DesktopAPP登录页_登入易信DesktopAPP
    DesktopAPP主页_朋友圈
    DesktopAPP朋友圈页_发布动态_文字+表情    这是我的第一条动态！！ 啦啦啦。。。。。。
    DesktopAPP朋友圈页_关闭
    DesktopAPP主页_点击下拉菜单
    DesktopAPP菜单页_注销
