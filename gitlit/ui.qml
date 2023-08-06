import QtQuick 2.7
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

import Vedder.vesc.commands 1.0
import Vedder.vesc.configparams 1.0

Item {
    anchors.fill: parent
    anchors.margins: 10

    property Commands mCommands: VescIf.commands()
    
    //property var parentTabBar: parent.tabBarItem
    
    //Component.onCompleted: {
     //   parentTabBar.visible = true
     //   parentTabBar.enabled = true
    //}
    
    
    
    ColumnLayout {
        id: root
        anchors.fill: parent
        //Layout.fillWidth: true
        //spacing: 0
        
        TabBar {
        id: gitlitTabBar
        currentIndex: 0
            Layout.fillWidth: true
            clip: true
            enabled: true
        //parent: parentTabBar
        //anchors.fill: parent
        //currentIndex: swipeView.currentIndex
        
        background: Rectangle {
            opacity: 1
            color: Utility.getAppHexColor("lightBackground")
        }
        
        property int buttonWidth: Math.max(120, gitlitTabBar.width / (rep.model.length))

        Repeater {
            id: rep
            model: ["GitLit"]
            
            TabButton {
                text: modelData
                width: gitlitTabBar.buttonWidth
            }
        }
    }
    
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
    
    Connections {
        target: mCommands
        
        function onValuesReceived(values, mask) {
            
        }
    }
    
    Timer {
        id: aliveTimer
        interval: 100
        running: true
        repeat: true
        
        onTriggered: {
            if (VescIf.isPortConnected()) {
                
            }
        }
    }
}
