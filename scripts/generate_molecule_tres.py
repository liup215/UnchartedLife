#!/usr/bin/env python3
"""
Generate .tres Resource files for molecule structures.
Run this to create the 6 initial molecule data files under data/molecules/.
"""
import os

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "data", "molecules")

# External resource references (scripts)
EXT_DATA = ('1_data', 'res://data/definitions/molecule/molecule_data.gd')
EXT_ATOM = ('2_atom', 'res://data/definitions/molecule/molecule_atom_data.gd')
EXT_BOND = ('3_bond', 'res://data/definitions/molecule/molecule_bond_data.gd')


def color_str(c):
    return f"Color({c[0]}, {c[1]}, {c[2]}, {c[3]})"


def make_tres(name, display_name, atoms, bonds, base_color):
    """Generate a .tres file from atom/bond definitions."""
    lines = []
    ext_count = 3
    sub_count = len(atoms) + len(bonds)
    load_steps = ext_count + sub_count + 1  # +1 for [resource]
    lines.append(f'[gd_resource type="Resource" script_class="MoleculeData" load_steps={load_steps} format=3]')
    lines.append("")
    lines.append(f'[ext_resource type="Script" path="{EXT_DATA[1]}" id="{EXT_DATA[0]}"]')
    lines.append(f'[ext_resource type="Script" path="{EXT_ATOM[1]}" id="{EXT_ATOM[0]}"]')
    lines.append(f'[ext_resource type="Script" path="{EXT_BOND[1]}" id="{EXT_BOND[0]}"]')
    lines.append("")

    # Sub-resources: atoms
    atom_ids = []
    for i, atom in enumerate(atoms):
        sid = f"Atom_{i}"
        atom_ids.append(sid)
        lines.append(f'[sub_resource type="Resource" id="{sid}"]')
        lines.append(f'script = ExtResource("{EXT_ATOM[0]}")')
        lines.append(f'element = "{atom["element"]}"')
        lines.append(f'label = "{atom["label"]}"')
        lines.append(f'position = Vector2({atom["pos"][0]}, {atom["pos"][1]})')
        lines.append(f'radius = {atom.get("radius", 7.0)}')
        lines.append(f'color = {color_str(atom["color"])}')
        lines.append(f'label_color = {color_str(atom.get("label_color", (0,0,0,1)))}')
        lines.append("")

    # Sub-resources: bonds
    bond_ids = []
    for i, bond in enumerate(bonds):
        sid = f"Bond_{i}"
        bond_ids.append(sid)
        lines.append(f'[sub_resource type="Resource" id="{sid}"]')
        lines.append(f'script = ExtResource("{EXT_BOND[0]}")')
        lines.append(f'atom_a_index = {bond["a"]}')
        lines.append(f'atom_b_index = {bond["b"]}')
        lines.append(f'bond_type = {bond["type"]}')
        lines.append(f'width = {bond.get("width", 3.0)}')
        lines.append(f'color = {color_str(bond["color"])}')
        lines.append("")

    # Main resource
    lines.append("[resource]")
    lines.append(f'script = ExtResource("{EXT_DATA[0]}")')
    lines.append(f'molecule_name = "{name}"')
    lines.append(f'display_name = "{display_name}"')

    # Build atom array
    atom_refs = ", ".join(f'SubResource("{aid}")' for aid in atom_ids)
    lines.append(f'atoms = Array[ExtResource("{EXT_ATOM[0]}")]([{atom_refs}])')

    # Build bond array
    bond_refs = ", ".join(f'SubResource("{bid}")' for bid in bond_ids)
    lines.append(f'bonds = Array[ExtResource("{EXT_BOND[0]}")]([{bond_refs}])')

    lines.append(f'base_color = {color_str(base_color)}')

    return "\n".join(lines)


def write_tres(filename, content):
    path = os.path.join(OUTPUT_DIR, filename)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Created: {path}")


# ================================================================
#  Define molecular structures
# ================================================================

# --- Glucose (D-glucopyranose, α-D-glucose) — Haworth projection ---
# Ring atoms (indices 0-5): O-C1-C2-C3-C4-C5
# OH atoms (indices 6-10): C1-OH, C2-OH, C3-OH, C4-OH, C5-CH2OH

GLUCOSE_ATOMS = [
    # Ring atoms
    {"element": "O",  "label": "O",   "pos": (0.50, -0.60),  "color": (0.0, 0.9, 1.0, 1.0)},   # [0] oxygen
    {"element": "C",  "label": "C1",  "pos": (1.00,  0.00),  "color": (1.0, 0.85, 0.0, 1.0)},  # [1] anomeric (yellow)
    {"element": "C",  "label": "C2",  "pos": (0.55,  0.55),  "color": (0.1, 1.0, 0.5, 1.0)},  # [2]
    {"element": "C",  "label": "C3",  "pos": (0.00,  0.80),  "color": (0.1, 1.0, 0.5, 1.0)},  # [3] frontmost
    {"element": "C",  "label": "C4",  "pos": (-0.55, 0.55),  "color": (0.1, 1.0, 0.5, 1.0)},  # [4]
    {"element": "C",  "label": "C5",  "pos": (-0.80, -0.50), "color": (0.1, 1.0, 0.5, 1.0)},  # [5]
    # OH / CH2OH substituents as separate atoms for data-driven rendering
    {"element": "O",  "label": "OH",  "pos": (1.35,  0.45),  "color": (1.0, 0.3, 0.9, 1.0)},  # [6] C1-OH (DOWN, away)
    {"element": "O",  "label": "OH",  "pos": (0.90,  0.90),  "color": (0.5, 1.0, 1.0, 1.0)},  # [7] C2-OH (UP, toward)
    {"element": "O",  "label": "OH",  "pos": (0.00,  1.30),  "color": (1.0, 0.3, 0.9, 1.0)},  # [8] C3-OH (DOWN, away)
    {"element": "O",  "label": "OH",  "pos": (-0.90, 0.90),  "color": (0.5, 1.0, 1.0, 1.0)},  # [9] C4-OH (UP, toward)
    {"element": "O",  "label": "CH₂OH", "pos": (-1.10, -0.80), "color": (1.0, 1.0, 1.0, 1.0), "radius": 6.0},  # [10] C5-CH2OH (UP, toward)
]

GLUCOSE_BONDS = [
    # Ring bonds (all SOLID)
    {"a": 0, "b": 1, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 1, "b": 2, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 2, "b": 3, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 3, "b": 4, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 4, "b": 5, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 5, "b": 0, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    # OH substituents — bond_type indicates perspective direction
    {"a": 1, "b": 6, "type": 1, "color": (1.0, 0.3, 0.9, 0.92)},   # DASHED: C1-OH (away)
    {"a": 2, "b": 7, "type": 2, "color": (0.5, 1.0, 1.0, 0.92)},   # WEDGE:  C2-OH (toward)
    {"a": 3, "b": 8, "type": 1, "color": (1.0, 0.3, 0.9, 0.92)},   # DASHED: C3-OH (away)
    {"a": 4, "b": 9, "type": 2, "color": (0.5, 1.0, 1.0, 0.92)},   # WEDGE:  C4-OH (toward)
    {"a": 5, "b": 10, "type": 2, "color": (1.0, 1.0, 1.0, 0.92)},  # WEDGE:  C5-CH2OH (toward)
]

# --- Fructose (D-fructofuranose, α-D-fructose) — 5-membered furanose ring ---
FRUCTOSE_ATOMS = [
    {"element": "O",  "label": "O",    "pos": (0.00,  0.00),  "color": (0.0, 0.9, 1.0, 1.0)},   # [0] ring oxygen
    {"element": "C",  "label": "C2",   "pos": (0.80,  0.20),  "color": (1.0, 0.85, 0.0, 1.0)},  # [1] anomeric (keto sugar)
    {"element": "C",  "label": "C3",   "pos": (0.50,  0.80),  "color": (0.1, 1.0, 0.5, 1.0)},  # [2]
    {"element": "C",  "label": "C4",   "pos": (-0.20, 0.80),  "color": (0.1, 1.0, 0.5, 1.0)},  # [3]
    {"element": "C",  "label": "C5",   "pos": (-0.60, 0.30),  "color": (0.1, 1.0, 0.5, 1.0)},  # [4]
    # Substituents
    {"element": "O",  "label": "OH",   "pos": (1.10, -0.20),  "color": (0.5, 1.0, 1.0, 1.0)},  # [5] C2-OH (UP)
    {"element": "O",  "label": "OH",   "pos": (0.80,  1.10),  "color": (1.0, 0.3, 0.9, 1.0)},  # [6] C3-OH (DOWN)
    {"element": "O",  "label": "OH",   "pos": (-0.20, 1.20),  "color": (0.5, 1.0, 1.0, 1.0)},  # [7] C4-OH (UP)
    {"element": "O",  "label": "CH₂OH", "pos": (-1.00, -0.10), "color": (1.0, 1.0, 1.0, 1.0), "radius": 6.0},  # [8] C5-CH2OH
    {"element": "O",  "label": "CH₂OH", "pos": (0.40, -0.70),  "color": (1.0, 1.0, 1.0, 1.0), "radius": 6.0},  # [9] C1-CH2OH
]

FRUCTOSE_BONDS = [
    # Ring
    {"a": 0, "b": 1, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 1, "b": 2, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 2, "b": 3, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 3, "b": 4, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 4, "b": 0, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    # Substituents
    {"a": 1, "b": 5, "type": 2, "color": (0.5, 1.0, 1.0, 0.92)},   # UP
    {"a": 2, "b": 6, "type": 1, "color": (1.0, 0.3, 0.9, 0.92)},   # DOWN
    {"a": 3, "b": 7, "type": 2, "color": (0.5, 1.0, 1.0, 0.92)},   # UP
    {"a": 4, "b": 8, "type": 2, "color": (1.0, 1.0, 1.0, 0.92)},   # CH2OH
    {"a": 0, "b": 9, "type": 2, "color": (1.0, 1.0, 1.0, 0.92)},   # C1-CH2OH attached to ring O
]

# --- Galactose (D-galactopyranose) — 6-membered ring, epimer of glucose at C4 ---
GALACTOSE_ATOMS = [
    {"element": "O",  "label": "O",    "pos": (0.50, -0.60),  "color": (0.0, 0.9, 1.0, 1.0)},
    {"element": "C",  "label": "C1",   "pos": (1.00,  0.00),  "color": (1.0, 0.85, 0.0, 1.0)},
    {"element": "C",  "label": "C2",   "pos": (0.55,  0.55),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C3",   "pos": (0.00,  0.80),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C4",   "pos": (-0.55, 0.55),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C5",   "pos": (-0.80, -0.50), "color": (0.1, 1.0, 0.5, 1.0)},
    # OH groups — note C4 is DOWN (epimer difference from glucose)
    {"element": "O",  "label": "OH",   "pos": (1.35,  0.45),  "color": (0.5, 1.0, 1.0, 1.0)},  # [6] C1-OH (UP for galactose)
    {"element": "O",  "label": "OH",   "pos": (0.90,  0.90),  "color": (1.0, 0.3, 0.9, 1.0)},  # [7] C2-OH (DOWN)
    {"element": "O",  "label": "OH",   "pos": (0.00,  1.30),  "color": (0.5, 1.0, 1.0, 1.0)},  # [8] C3-OH (UP)
    {"element": "O",  "label": "OH",   "pos": (-0.90, 0.90),  "color": (1.0, 0.3, 0.9, 1.0)},  # [9] C4-OH (DOWN — the epimer!)
    {"element": "O",  "label": "CH₂OH", "pos": (-1.10, -0.80), "color": (1.0, 1.0, 1.0, 1.0), "radius": 6.0},  # [10] C5-CH2OH
]

GALACTOSE_BONDS = [
    # Ring
    {"a": 0, "b": 1, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 1, "b": 2, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 2, "b": 3, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 3, "b": 4, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 4, "b": 5, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 5, "b": 0, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    # OH — note C4 is DOWN (dashed)
    {"a": 1, "b": 6, "type": 2, "color": (0.5, 1.0, 1.0, 0.92)},   # UP
    {"a": 2, "b": 7, "type": 1, "color": (1.0, 0.3, 0.9, 0.92)},   # DOWN
    {"a": 3, "b": 8, "type": 2, "color": (0.5, 1.0, 1.0, 0.92)},   # UP
    {"a": 4, "b": 9, "type": 1, "color": (1.0, 0.3, 0.9, 0.92)},   # DOWN — epimer!
    {"a": 5, "b": 10, "type": 2, "color": (1.0, 1.0, 1.0, 0.92)},  # CH2OH
]

# --- Sucrose (glucose + fructose, glycosidic linkage) — simplified representation ---
SUCROSE_ATOMS = [
    # Glucose ring (indices 0-5)
    {"element": "O",  "label": "O",   "pos": (-0.60, -0.40), "color": (0.0, 0.9, 1.0, 1.0)},
    {"element": "C",  "label": "C1g", "pos": (-0.10, -0.10), "color": (1.0, 0.85, 0.0, 1.0)},  # glycosidic C1
    {"element": "C",  "label": "C2g", "pos": (0.10,  0.30),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C3g", "pos": (-0.20, 0.60),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C4g", "pos": (-0.70, 0.60),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C5g", "pos": (-1.00, 0.20),  "color": (0.1, 1.0, 0.5, 1.0)},
    # Fructose ring (indices 6-10) — positioned to the right/bottom
    {"element": "O",  "label": "O",   "pos": (0.40,  -0.30), "color": (0.0, 0.9, 1.0, 1.0)},
    {"element": "C",  "label": "C2f", "pos": (0.80,  0.00),  "color": (1.0, 0.85, 0.0, 1.0)},  # glycosidic C2
    {"element": "C",  "label": "C3f", "pos": (0.70,  0.50),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C4f", "pos": (0.30,  0.70),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C5f", "pos": (0.00,  0.40),  "color": (0.1, 1.0, 0.5, 1.0)},
    # Some OH
    {"element": "O",  "label": "OH",  "pos": (0.30,  -0.20), "color": (0.5, 1.0, 1.0, 1.0)},  # [11] glucose C2-OH
    {"element": "O",  "label": "OH",  "pos": (1.00,  0.30),  "color": (0.5, 1.0, 1.0, 1.0)},  # [12] fructose C1-OH
]

SUCROSE_BONDS = [
    # Glucose ring
    {"a": 0, "b": 1, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 1, "b": 2, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 2, "b": 3, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 3, "b": 4, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 4, "b": 5, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 5, "b": 0, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    # Fructose ring
    {"a": 6, "b": 7, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 7, "b": 8, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 8, "b": 9, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 9, "b": 10, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 10, "b": 6, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    # Glycosidic linkage C1glucose -- C2fructose
    {"a": 1, "b": 7, "type": 0, "color": (1.0, 0.5, 0.0, 0.92), "width": 4.0},
    # OH substituents
    {"a": 1, "b": 11, "type": 2, "color": (0.5, 1.0, 1.0, 0.92)},
    {"a": 7, "b": 12, "type": 2, "color": (0.5, 1.0, 1.0, 0.92)},
]

# --- Lactose (galactose + glucose, β-1,4 linkage) — simplified ---
LACTOSE_ATOMS = [
    # Galactose ring (left)
    {"element": "O",  "label": "O",   "pos": (-0.80, -0.30), "color": (0.0, 0.9, 1.0, 1.0)},
    {"element": "C",  "label": "C1a", "pos": (-0.30, 0.00),  "color": (1.0, 0.85, 0.0, 1.0)},
    {"element": "C",  "label": "C2a", "pos": (-0.10, 0.50),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C3a", "pos": (-0.40, 0.90),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C4a", "pos": (-0.90, 0.90),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C5a", "pos": (-1.20, 0.50),  "color": (0.1, 1.0, 0.5, 1.0)},
    # Glucose ring (right) — linked via C4 galactose to C1 glucose
    {"element": "O",  "label": "O",   "pos": (0.20,  0.30),  "color": (0.0, 0.9, 1.0, 1.0)},
    {"element": "C",  "label": "C1b", "pos": (0.60,  0.60),  "color": (1.0, 0.85, 0.0, 1.0)},
    {"element": "C",  "label": "C2b", "pos": (0.80,  1.00),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C3b", "pos": (0.50,  1.40),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C4b", "pos": (0.00,  1.40),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C5b", "pos": (-0.30, 1.00),  "color": (0.1, 1.0, 0.5, 1.0)},
    # Some OH
    {"element": "O",  "label": "OH",  "pos": (-0.10, -0.10), "color": (0.5, 1.0, 1.0, 1.0)},  # [12]
]

LACTOSE_BONDS = [
    # Galactose ring
    {"a": 0, "b": 1, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 1, "b": 2, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 2, "b": 3, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 3, "b": 4, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 4, "b": 5, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 5, "b": 0, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    # Glucose ring
    {"a": 6, "b": 7, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 7, "b": 8, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 8, "b": 9, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 9, "b": 10, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 10, "b": 11, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 11, "b": 6, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    # Glycosidic linkage: C4 galactose (index 4) -> C1 glucose (index 7)
    {"a": 4, "b": 7, "type": 0, "color": (1.0, 0.5, 0.0, 0.92), "width": 4.0},
    # OH
    {"a": 1, "b": 12, "type": 2, "color": (0.5, 1.0, 1.0, 0.92)},
]

# --- Maltose (glucose + glucose, α-1,4 linkage) ---
MALTOSE_ATOMS = [
    # Glucose A (left)
    {"element": "O",  "label": "O",   "pos": (-0.80, -0.30), "color": (0.0, 0.9, 1.0, 1.0)},
    {"element": "C",  "label": "C1a", "pos": (-0.30, 0.00),  "color": (1.0, 0.85, 0.0, 1.0)},
    {"element": "C",  "label": "C2a", "pos": (-0.10, 0.50),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C3a", "pos": (-0.40, 0.90),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C4a", "pos": (-0.90, 0.90),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C5a", "pos": (-1.20, 0.50),  "color": (0.1, 1.0, 0.5, 1.0)},
    # Glucose B (right)
    {"element": "O",  "label": "O",   "pos": (0.20,  0.30),  "color": (0.0, 0.9, 1.0, 1.0)},
    {"element": "C",  "label": "C1b", "pos": (0.60,  0.60),  "color": (1.0, 0.85, 0.0, 1.0)},
    {"element": "C",  "label": "C2b", "pos": (0.80,  1.00),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C3b", "pos": (0.50,  1.40),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C4b", "pos": (0.00,  1.40),  "color": (0.1, 1.0, 0.5, 1.0)},
    {"element": "C",  "label": "C5b", "pos": (-0.30, 1.00),  "color": (0.1, 1.0, 0.5, 1.0)},
    # OH
    {"element": "O",  "label": "OH",  "pos": (0.10, -0.10),  "color": (0.5, 1.0, 1.0, 1.0)},  # [12]
]

MALTOSE_BONDS = [
    # Ring A
    {"a": 0, "b": 1, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 1, "b": 2, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 2, "b": 3, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 3, "b": 4, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 4, "b": 5, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 5, "b": 0, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    # Ring B
    {"a": 6, "b": 7, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 7, "b": 8, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 8, "b": 9, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 9, "b": 10, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 10, "b": 11, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    {"a": 11, "b": 6, "type": 0, "color": (0.0, 0.85, 0.65, 0.92)},
    # Glycosidic linkage: C4 glucoseA (4) -> C1 glucoseB (7)
    {"a": 4, "b": 7, "type": 0, "color": (1.0, 0.5, 0.0, 0.92), "width": 4.0},
    # OH
    {"a": 1, "b": 12, "type": 2, "color": (0.5, 1.0, 1.0, 0.92)},
]


def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    molecules = [
        ("glucose.tres",  "glucose",  "Glucose",  GLUCOSE_ATOMS,  GLUCOSE_BONDS,  (0.0, 1.0, 0.6, 1.0)),
        ("fructose.tres", "fructose", "Fructose", FRUCTOSE_ATOMS, FRUCTOSE_BONDS, (1.0, 0.5, 0.0, 1.0)),
        ("galactose.tres","galactose","Galactose",GALACTOSE_ATOMS,GALACTOSE_BONDS,(1.0, 0.9, 0.0, 1.0)),
        ("sucrose.tres",  "sucrose",  "Sucrose",  SUCROSE_ATOMS,  SUCROSE_BONDS,  (1.0, 0.2, 0.2, 1.0)),
        ("lactose.tres",  "lactose",  "Lactose",  LACTOSE_ATOMS,  LACTOSE_BONDS,  (0.8, 0.2, 1.0, 1.0)),
        ("maltose.tres",  "maltose",  "Maltose",  MALTOSE_ATOMS,  MALTOSE_BONDS,  (0.2, 0.4, 1.0, 1.0)),
    ]

    for filename, name, display, atoms, bonds, color in molecules:
        content = make_tres(name, display, atoms, bonds, color)
        write_tres(filename, content)

    print("\nAll 6 molecule .tres files generated successfully!")


if __name__ == "__main__":
    main()
