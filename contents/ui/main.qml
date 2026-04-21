import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support
import "logic.js" as Logic

PlasmoidItem {
    id: root

    property bool isServiceActive: false
    property bool isServiceEnabled: false
    property bool isVpnConnected: false
    property bool isPending: false
    property bool isTogglePending: false
    property string lastLog: "Inicializando..."
    property bool _waitingVerify: false

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        onNewData: (sourceName, data) => {
            if (sourceName === "systemctl is-enabled warp-svc" && root._waitingVerify) {
                root._waitingVerify = false;
                Logic.parseStatus(sourceName, data, root);
                root.isTogglePending = false;
                disconnectSource(sourceName);
                return;
            }
            let log = Logic.parseStatus(sourceName, data, root);
            if (log) lastLog = log;
            isPending = false;
            disconnectSource(sourceName);
        }
    }

    Plasma5Support.DataSource {
        id: sudoExecutable
        engine: "executable"
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            pendingGuard.stop();
            let exitCode = data["exit code"];
            let ts = new Date().toLocaleTimeString([], {hour:'2-digit',minute:'2-digit',second:'2-digit'});
            let wasToggle = sourceName.indexOf("systemctl enable") !== -1 ||
                            sourceName.indexOf("systemctl disable") !== -1;
            if (wasToggle) {
                if (exitCode === 0) {
                    lastLog = "[" + ts + "] Autoboot actualizado.";
                    root._waitingVerify = true;
                    verifyToggleTimer.restart();
                } else {
                    lastLog = "[" + ts + "] Cancelado.";
                    root._waitingVerify = false;
                    root.isTogglePending = false;
                }
            } else {
                isPending = false;
                lastLog = "[" + ts + "] " + (exitCode === 0 ? "OK." : "Cancelado.");
                Logic.updateStatus(executable);
            }
        }
    }

    Timer {
        id: verifyToggleTimer; interval: 400
        onTriggered: {
            executable.disconnectSource("systemctl is-enabled warp-svc");
            executable.connectSource("systemctl is-enabled warp-svc");
        }
    }

    function runCmd(cmd) {
        isPending = true;
        let ts = new Date().toLocaleTimeString([], {hour:'2-digit',minute:'2-digit',second:'2-digit'});
        lastLog = "[" + ts + "] " + cmd;
        executable.connectSource(cmd);
        pendingGuard.restart();
    }

    function runToggleCmd(action) {
        root.isTogglePending = true;
        root._waitingVerify = false;
        let ts = new Date().toLocaleTimeString([], {hour:'2-digit',minute:'2-digit',second:'2-digit'});
        lastLog = "[" + ts + "] pkexec systemctl " + action + " warp-svc";
        sudoExecutable.connectSource("bash -c 'pkexec systemctl " + action + " warp-svc; echo __done__'");
        pendingGuard.restart();
    }

    Timer {
        id: pendingGuard; interval: 15000
        onTriggered: {
            root.isPending = false;
            root.isTogglePending = false;
            root._waitingVerify = false;
            lastLog = "[System] Timeout.";
            Logic.updateStatus(executable);
        }
    }

    function updateStatus() {
        if (!isPending) Logic.updateStatus(executable);
    }

    Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: updateStatus()
    }

    compactRepresentation: MouseArea {
        onClicked: root.expanded = !root.expanded
        Kirigami.Icon {
            anchors.fill: parent
            source: isVpnConnected ? "network-vpn-symbolic" : "network-vpn-none-symbolic"
            color: isVpnConnected ? Kirigami.Theme.positiveTextColor :
                   (isServiceActive ? Kirigami.Theme.textColor : Kirigami.Theme.negativeTextColor)
        }
    }

    fullRepresentation: Item {
        implicitWidth: Kirigami.Units.gridUnit * 18
        implicitHeight: Kirigami.Units.gridUnit * 22

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true

                Kirigami.Icon {
                    source: "cloudflare-warp"
                    fallback: "network-vpn"
                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                    opacity: 0.85
                }

                PlasmaComponents.Label {
                    text: "Cloudflare WARP"
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                Rectangle {
                    height: Kirigami.Units.gridUnit * 0.9
                    width: statusPillText.implicitWidth + Kirigami.Units.smallSpacing * 3
                    radius: height / 2
                    color: root.isVpnConnected
                           ? Kirigami.Theme.positiveBackgroundColor
                           : (root.isServiceActive
                              ? Kirigami.Theme.neutralBackgroundColor
                              : Kirigami.Theme.negativeBackgroundColor)

                    Behavior on color { ColorAnimation { duration: 400 } }

                    PlasmaComponents.Label {
                        id: statusPillText
                        anchors.centerIn: parent
                        text: root.isVpnConnected ? "● Activo" :
                              (root.isServiceActive ? "○ Desconectado" : "✕ Detenido")
                        font.pixelSize: Kirigami.Units.gridUnit * 0.6
                        font.weight: Font.Medium
                        color: root.isVpnConnected
                               ? Kirigami.Theme.positiveTextColor
                               : (root.isServiceActive
                                  ? Kirigami.Theme.neutralTextColor
                                  : Kirigami.Theme.negativeTextColor)
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Kirigami.Theme.separatorColor
                opacity: 0.5
                Layout.topMargin: Kirigami.Units.smallSpacing / 2
                Layout.bottomMargin: Kirigami.Units.smallSpacing / 2
            }

            PlasmaComponents.Button {
                Layout.fillWidth: true
                enabled: root.isServiceActive && !root.isPending && !root.isTogglePending
                icon.name: root.isVpnConnected ? "network-disconnect" : "network-connect"
                text: root.isVpnConnected ? "Cortar conexión" : "Conectar VPN"
                display: AbstractButton.TextBesideIcon
                highlighted: !root.isVpnConnected && root.isServiceActive
                onClicked: runCmd(root.isVpnConnected ? "warp-cli disconnect" : "warp-cli connect")
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                spacing: 0

                    PlasmaComponents.Label {
                        text: "Ajustes del sistema"
                        font.pixelSize: Kirigami.Units.gridUnit * 0.65
                        font.weight: Font.Medium
                        opacity: 0.55
                        Layout.bottomMargin: Kirigami.Units.smallSpacing
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Kirigami.Icon {
                            source: "system-run"
                            implicitWidth: Kirigami.Units.iconSizes.small
                            implicitHeight: Kirigami.Units.iconSizes.small
                            opacity: root.isTogglePending ? 0.3 : 0.7
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }

                        ColumnLayout {
                            spacing: 0
                            PlasmaComponents.Label {
                                text: "Inicio automático"
                                opacity: root.isTogglePending ? 0.4 : 1.0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                            }
                            PlasmaComponents.Label {
                                text: root.isServiceEnabled ? "Habilitado al arrancar" : "Deshabilitado"
                                font.pixelSize: Kirigami.Units.gridUnit * 0.6
                                opacity: 0.55
                            }
                        }

                        Item { Layout.fillWidth: true }

                        PlasmaComponents.BusyIndicator {
                            visible: root.isTogglePending
                            running: root.isTogglePending
                            implicitWidth: Kirigami.Units.gridUnit * 1.4
                            implicitHeight: Kirigami.Units.gridUnit * 1.4
                        }

                        Rectangle {
                            visible: !root.isTogglePending
                            width: Kirigami.Units.gridUnit * 2.6
                            height: Kirigami.Units.gridUnit * 1.3
                            radius: height / 2
                            color: root.isServiceEnabled
                                   ? Kirigami.Theme.highlightColor
                                   : Kirigami.Theme.backgroundColor
                            border.color: root.isServiceEnabled
                                          ? Kirigami.Theme.highlightColor
                                          : Kirigami.Theme.disabledTextColor
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                width: parent.height - 4
                                height: width
                                radius: width / 2
                                anchors.verticalCenter: parent.verticalCenter
                                x: root.isServiceEnabled ? (parent.width - width - 2) : 2
                                color: "white"
                                Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                layer.enabled: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: !root.isPending && !root.isTogglePending
                                onClicked: runToggleCmd(root.isServiceEnabled ? "disable" : "enable")
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Kirigami.Theme.separatorColor
                        opacity: 0.4
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        Layout.bottomMargin: Kirigami.Units.smallSpacing
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Kirigami.Icon {
                            source: root.isServiceActive ? "process-stop" : "process-start"
                            fallback: root.isServiceActive ? "media-playback-stop" : "media-playback-start"
                            implicitWidth: Kirigami.Units.iconSizes.small
                            implicitHeight: Kirigami.Units.iconSizes.small
                            opacity: 0.7
                        }

                        ColumnLayout {
                            spacing: 0
                            PlasmaComponents.Label { text: "Daemon" }
                            PlasmaComponents.Label {
                                text: root.isServiceActive ? "warp-svc corriendo" : "warp-svc detenido"
                                font.pixelSize: Kirigami.Units.gridUnit * 0.6
                                opacity: 0.55
                            }
                        }

                        Item { Layout.fillWidth: true }

                        PlasmaComponents.Button {
                            text: root.isServiceActive ? "Apagar" : "Iniciar"
                            icon.name: root.isServiceActive ? "process-stop" : "system-run"
                            enabled: !root.isPending && !root.isTogglePending
                            flat: true
                            onClicked: {
                                let action = root.isServiceActive ? "stop" : "start";
                                root.isPending = true;
                                let ts = new Date().toLocaleTimeString([],{hour:'2-digit',minute:'2-digit',second:'2-digit'});
                                lastLog = "[" + ts + "] pkexec systemctl " + action + " warp-svc";
                                sudoExecutable.connectSource("bash -c 'pkexec systemctl " + action + " warp-svc; echo __done__'");
                                pendingGuard.restart();
                            }
                        }
                    }
                }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Kirigami.Units.smallSpacing
                color: Kirigami.Theme.backgroundColor
                border.color: Kirigami.Theme.separatorColor
                border.width: 1
                opacity: 0.75
                clip: true

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    PlasmaComponents.TextArea {
                        text: root.lastLog
                        readOnly: true
                        font.family: "Monospace"
                        font.pixelSize: Kirigami.Units.gridUnit * 0.65
                        wrapMode: TextEdit.Wrap
                        background: null
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                PlasmaComponents.ToolButton {
                    icon.name: "view-refresh"
                    flat: true
                    enabled: !root.isPending
                    onClicked: updateStatus()
                    PlasmaComponents.ToolTip { text: "Actualizar estado" }
                }

                Item { Layout.fillWidth: true }

                PlasmaComponents.Label {
                    text: "v1.0.0 · 500Byte"
                    font.pixelSize: Kirigami.Units.gridUnit * 0.55
                    opacity: 0.35
                }
            }
        }
    }
}
