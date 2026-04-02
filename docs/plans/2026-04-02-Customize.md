# Charter Toolbar Customization Guide

## Where toolbar code lives

Charter uses two files for toolbar items:

| File | Purpose |
|------|---------|
| `Charter/Views/Main/ContentView.swift` | Top-level window toolbar (settings gear, search bar) |
| `Charter/Views/Main/ProjectListView.swift` | Content-column toolbar (New Project, Export, Import buttons) |

Because Charter is a three-column `NavigationSplitView`, each column can contribute its own `.toolbar {}` block. Items are merged by macOS into the unified window toolbar.

---

## Adding the app name to the toolbar

The cleanest approach is a `ToolbarItem` with `.principal` placement. This puts a `Text` or `Label` centered in the toolbar title area.

Add this inside the `.toolbar {}` block in `ContentView.swift`:

```swift
.toolbar {
    // Existing item
    ToolbarItem(placement: .automatic) {
        SettingsGearButton()
    }

    // App name in the title position
    ToolbarItem(placement: .principal) {
        Text("Charter")
            .font(.headline)
            .foregroundStyle(Color.themeFg)
    }
}
```

If you prefer an icon alongside the name, use `Label` instead of `Text`:

```swift
ToolbarItem(placement: .principal) {
    Label("Charter", systemImage: "chart.bar.doc.horizontal")
        .font(.headline)
        .foregroundStyle(Color.themeFg)
}
```

> **Note:** `.principal` is ignored on macOS 12 and earlier; it works correctly on macOS 13+.

---

## Adding additional icon buttons

Icon-only toolbar buttons follow the same pattern as the existing export/import buttons in `ProjectListView.swift`. Add a new `ToolbarItem` block inside any `.toolbar {}` closure:

```swift
ToolbarItem {
    Button {
        // your action here
    } label: {
        Image(systemName: "bell")
    }
    .help("Notifications")  // tooltip shown on hover
}
```

### Placement options

| Placement | Where it appears |
|-----------|-----------------|
| `.primaryAction` | Right side, highlighted (used for "New Project") |
| `.automatic` | macOS decides — typically right side |
| `.principal` | Centered title area |
| `.navigation` | Left/navigation area |
| `.confirmationAction` | Confirm-style (sheets/dialogs) |

### Recommended placements for new icons

- Additional action buttons (e.g., filter, refresh): use `.automatic` in `ProjectListView.swift` alongside the existing export/import items.
- Global actions (e.g., notifications, help): use `.automatic` in `ContentView.swift` alongside the existing gear button.

---

## Full example: app name + two extra icons

Below is the updated `.toolbar {}` block for `ContentView.swift` with a centered app name and a notifications button added next to the existing gear:

```swift
.toolbar {
    ToolbarItem(placement: .principal) {
        Text("Charter")
            .font(.headline)
    }

    ToolbarItem(placement: .automatic) {
        Button {
            // show notifications or activity feed
        } label: {
            Image(systemName: "bell")
        }
        .help("Activity")
    }

    ToolbarItem(placement: .automatic) {
        SettingsGearButton()
    }
}
```

And in `ProjectListView.swift`, adding a filter button alongside the existing items:

```swift
ToolbarItem {
    Button {
        showFilter.toggle()
    } label: {
        Image(systemName: "line.3.horizontal.decrease.circle")
    }
    .help("Filter projects")
}
```

---

## Tips

- Use `.help("…")` on every `Button` — it provides the hover tooltip and improves accessibility.
- Prefer `Image(systemName:)` for icon-only buttons; use `Label` when you want icon + text (macOS will hide the text in compact toolbars automatically).
- Browse available SF Symbols with the SF Symbols app or at [developer.apple.com/sf-symbols](https://developer.apple.com/sf-symbols/).
- Keep the `SettingsGearButton` as the rightmost item — users expect the gear at the far right.
