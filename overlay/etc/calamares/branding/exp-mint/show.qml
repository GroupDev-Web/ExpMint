import QtQuick 2.0

Presentation {
    id: presentation

    Slide {
        Image {
            anchors.fill: parent
            source: "exp-mint-welcome.png"
            fillMode: Image.PreserveAspectCrop
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#07110d"
            Text {
                anchors.centerIn: parent
                width: parent.width * 0.78
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: "#dff7e9"
                font.pixelSize: 30
                text: "Fast and familiar\n\nEXP Mint uses the lightweight XFCE desktop and is tuned for dependable performance on older PCs."
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#07110d"
            Text {
                anchors.centerIn: parent
                width: parent.width * 0.78
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: "#9fffd0"
                font.pixelSize: 30
                text: "Your computer, your rules.\n\nThe installer is preparing EXP Mint 22.3."
            }
        }
    }
}
