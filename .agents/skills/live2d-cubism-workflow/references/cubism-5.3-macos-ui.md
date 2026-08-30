# Cubism Editor 5.3 on macOS

## Proven environment

- App bundle identifier: `com.live2d.cubism.CECubismEditorApp`
- Verified Editor: 5.3.03 PRO trial on Apple Silicon macOS
- UI scale observed after restart: 100%
- Current project model names use stable lowercase IDs such as `eye_left`, `eye_right`, and `body_base`.

Use the `computer-use` skill and its `node_repl` wrapper for every UI action. Do not replace it with AppleScript, `osascript`, or CGEvent synthesis unless the user explicitly requests that technology.

## Initialize Computer Use

```js
if (!globalThis.sky) {
  var { setupComputerUseRuntime } = await import(
    "/Users/fengzhuo/.codex/plugins/cache/openai-bundled/computer-use/1.0.1000550/scripts/computer-use-client.mjs"
  );
  await setupComputerUseRuntime({ globals: globalThis });
}
var app = "com.live2d.cubism.CECubismEditorApp";
var state = await sky.get_app_state({ app, disableDiff: true });
```

The plugin cache version can change. If that path no longer exists, locate and read the currently installed `computer-use` skill before initializing.

## Invoke native menus reliably

The full Java accessibility tree contains menu definitions that may be offscreen. Clicking those entries can return `cannotClickOffscreenElement`. Open the native macOS menu bar entry—the final exact menu-name occurrence—then resolve the fresh menu item ID.

```js
var state = await sky.get_app_state({ app, disableDiff: true });
var modelingLines = state.text
  .split("\n")
  .filter((line) => /^\s+\d+ 建模$/.test(line));
var modelingMenuId = Number(modelingLines.at(-1).trim().split(" ")[0]);
await sky.click({ app, element_index: modelingMenuId });

var menu = await sky.get_app_state({ app, disableDiff: true });
var autoLine = menu.text
  .split("\n")
  .find((line) => line.includes("自动网格生成..."));
var autoId = Number(autoLine.trim().split(" ")[0]);
await sky.click({ app, element_index: autoId });
```

Apply the same pattern to `显示 → 显示图形网格顶点` and `显示 → 聚焦到选中的对象`. Never reuse an element index after another UI action.

## Interpret the automatic mesh window

- Window title: `自动网格生成`
- Built-in preset names visible through accessibility: `标准`, `变形(轻)`, `变形(重)`.
- The right-facing `>` button executes generation.
- Closing the window after execution does not undo an already generated mesh.
- A default spacing of 100 can leave a small eye with only a few points. Candidate eye values are `20, 20, 5, 5, 3, 8, 1` from top to bottom, but treat these as an unverified starting point and visually inspect the result.
- Cubism 5.3 may expose all seven numeric fields as one accessibility text element. If coordinate focusing cannot edit them, ask the user to enter the seven values and click `>`; then resume inspection.

## Verify selection and mesh outcome

The Inspector `名称` and `ID` are authoritative. A visually left/right eye can be named from the character's perspective or the viewer's perspective, so report the actual ID.

After generation:

1. Close the generator.
2. Enable mesh vertices.
3. Focus the selected object.
4. Confirm that internal vertices and triangles exist, not only the bounding box.
5. Check that contours follow the opaque pixels without swallowing large transparent regions.
6. Save with `super+s`, re-read the window state, and persist a checkpoint outside `/tmp`.

## Known accessibility defect

Cubism's Java accessibility bridge can emit repeated stack traces including:

```text
AccessibleHTML$TableElementInfo
Cannot read the array length because "this.grid" is null
```

These errors commonly appear while reading palette tables or menu state. Avoid repeated full-tree reads when a small state slice or screenshot is sufficient. Re-read fresh state after a failed action. Do not restart or discard the model unless the actual UI is unresponsive or model data is visibly wrong.
