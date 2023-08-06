import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

import Vedder.vesc.commands 1.0
import Vedder.vesc.configparams 1.0

Item {
    id: rootItem
    anchors.fill: parent
    anchors.margins: 10
    
    property Commands mCommands: VescIf.commands()
    
    property var parentTabBar: parent.tabBarItem
    property var parentSwipeView: parent.swipeViewItem
    
    Component.onCompleted: {
        swipeView.insertItem(swipeView.count, root)
        tabBar.insertItem(tabBar.count, gitlitAppButton)
        tabBar.visible = true
        tabBar.enabled = true
    }
    
    TabButton {
        id: gitlitAppButton
        visible: true
        text: "GitLit"
        width: tabBar.buttonWidth
    }
    
//    Page {
//        id: gitlitAppPage
//        visible: true
        
        ColumnLayout {
            id: root
            //anchors.fill: parent
            Layout.fillWidth: true
            spacing: 0
            
            Text {
                id: dimmerHeader
                color: Utility.getAppHexColor("lightText")
                font.family: "DejaVu Sans Mono"
                Layout.margins: 0
                Layout.leftMargin: 0
                Layout.fillWidth: true
                text: "Dimming Control"
                font.underline: true
                font.weight: Font.Black
                font.pointSize: 14
            }
            
            Slider {
                id: dimSlider
                Layout.fillWidth: true
                //decimals: 1
                from: 0.0
                to: 1.0
                value:1.0
                stepSize: 0.1
                
                onValueChanged: {
                    mCommands.lispSendReplCmd("(setq dim-on " + value + ")")
                    mCommands.lispSendReplCmd("(update-output)")
                }
            }
            
            RowLayout {
                Button {
                    Layout.fillWidth: true
                    text: "On"
                    
                    onClicked: {
                        
                        mCommands.lispSendReplCmd("(setq lit-state 1)")
                        mCommands.lispSendReplCmd("(set-output 1)")
                    }
                }
                
                Button {
                    Layout.fillWidth: true
                    text: "Off"
                    
                    onClicked: {
                        mCommands.lispSendReplCmd("(setq lit-state 0)")
                        mCommands.lispSendReplCmd("(set-output 1)")
                    }
                }
            }
            
            Item {
                Layout.fillHeight: true
            }
        }
        
//    }
    
//    function addAppUI () {
//        parentSwipeView.insertItem(0, gitlitAppPage)
//        parentTabBar.insertItem(0, gitlitAppButton)       
//    }
    
}
