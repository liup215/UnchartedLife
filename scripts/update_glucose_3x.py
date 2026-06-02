#!/usr/bin/env python3
"""Scale glucose molecule coordinates by 3x and update atom radii."""

import re

filepath = r"C:\Users\22569\Workspace\LagendsOfDepu\UnchartedLife\data\molecules\glucose.tres"

with open(filepath, "r") as f:
    content = f.read()

# Scale all Vector2 positions by 3
# Match patterns like: position = Vector2(0.6, -0.7)
def scale_vector2(match: re.Match) -> str:
    x = float(match.group(1))
    y = float(match.group(2))
    new_x = round(x * 3, 1)
    new_y = round(y * 3, 1)
    # Format with .0 or .6 etc stripped when whole number
    def fmt(v: float) -> str:
        if v == int(v):
            return str(int(v))
        return str(v).rstrip("0").rstrip(".") if "." in str(v) else str(v)
    return f"position = Vector2({fmt(new_x)}, {fmt(new_y)})\n"

content = re.sub(r"position = Vector2\(([\d.\-]+),\s*([\d.\-]+)\)\n", scale_vector2, content)

# Update atom radius to 14.0 (except CH2OH which can stay 12 or also 14)
content = re.sub(r"^radius = [\d.]+\n", "radius = 14.0\n", content, flags=re.MULTILINE)

with open(filepath, "w") as f:
    f.write(content)

print("Done! Glucose coordinates scaled 3x, atom radii set to 14.0.")
