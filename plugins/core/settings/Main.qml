// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Shell as K
import qs.services as S
import qs.components as C

// Settings forms generated from each plugin's schema (ADR-0004).
Item {
    id: root
    property var plugin: null
    property string slot: ""
    property var host: null

    property bool shown: false
    onShownChanged: if (shown) K.Theme.scan()
    readonly property var targetScreen: Quickshell.screens.find(s => s.name === S.Workspaces.focusedOutput) || null

    IpcHandler {
        target: "settings"
        function toggle(): void { root.shown = !root.shown; }
        function open(): void { root.shown = true; }
        function close(): void { root.shown = false; }
    }

    onPluginChanged: if (plugin) K.Shell.registerPaletteAction(plugin, { title: "Open settings", exec: () => { root.shown = true; } })
    Component.onDestruction: if (plugin) K.Shell.unregisterPaletteActions(plugin)

    LazyLoader {
        active: root.shown

        PanelWindow {
            id: win
            screen: root.targetScreen
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "kotilo-settings"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            property var schemas: ({})             // plugin id -> parsed schema
            property int selected: 1                // row 0 is a heading
            property bool editing: false
            property string refused: ""

            readonly property var entries: {
                const plugins = root.host ? root.host.plugins : {};
                return Object.keys(plugins).filter(id => plugins[id].enabled && plugins[id].manifest.settingsSchema)
                    .map(id => ({ id: id, name: plugins[id].manifest.name, dir: plugins[id].dir, file: plugins[id].manifest.settingsSchema }))
                    .sort((a, b) => a.name.localeCompare(b.name));
            }

            // Settings that belong to the shell. Each key has a writer, since they live outside `plugins`.
            readonly property var generalSchema: ({ properties: {
                theme: { title: "Theme", enum: K.Theme.schemes.map(s => s.id) },
                propagate: { type: "boolean", title: "Apply the theme to other apps", default: true },
                animations: { type: "boolean", title: "Animations", default: true },
                position: { title: "Bar position", enum: ["top", "bottom"], default: "top" },
                height: { type: "integer", title: "Bar height", default: 40, minimum: 28, maximum: 64 }
            } })
            readonly property var generalWriters: ({
                theme: v => K.Settings.setTheme(v),
                propagate: v => K.Settings.setGeneral("theme", "propagate", v),
                animations: v => K.Settings.setGeneral("", "animations", v),
                position: v => K.Settings.setGeneral("bar", "position", v),
                height: v => K.Settings.setGeneral("bar", "height", v)
            })

            readonly property var rows: {
                const g = K.Settings.global;
                const plugins = g.plugins || {};
                const theme = g.theme || {}, bar = g.bar || {};
                const list = [{ heading: "General" }];
                for (const f of K.Shell.formFields(generalSchema, { theme: K.Theme.schemeId, propagate: theme.propagate, animations: g.animations,
                                                                    position: bar.position, height: bar.height }))
                    list.push({ field: f, pluginId: "" });
                for (const e of entries) {
                    const fields = K.Shell.formFields(schemas[e.id], plugins[e.id]);
                    if (!fields.length) continue;
                    list.push({ heading: e.name });
                    for (const f of fields) list.push({ field: f, pluginId: e.id });
                }
                return list;
            }
            onRowsChanged: if (!rows[selected] || !rows[selected].field) selected = K.Shell.formMove(rows, selected, 1)

            readonly property var current: rows[selected] && rows[selected].field ? rows[selected] : null

            // One FileView per schema, gone with the panel.
            Instantiator {
                model: win.entries
                delegate: FileView {
                    required property var modelData
                    path: modelData.dir + "/" + modelData.file
                    printErrors: false
                    onLoaded: {
                        try {
                            win.schemas = Object.assign({}, win.schemas, { [modelData.id]: JSON.parse(text()) });
                        } catch (e) {
                            K.Log.warn("settings schema of " + modelData.id + " is not valid JSON", "settings");
                        }
                    }
                }
            }

            function move(delta) {
                refused = "";
                selected = K.Shell.formMove(rows, selected, delta);
            }

            function write(value) {
                if (K.Settings.parseError || !current) return;
                if (current.pluginId) K.Settings.set(current.pluginId, current.field.key, value);
                else generalWriters[current.field.key](value);
            }

            function adjust(delta) {
                if (!current) return;
                const value = K.Shell.formStep(current.field, delta);
                if (value !== undefined) write(value);
            }

            function activate() {
                if (!current || K.Settings.parseError) return;
                const kind = current.field.kind;
                if (kind === "boolean" || kind === "enum") adjust(1);
                else if (kind !== "other") startEdit();
            }

            function startEdit() {
                input.text = K.Shell.formText(current.field);
                refused = "";
                editing = true;
                input.selectAll();
                input.forceActiveFocus();
            }

            function stopEdit() {
                editing = false;
                keys.forceActiveFocus();
            }

            function commitEdit() {
                const result = K.Shell.formParse(current.field, input.text);
                if (!result.ok) { refused = current.field.schema.type === "array" || current.field.schema.type === "object"
                    ? "That is not valid JSON for this setting." : "That value does not fit this setting."; return; }
                write(result.value);
                stopEdit();
            }

            MouseArea { anchors.fill: parent; onClicked: root.shown = false }

            C.Surface {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.round(parent.height * 0.08)
                width: Math.min(640, parent.width - 2 * K.Theme.space.lg)
                height: Math.round(parent.height * 0.84)
                clip: true

                NumberAnimation on opacity { from: 0; to: 1; duration: K.Theme.animMs }
                MouseArea { anchors.fill: parent }

                Item {
                    id: keys
                    anchors.fill: parent
                    focus: true
                    Component.onCompleted: forceActiveFocus()

                    Keys.onPressed: event => {
                        const key = event.key;
                        const ctrl = event.modifiers & Qt.ControlModifier;
                        if (key === Qt.Key_Escape) root.shown = false;
                        else if (key === Qt.Key_Down || key === Qt.Key_Tab || (ctrl && key === Qt.Key_N)) win.move(1);
                        else if (key === Qt.Key_Up || key === Qt.Key_Backtab || (ctrl && key === Qt.Key_P)) win.move(-1);
                        else if (key === Qt.Key_Right) win.adjust(1);
                        else if (key === Qt.Key_Left) win.adjust(-1);
                        else if (key === Qt.Key_Return || key === Qt.Key_Enter || key === Qt.Key_Space) win.activate();
                        else return;
                        event.accepted = true;
                    }

                    C.Label {
                        id: heading
                        anchors { top: parent.top; left: parent.left; margins: K.Theme.space.lg }
                        font.pixelSize: K.Theme.font.size + 2
                        text: "Settings"
                    }

                    C.Label {
                        id: warning
                        anchors {
                            top: heading.bottom; left: parent.left; right: parent.right
                            leftMargin: K.Theme.space.lg; rightMargin: K.Theme.space.lg
                            topMargin: visible ? K.Theme.space.sm : 0
                        }
                        visible: K.Settings.parseError
                        wrapMode: Text.Wrap
                        color: K.Theme.state.warning
                        text: "settings.json has a syntax error, so changes are off until it is fixed."
                    }

                    ListView {
                        id: list
                        anchors {
                            top: warning.visible ? warning.bottom : heading.bottom; bottom: footer.top; left: parent.left; right: parent.right
                            topMargin: K.Theme.space.md; bottomMargin: K.Theme.space.md
                            leftMargin: K.Theme.space.lg; rightMargin: K.Theme.space.lg
                        }
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: win.rows
                        currentIndex: win.selected
                        highlightMoveDuration: 0

                        delegate: Item {
                            id: row
                            required property var modelData
                            required property int index
                            readonly property var field: modelData.field || null
                            readonly property bool chosen: index === win.selected
                            width: ListView.view.width
                            height: field ? 32 : 40

                            C.Label {
                                visible: !row.field
                                anchors { left: parent.left; bottom: parent.bottom; bottomMargin: K.Theme.space.xs }
                                secondary: true
                                textFormat: Text.PlainText
                                font.pixelSize: K.Theme.font.size - 2
                                text: row.modelData.heading || ""
                            }

                            Rectangle {
                                visible: !!row.field
                                anchors.fill: parent
                                radius: K.Theme.radius.sm
                                color: row.chosen ? K.Theme.surface[1] : "transparent"

                                C.Label {
                                    anchors { left: parent.left; right: value.left; leftMargin: K.Theme.space.sm; rightMargin: K.Theme.space.md; verticalCenter: parent.verticalCenter }
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                    text: row.field ? row.field.title : ""
                                }
                                C.Label {
                                    id: value
                                    anchors { right: parent.right; rightMargin: K.Theme.space.sm; verticalCenter: parent.verticalCenter }
                                    width: Math.min(implicitWidth, row.width * 0.5)
                                    elide: Text.ElideRight
                                    textFormat: Text.PlainText
                                    secondary: !row.field || row.field.kind === "other"
                                    mono: !!row.field && row.field.kind !== "other"
                                    text: row.field ? K.Shell.formDisplay(row.field) : ""
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (win.editing) win.stopEdit();
                                        win.selected = row.index;
                                        win.activate();
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        id: footer
                        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: K.Theme.space.lg }
                        spacing: K.Theme.space.xs

                        C.Label {
                            width: parent.width
                            visible: text.length > 0
                            wrapMode: Text.Wrap
                            secondary: true
                            textFormat: Text.PlainText
                            font.pixelSize: K.Theme.font.size - 2
                            text: win.current ? win.current.field.description : ""
                        }
                        C.Label {
                            width: parent.width
                            visible: win.refused.length > 0
                            color: K.Theme.state.warning
                            font.pixelSize: K.Theme.font.size - 2
                            text: win.refused
                        }
                        Rectangle {
                            width: parent.width
                            height: win.editing ? 32 : 0
                            visible: win.editing
                            radius: K.Theme.radius.sm
                            color: K.Theme.surface[0]
                            border.width: 1
                            border.color: K.Theme.accent.primary

                            TextInput {
                                id: input
                                anchors { fill: parent; leftMargin: K.Theme.space.sm; rightMargin: K.Theme.space.sm }
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true
                                color: K.Theme.text.primary
                                selectionColor: K.Theme.accent.primary
                                selectedTextColor: K.Theme.text.onAccent
                                font.family: K.Theme.font.mono
                                font.pixelSize: K.Theme.font.size
                                activeFocusOnTab: false
                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Escape) { win.refused = ""; win.stopEdit(); }
                                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) win.commitEdit();
                                    else return;
                                    event.accepted = true;
                                }
                            }
                        }
                        C.Label {
                            secondary: true
                            font.pixelSize: K.Theme.font.size - 2
                            text: win.editing ? "↵ save   esc cancel" : "↑↓ move   ←→ change   ↵ edit   esc close"
                        }
                    }
                }
            }
        }
    }
}
