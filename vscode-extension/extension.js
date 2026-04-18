const vscode = require("vscode");

function activate(context) {
  context.subscriptions.push(
    vscode.window.registerUriHandler({
      async handleUri(uri) {
        const params = new URLSearchParams(uri.query);
        const pidStr = params.get("pid");
        const pid = Number.parseInt(pidStr, 10);
        if (!Number.isFinite(pid)) {
          vscode.window.showWarningMessage(
            `Claude Focus: invalid pid "${pidStr}"`,
          );
          return;
        }

        for (const term of vscode.window.terminals) {
          let termPid;
          try {
            termPid = await term.processId;
          } catch {
            continue;
          }
          if (termPid === pid) {
            term.show(false);
            return;
          }
        }
      },
    }),
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
