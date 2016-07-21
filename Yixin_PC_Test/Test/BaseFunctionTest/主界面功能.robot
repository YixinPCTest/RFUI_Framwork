*** Settings ***
Suite Setup       DesktopApp测试准备
Suite Teardown    关闭Desktop远程服务器
Resource          ../PubResource-POM/元子页面关键字.txt
Library           SikuliLibrary

*** Test Cases ***
置顶该会话_我的手机
    DesktopAPP登录页_登入易信DesktopAPP
    DesktopAPP主页_置顶该会话
    DesktopAPP主页_点击下拉菜单
    DesktopAPP菜单页_注销

从列表中删除该会话_我的手机
    DesktopAPP登录页_登入易信DesktopAPP
    DesktopAPP主页_取消置顶
    DesktopAPP主页_从列表中删除该会话
    DesktopAPP主页_点击下拉菜单
    DesktopAPP菜单页_注销
