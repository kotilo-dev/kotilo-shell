#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""The Claude Code hook in scripts/kotilo-agent against a stand-in shell socket (ADR-0013)."""
import json, os, socket, subprocess, sys, tempfile, threading

SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "scripts", "kotilo-agent")
tmp = tempfile.TemporaryDirectory()
path = os.path.join(tmp.name, "agents.sock")

class Shell:
    """Records messages and answers approvals with `answer`: True, False, or None to hang up."""
    def __init__(self, answer=None):
        self.answer, self.messages = answer, []
        self.server = socket.socket(socket.AF_UNIX)
        self.server.bind(path)
        self.server.listen()
        threading.Thread(target=self.serve, daemon=True).start()
    def serve(self):
        while True:
            try: client, _ = self.server.accept()
            except OSError: return
            with client:
                message = json.loads(client.makefile().readline())
                self.messages.append(message)
                if message["type"] == "agent.approval" and self.answer is not None:
                    client.sendall((json.dumps({"type": "agent.approval.reply", "id": message["id"], "allow": self.answer}) + "\n").encode())
    def close(self):
        self.server.shutdown(socket.SHUT_RDWR); self.server.close(); os.unlink(path)

def run(event, **env):
    text = event if isinstance(event, str) else json.dumps(event)
    clean = {k: v for k, v in os.environ.items() if not k.startswith("AGENTHUB")}
    done = subprocess.run([sys.executable, "-I", SCRIPT, "hook", "claude"], input=text, capture_output=True, text=True,
                          timeout=10, env={**clean, "KOTILO_AGENT_SOCKET": path, **env})
    assert done.returncode == 0 and done.stderr == "", done
    return done.stdout

def permission(**over):
    return {"hook_event_name": "PermissionRequest", "session_id": "s1", "cwd": "/src/demo", "tool_name": "Bash",
            "tool_input": {"command": "git push", "description": "harmless, trust me"}, **over}

def behavior(out):
    assert json.loads(out)["hookSpecificOutput"]["hookEventName"] == "PermissionRequest"
    return json.loads(out)["hookSpecificOutput"]["decision"]["behavior"]

# Allow and deny reach Claude Code, and the request shows the command, not the claimed description.
shell = Shell(True)
assert behavior(run(permission())) == "allow"
status, request = shell.messages
assert (status["id"], status["state"], status["tool"], status["project"]) == ("s1", "awaiting", "Claude Code", "demo")
assert request["command"] == "git push" and request["cwd"] == "/src/demo" and request["agent"] == "s1"
shell.close()
shell = Shell(False)
assert behavior(run(permission())) == "deny"

# Each request has its own id: the shell drops a repeated one, and subagents share a session.
run(permission())
assert shell.messages[1]["id"] != shell.messages[3]["id"] and all(m["id"].startswith("s1") for m in shell.messages)

# Other tools show their whole input.
shell.messages.clear()
run(permission(tool_name="Write", tool_input={"file_path": "/a", "content": "secret plan"}))
assert shell.messages[1]["command"].startswith("Write\n") and "secret plan" in shell.messages[1]["command"]

# Text that would not fit is never cut, since a cut request could hide what is approved.
shell.messages.clear()
assert run(permission(tool_input={"command": "x" * 8193})) == ""
assert [m["type"] for m in shell.messages] == ["agent.status"]

# Desktop answers in its own panes, and its internal runs stay invisible.
shell.messages.clear()
assert run(permission(), AGENTHUB_PANE_ID="p1") == ""
assert [m["type"] for m in shell.messages] == ["agent.status"]
shell.messages.clear()
assert run(permission(), AGENTHUB_INTERNAL="1") == "" and shell.messages == []
shell.close()

# No decision unless the shell gave one.
shell = Shell(None)
assert run(permission()) == ""
shell.close()
assert run(permission()) == ""                  # shell not running
for bad in ("", "not json", "[]", "{}", json.dumps(permission(session_id=5))):
    assert run(bad) == "", bad

# States.
shell = Shell()
for event, state in (("SessionStart", "idle"), ("UserPromptSubmit", "running"), ("PostToolUse", "running"),
                     ("PostToolUseFailure", "running"), ("Stop", "idle"), ("StopFailure", "idle"), ("SessionEnd", "done")):
    shell.messages.clear()
    run({"hook_event_name": event, "session_id": "s1", "cwd": "/src/demo/"})
    assert shell.messages[0]["state"] == state and shell.messages[0]["project"] == "demo", event
shell.messages.clear()
run({"hook_event_name": "Notification", "session_id": "s1", "notification_type": "idle_prompt"})
assert shell.messages[0]["state"] == "idle"
shell.messages.clear()
run({"hook_event_name": "Notification", "session_id": "s1", "notification_type": "permission_prompt"})
assert shell.messages == []
shell.close()
print("kotilo-agent hook ok")
