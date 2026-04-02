"""
charter_demo.py — PyAutoGUI demo recording script for Charter

SETUP
─────
  pip install pyautogui pillow            # pillow is required by pyautogui on macOS
  brew install gifski                     # optional: convert .mov → .gif after recording

WORKFLOW
────────
  1. Open QuickTime → File → New Screen Recording → select Charter's window
  2. Start QuickTime recording
  3. Run:  mise run demo
     (or:  python scripts/charter_demo.py)
  4. Stop QuickTime recording
  5. Optional: run  mise run gif  to convert to a GIF

CALIBRATION
───────────
  Before running for real, run the calibration helper:
      python scripts/charter_demo.py --calibrate

  Move your mouse to each UI element and press Enter. The script will
  print the coordinates to update the COORDS dict below.

  Alternatively, open Accessibility Inspector (Xcode → Open Developer Tool)
  and hover over elements to read their on-screen position.

IMPORTANT macOS PERMISSIONS
────────────────────────────
  System Settings → Privacy & Security → Accessibility → add Terminal (or iTerm)
  Without this, pyautogui cannot send clicks/keystrokes to other apps.
"""

import pyautogui
import time
import sys
import subprocess
from pathlib import Path

# ── Safety net ─────────────────────────────────────────────────────────────────
# Move mouse to top-left corner at any point to abort (FAILSAFE = True is default)
pyautogui.FAILSAFE = True

# ── Global timing ──────────────────────────────────────────────────────────────
# Add a small pause between every pyautogui action. Increase if your machine
# is slow or animations need to finish before the next click.
pyautogui.PAUSE = 0.4   # seconds between each action

# Longer pauses for UI transitions (opening windows, loading views)
TRANSITION = 1.2        # wait after opening a new view/sheet
BEAT       = 0.6        # short dramatic pause for screen recording "breathing room"
LONG       = 2.0        # pause on interesting content so viewers can read it

# ── Coordinate map ─────────────────────────────────────────────────────────────
# All (x, y) coordinates need to be calibrated for YOUR screen and window position.
# Run:  python scripts/charter_demo.py --calibrate  to measure them.
#
# These are placeholder values — replace with your actual measurements.
# Tip: position Charter's main window in the same spot each run so coords stay stable.
COORDS = {
    # ── App / menu bar ──
    "menu_bar_icon":        (1200, 11),   # Charter briefcase icon in menu bar
    "dock_icon":            (800,  780),  # Charter icon in the Dock

    # ── Main window — sidebar ──
    "new_project_btn":      (110,  120),  # + button to create a new project
    "project_row_first":    (110,  200),  # first project row in the sidebar
    "search_field":         (110,  80),   # search/filter field at top of sidebar

    # ── New project sheet ──
    "sheet_name_field":     (540,  280),  # project name text field
    "sheet_client_field":   (540,  330),  # client / company field
    "sheet_template_picker":(540,  380),  # template dropdown
    "sheet_create_btn":     (640,  520),  # "Create Project" button

    # ── Project detail — tab bar ──
    "tab_overview":         (340,  190),  # Overview tab
    "tab_contacts":         (440,  190),  # Contacts tab
    "tab_engagements":      (540,  190),  # Engagements tab
    "tab_tasks":            (640,  190),  # Tasks tab
    "tab_notes":            (740,  190),  # Notes tab

    # ── Contacts tab ──
    "add_contact_btn":      (860,  220),  # + add contact button
    "contact_name_field":   (540,  300),  # name field in add contact sheet
    "contact_role_field":   (540,  350),  # role/title field
    "contact_email_field":  (540,  400),  # email field
    "contact_save_btn":     (640,  500),  # Save button

    # ── Engagements tab ──
    "add_engagement_btn":   (860,  220),  # + log engagement button
    "engagement_type":      (540,  280),  # type picker (Call / Meeting / Email)
    "engagement_summary":   (540,  380),  # summary text area
    "engagement_save_btn":  (640,  520),  # Save button

    # ── Tasks tab ──
    "add_task_btn":         (860,  220),  # + add task button
    "task_name_field":      (540,  300),  # task name field in sheet
    "task_save_btn":        (640,  400),  # Save button
    "task_checkbox_first":  (360,  280),  # checkbox on first task row

    # ── Notes tab ──
    "notes_editor":         (600,  380),  # click to focus the notes text area

    # ── Stage picker (Overview tab) ──
    "stage_picker":         (540,  260),  # stage dropdown in overview

    # ── Menu bar popover ──
    "popover_log_btn":      (640,  320),  # "Log Engagement" button in popover
    "popover_note_btn":     (540,  320),  # "+ Note" button in popover
    "popover_task_btn":     (490,  320),  # "+ Task" button in popover
}

# ── Helpers ────────────────────────────────────────────────────────────────────

def click(target: str, *, double=False, offset=(0, 0)):
    """
    Click a named coordinate from the COORDS map.
    Pass double=True for double-click (e.g. to open a row).
    Pass offset=(dx, dy) to nudge from the base coordinate.
    """
    x, y = COORDS[target]
    x += offset[0]
    y += offset[1]
    if double:
        pyautogui.doubleClick(x, y)
    else:
        pyautogui.click(x, y)


def type_text(text: str, *, clear_first=True):
    """
    Type a string. If clear_first=True, select-all before typing
    so any placeholder text gets replaced cleanly.
    """
    if clear_first:
        pyautogui.hotkey("cmd", "a")
        time.sleep(0.1)
    # pyautogui.write() doesn't handle unicode well on macOS;
    # pyautogui.typewrite() is safer for plain ASCII.
    # For text with special chars, use pyperclip + cmd+v instead.
    pyautogui.typewrite(text, interval=0.05)


def paste_text(text: str):
    """
    Paste text via clipboard — more reliable than typewrite for
    longer strings or strings with special characters.
    """
    import subprocess
    proc = subprocess.run(
        ["pbcopy"],
        input=text.encode("utf-8"),
        check=True,
    )
    pyautogui.hotkey("cmd", "v")


def wait(seconds: float = BEAT, *, reason: str = ""):
    """Named pause — makes the script read like a storyboard."""
    if reason:
        print(f"  ⏸  waiting {seconds}s — {reason}")
    time.sleep(seconds)


def press(*keys):
    """Thin wrapper around pyautogui.hotkey for readability."""
    pyautogui.hotkey(*keys)


def focus_app(app_name: str = "Charter"):
    """Bring the app to the front using AppleScript."""
    subprocess.run(
        ["osascript", "-e", f'tell application "{app_name}" to activate'],
        check=True,
    )
    wait(TRANSITION, reason=f"waiting for {app_name} to activate")


def screenshot(name: str):
    """Save a screenshot to ./demo-frames/ for debugging."""
    out = Path("demo-frames")
    out.mkdir(exist_ok=True)
    path = out / f"{name}.png"
    pyautogui.screenshot(str(path))
    print(f"  📸  saved {path}")


# ── Demo flow ───────────────────────────────────────────────────────────────────

def demo_open_app():
    """Step 1 — Bring Charter to the foreground."""
    print("▶ Step 1: Opening Charter")
    focus_app("Charter")          # replace "Charter" with "Manifest" if you
                                   # haven't renamed the app bundle yet


def demo_create_project():
    """Step 2 — Create a new project from the New Client Engagement template."""
    print("▶ Step 2: Creating a new project")

    # Click the + button in the sidebar
    click("new_project_btn")
    wait(TRANSITION, reason="new project sheet opening")

    # Fill in the project name
    click("sheet_name_field")
    type_text("Acme Corp Migration")
    wait(BEAT)

    # Fill in the client field
    click("sheet_client_field")
    type_text("Acme Corporation")
    wait(BEAT)

    # Pick a template (assumes a picker/dropdown — adjust if it's a list)
    click("sheet_template_picker")
    wait(BEAT)
    # Arrow down to select the first template, then Enter to confirm
    pyautogui.press("down")
    wait(0.3)
    pyautogui.press("return")
    wait(BEAT)

    # Confirm / create
    click("sheet_create_btn")
    wait(TRANSITION, reason="project view loading")
    screenshot("02-project-created")


def demo_overview():
    """Step 3 — Show the overview tab, advance the stage."""
    print("▶ Step 3: Showing overview + setting stage")

    click("tab_overview")
    wait(BEAT)

    # Click the stage picker and select "Initial Delivery"
    click("stage_picker")
    wait(0.5)
    pyautogui.press("down")       # move from Discovery → Initial Delivery
    pyautogui.press("return")
    wait(TRANSITION, reason="stage update")

    wait(LONG, reason="let viewers read the overview")
    screenshot("03-overview")


def demo_add_contact():
    """Step 4 — Add a contact on the Contacts tab."""
    print("▶ Step 4: Adding a contact")

    click("tab_contacts")
    wait(BEAT)
    screenshot("04a-contacts-empty")

    click("add_contact_btn")
    wait(TRANSITION, reason="add contact sheet opening")

    click("contact_name_field")
    type_text("Sarah Chen")
    wait(BEAT)

    click("contact_role_field")
    type_text("Technical Lead")
    wait(BEAT)

    click("contact_email_field")
    type_text("schen@acmecorp.example")
    wait(BEAT)

    click("contact_save_btn")
    wait(TRANSITION, reason="contact saving")

    wait(LONG, reason="show the contact in the list")
    screenshot("04b-contact-added")


def demo_log_engagement():
    """Step 5 — Log an engagement on the Engagements tab."""
    print("▶ Step 5: Logging an engagement")

    click("tab_engagements")
    wait(BEAT)

    click("add_engagement_btn")
    wait(TRANSITION, reason="engagement sheet opening")

    # Pick type = "Call" (assumes picker is already on Call or use arrow keys)
    click("engagement_type")
    wait(0.4)
    pyautogui.press("return")     # confirm current selection
    wait(BEAT)

    # Write a summary
    click("engagement_summary")
    paste_text(
        "Discovery call with Sarah Chen. Discussed data migration scope, "
        "timeline constraints, and phased rollout approach. Follow-up: "
        "share architecture diagram by EOW."
    )
    wait(BEAT)

    click("engagement_save_btn")
    wait(TRANSITION, reason="engagement saving")

    wait(LONG, reason="show the engagement log")
    screenshot("05-engagement-logged")


def demo_tasks():
    """Step 6 — Show the task list, check one off."""
    print("▶ Step 6: Working with tasks")

    click("tab_tasks")
    wait(BEAT)

    # If template pre-populated tasks, they should already be here.
    # Add a manual task as well.
    click("add_task_btn")
    wait(TRANSITION, reason="task sheet opening")

    click("task_name_field")
    type_text("Share architecture diagram with Sarah")
    wait(BEAT)

    click("task_save_btn")
    wait(TRANSITION, reason="task saving")

    wait(BEAT, reason="let the task appear")

    # Check off the first (template-generated) task
    click("task_checkbox_first")
    wait(BEAT)

    wait(LONG, reason="show task list with one checked")
    screenshot("06-tasks")


def demo_notes():
    """Step 7 — Drop a markdown note."""
    print("▶ Step 7: Adding a note")

    click("tab_notes")
    wait(BEAT)

    click("notes_editor")
    wait(0.3)

    # Select all existing content first, then replace
    press("cmd", "a")
    wait(0.2)

    paste_text(
        "## Acme Corp Migration\n\n"
        "### Open questions\n"
        "- What is the target go-live date?\n"
        "- Is phased migration acceptable or do they need a hard cutover?\n"
        "- Who owns sign-off on the architecture diagram?\n\n"
        "### Decisions\n"
        "- Starting with Discovery → Initial Delivery sprint\n"
        "- Sarah Chen is primary technical contact\n"
    )
    wait(LONG, reason="let viewers read the notes")
    screenshot("07-notes")


def demo_menu_bar():
    """Step 8 — Show quick capture via the menu bar popover."""
    print("▶ Step 8: Menu bar quick capture")

    # Click the Charter icon in the menu bar to open the popover
    click("menu_bar_icon")
    wait(TRANSITION, reason="popover opening")

    wait(LONG, reason="show the popover with the active project")
    screenshot("08a-popover")

    # Click Log Engagement from the popover
    click("popover_log_btn")
    wait(TRANSITION, reason="quick engagement sheet opening")

    wait(BEAT, reason="show the sheet")
    screenshot("08b-popover-log")

    # Dismiss with Escape — we don't want to actually save a blank engagement
    pyautogui.press("escape")
    wait(BEAT)

    # Close the popover by clicking the menu bar icon again (toggles it)
    click("menu_bar_icon")
    wait(BEAT)


def demo_return_to_main():
    """Step 9 — Return to the full window as the outro."""
    print("▶ Step 9: Return to main window")

    focus_app("Charter")
    wait(TRANSITION)

    # Navigate back to the overview tab for a clean final frame
    click("tab_overview")
    wait(LONG, reason="final frame")
    screenshot("09-final")

    print("\n✅ Demo flow complete. Stop your screen recording now.")


# ── Calibration helper ──────────────────────────────────────────────────────────

def run_calibration():
    """
    Interactive calibration mode.
    Move your mouse to each element and press Enter.
    Copy the printed output into the COORDS dict above.
    """
    print("\n── Calibration mode ──────────────────────────────────────────")
    print("Move your mouse to each element when prompted and press Enter.")
    print("Press Ctrl+C to quit at any time.\n")

    for name in COORDS:
        input(f"  Point at: {name:40s} then press Enter...")
        x, y = pyautogui.position()
        print(f"    → \"{name}\": ({x}, {y}),")

    print("\n── Done. Paste the above into COORDS in charter_demo.py ──────")


# ── Entry point ────────────────────────────────────────────────────────────────

def main():
    if "--calibrate" in sys.argv:
        run_calibration()
        return

    print("\n── Charter Demo Recording ────────────────────────────────────")
    print("  Make sure QuickTime screen recording is already running.")
    print("  Move mouse to top-left corner at any time to abort (FAILSAFE).\n")

    # 3-second countdown so you can start QuickTime before actions begin
    for i in range(3, 0, -1):
        print(f"  Starting in {i}...")
        time.sleep(1)
    print()

    demo_open_app()
    demo_create_project()
    demo_overview()
    demo_add_contact()
    demo_log_engagement()
    demo_tasks()
    demo_notes()
    demo_menu_bar()
    demo_return_to_main()


if __name__ == "__main__":
    main()
