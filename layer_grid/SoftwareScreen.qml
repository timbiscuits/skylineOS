import QtQuick 2.8
import QtGraphicalEffects 1.0
import "../global"
import "../Lists"
import "../layer_help"
import "../utils.js" as Utils
import "qrc:/qmlutils" as PegasusUtils

FocusScope
{

    property int numcolumns: widescreen ? 6 : 3
    property int idx: 0
    // "By Time Last Played" "By Title" "By Total Play Time"
    property var sortTitle: {
        switch (sortByIndex) {
            case 0:
                return "By Time Last Played";
            case 1:
                return "By Title";
            case 2:
                return "By Total Play Time";
            default:
                return ""
        }
    }

    function processButtonArt(buttonModel) {
        var i;
        for (i = 0; buttonModel.length; i++) {
            if (buttonModel[i].name().includes("Gamepad")) {
            var buttonValue = buttonModel[i].key.toString(16)
            return buttonValue.substring(buttonValue.length-1, buttonValue.length);
            }
        }
    }

    Item
    {
        id: softwareScreenContainer
        anchors.fill: parent
        anchors {
            left: parent.left; leftMargin: screenmargin
            right: parent.right; rightMargin: screenmargin
        }

        Keys.onPressed: {
            if (event.isAutoRepeat)
                return;

            if (api.keys.isDetails(event)) {
                event.accepted = true;
                return;
            }
            if (api.keys.isCancel(event)) {
                event.accepted = true;
                showHomeScreen();
                return;
            }
            if (api.keys.isFilters(event)) {
                event.accepted = true;
                cycleSort();
                return;
            }
        }

        // Top bar
        Item
        {
            id: topBar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.right: parent.right
            height: Math.round(screenheight * 0.1222)
            z: 5

            Image
            {
                id: headerIcon
                width: Math.round(screenheight*0.0611)
                height: width
                source: "../assets/images/allsoft_icon.svg"
                sourceSize.width: vpx(128)
                sourceSize.height: vpx(128)

                anchors {
                    top: parent.top; topMargin: Math.round(screenheight*0.0416)
                    left: parent.left; leftMargin: vpx(38)
                }

                Text
                {
                    id: collectionTitle
                    text: currentCollection == -1 ? "All Software" : api.collections.get(currentCollection).name
                    color: theme.text
                    font.family: titleFont.name
                    font.pixelSize: Math.round(screenheight*0.0277)
                    font.bold: true
                    anchors {
                        verticalCenter: headerIcon.verticalCenter
                        left: parent.right; leftMargin: vpx(12)
                    }
                }
            }


            // Nintendo's Sort Options: "By Time Last Played", "By Total Play Time", "By Title", "By Publisher"
            // Probably won't do "By Publisher"
            Text {
                id: sortTypeTxt
                text:sortTitle

                anchors {
                    verticalCenter: headerIcon.verticalCenter;
                    right: topBar.right
                }
                color: theme.text
                font.family: titleFont.name
                font.weight: Font.Thin
                font.pixelSize: Math.round(screenheight*0.02)
                horizontalAlignment: Text.Right
            }

            MouseArea {
                anchors.fill: sortTypeTxt
                hoverEnabled: true
                onEntered: {}
                onExited: {}
                onClicked: cycleSort();
            }

            ColorOverlay {
                anchors.fill: headerIcon
                source: headerIcon
                color: theme.text
                cached: true
            }

            Image {
                id: sortIcon
                width: Math.round(screenheight*0.04)
                height: width
                source: "../assets/images/controller/"+ processButtonArt(api.keys.filters) + ".png"
                sourceSize.width: 64
                sourceSize.height: 64
                anchors {
                    verticalCenter: sortTypeTxt.verticalCenter
                    right: sortTypeTxt.left
                    rightMargin: vpx(5)
                }
            }

            ColorOverlay {
                anchors.fill: sortIcon
                source: sortIcon
                color: theme.text
                cached: true
            }

            MouseArea {
                anchors.fill: headerIcon
                hoverEnabled: true
                onEntered: {}
                onExited: {}
                onClicked: showHomeScreen();
            }

            // Line
            Rectangle {
                y: parent.height - vpx(1)
                anchors.left: parent.left; anchors.right: parent.right
                height: 1
                color: theme.secondary
            }

        }

        // Grid masks (better performance than using clip: true)
        Rectangle
        {
            anchors {
                left: parent.left; top: parent.top; right: parent.right
            }
            color: theme.main
            height: topBar.height
            z: 4
        }
        
        // Game grid
        GridView 
        {
            id: gameGrid
            focus: true

            NumberAnimation { id: anim; property: "scale"; to: 0.7; duration: 100 }

            Keys.onPressed: {
                if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                    event.accepted = true;
                    anim.start();
                    playSoftware();
                }
            }

            Keys.onUpPressed:       { navSound.play(); moveCurrentIndexUp() }
            Keys.onDownPressed:     { navSound.play(); moveCurrentIndexDown() }
            Keys.onLeftPressed:     { navSound.play(); moveCurrentIndexLeft() }
            Keys.onRightPressed:    { navSound.play(); moveCurrentIndexRight() }

            onCurrentIndexChanged: {
                currentGameIndex = currentIndex;
                return;
            }

            anchors {
                left: parent.left; leftMargin: vpx(63)
                top: topBar.bottom;
                right: parent.right; rightMargin: vpx(63)
                bottom: parent.bottom
            }
			topMargin: Math.round(screenheight*0.12)
            bottomMargin: Math.round(screenheight*0.12)
            
            cellWidth: width / numcolumns
            cellHeight: cellWidth
            preferredHighlightBegin: Math.round(screenheight*0.1388)
            preferredHighlightEnd: Math.round(screenheight*0.6527)
            highlightRangeMode: ListView.StrictlyEnforceRange // Highlight never moves outside the range
            snapMode: ListView.SnapToItem
            highlightMoveDuration: 150 //150 is default

            
            model: softwareList[sortByIndex].games //api.collections.get(collectionIndex).games
            delegate: gameGridDelegate            

            Component 
            {
                id: gameGridDelegate
                
                Item
                {
                    id: delegateContainer
                    property bool selected: delegateContainer.GridView.isCurrentItem
                    width: gameGrid.cellWidth - vpx(10)
                    height: width
                    z: selected ? 10 : 0


                    Image {
                        id: screenshot
                        width: parent.width
                        height: parent.height
                        asynchronous: true
                        //smooth: true
                        source: modelData.assets.screenshots[0] ? modelData.assets.screenshots[0] : ""
                        sourceSize { width: 256; height: 256 }
                        fillMode: Image.PreserveAspectCrop
                        layer.enabled: !selected
                        layer.effect: DropShadow {
                            transparentBorder: true
                            horizontalOffset: 0
                            verticalOffset: 2
                            color: "#1F000000"
                            radius: 6.0
                            samples: 6
                            z: -2
                        }
                    }

                    //white overlay on screenshot for better logo visibility over screenshot
                    Rectangle
                    {
                        width: parent.width
                        height: parent.height
                        color: "white"
                        opacity: 0.15
                        visible: gamelogo.source != "" && screenshot.source != ""
                    }

                    // Logo
                    Image {
                        id: gamelogo

                        width: screenshot.width
                        height: screenshot.height
                        anchors {
                            fill: parent
                            margins: vpx(6)
                        }

                        asynchronous: true

                        property var logoImage: {
                            if (modelData != null) {
                                if (modelData.collections.get(0).shortName === "retropie")
                                    return modelData.assets.boxFront;
                                else if (modelData.collections.get(0).shortName === "steam")
                                    return modelData.assets.logo ? modelData.assets.logo : "" //root.logo(gameData);
                                else
                                    return modelData.assets.logo;
                            } else {
                                return ""
                            }
                        }

                        //opacity: 0
                        source: modelData ? Utils.logo(modelData) || "" : "" //modelData.assets.logo ? modelData.assets.logo : ""
                        sourceSize { width: 256; height: 256 }
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: modelData.assets.logo ? modelData.assets.logo : ""
                        z:8
                    }

                    /*DropShadow {
                        id: logoshadow
                        anchors.fill: gamelogo
                        horizontalOffset: 0
                        verticalOffset: 2
                        radius: 4.0
                        samples: 6
                        color: "#80000000"
                        source: gamelogo
                    }*/

                    MouseArea {
                        anchors.fill: screenshot
                        hoverEnabled: true
                        onEntered: {}
                        onExited: {}
                        onClicked: {
                            if (selected)
                            {
                                anim.start();
                                playSoftware();
                            }
                            else
                                navSound.play();
                                gameGrid.currentIndex = index
                        }
                    }

                    //NumberAnimation { id: anim; property: "scale"; to: 0.7; duration: 100 }
                    //NumberAnimation { property: "scale"; to: 1.0; duration: 100 }
                    
                    Rectangle {
                        id: outerborder
                        width: screenshot.width
                        height: screenshot.height
                        color: theme.button//"white"
                        z: -1

                        Rectangle
                        {
                            anchors.fill: outerborder
                            anchors.margins: vpx(4)
                            color: theme.button
                            z: 7
                        }

                        Text
                        {
                            text: modelData.title
                            x: vpx(8)
                            width: parent.width - vpx(16)
                            height: parent.height
                            font.family: titleFont.name
                            color: theme.text//"white"
                            font.pixelSize: Math.round(screenheight*0.0194)
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            wrapMode: Text.Wrap
                            visible: !modelData.assets.logo
                            z: 10
                        }
                    }
                        

                    // Title bubble
                    Rectangle {
                        id: titleBubble
                        width: gameTitle.contentWidth + vpx(54)
                        height: Math.round(screenheight*0.0611)
                        color: "white"
                        radius: vpx(4)
                        
                        // Need to figure out how to stop it from clipping the margin
                        // mapFromItem and mapToItem are probably going to help
                        property int xpos: screenshot.width/2 - width/2
                        x: xpos
                        //y: highlightBorder.y//vpx(-63)
                        z: 10 * index

                        anchors {
                            horizontalCenter: bubbletriangle.horizontalCenter
                            bottom: bubbletriangle.top
                        }
                        
                        opacity: selected ? 0.95 : 0
                        //Behavior on opacity { NumberAnimation { duration: 50 } }

                        Text {
                            id: gameTitle
                            text: modelData.title
                            color: theme.accent
                            font.pixelSize: Math.round(screenheight*0.0222)
                            font.bold: true
                            font.family: titleFont.name
                            
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left; leftMargin: vpx(27)
                            }
                            
                        }
                    }

                    Image {
                        id: bubbletriangle
                        source: "../assets/images/triangle.svg"
                        width: vpx(17)
                        height: Math.round(screenheight*0.0152)
                        opacity: titleBubble.opacity
                        x: screenshot.width/2 - width/2
                        anchors.bottom: screenshot.top
                    }

                    // Border
                    HighlightBorder
                    {
                        id: highlightBorder
                        width: screenshot.width + vpx(18)
                        height: width

                        
                        anchors.centerIn: screenshot
                        
                        //x: vpx(-7)
                        //y: vpx(-7)
                        z: -10

                        selected: delegateContainer.GridView.isCurrentItem
                    }

                }
            }
        }

    }
}
