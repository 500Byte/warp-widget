.import org.kde.plasma.plasma5support as Plasma5Support

function updateStatus(executable) {
    executable.connectSource("systemctl is-active warp-svc");
    executable.connectSource("systemctl is-enabled warp-svc");
    executable.connectSource("warp-cli status");
}

function parseStatus(sourceName, data, root) {
    let output = data.stdout.trim();
    let error = data.stderr.trim();
    let fullOutput = (output + " " + error).toLowerCase();

    if (sourceName === "systemctl is-active warp-svc") {
        root.isServiceActive = (output === "active");
    } else if (sourceName === "systemctl is-enabled warp-svc") {
        root.isServiceEnabled = (output === "enabled");
    } else if (sourceName === "warp-cli status") {
        root.isVpnConnected = (fullOutput.includes("connected") && 
                              !fullOutput.includes("disconnected") && 
                              !fullOutput.includes("unable to connect"));
    } else {
        return formatLog(sourceName, output, error);
    }
    return null;
}

function formatLog(cmd, output, error) {
    let timestamp = new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit', second:'2-digit'});
    return "[" + timestamp + "] " + cmd + "\n" + (output ? "> " + output : "") + (error ? "\nERR: " + error : "");
}

function getStatusText(isConnected, isActive) {
    if (isConnected) return "VPN CONECTADA";
    if (isActive) return "VPN DESCONECTADA";
    return "SERVICIO DETENIDO";
}
