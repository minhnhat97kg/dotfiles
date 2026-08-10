"""Shared 5-row filled-bar rendering for waybar custom modules (volume, brightness)."""


def render_bar(percent):
    filled = min(5, max(0, (percent + 10) // 20))
    rows = []
    for i in range(1, 6):
        row = 6 - i
        rows.append("█" if row <= filled else "░")
    return rows
