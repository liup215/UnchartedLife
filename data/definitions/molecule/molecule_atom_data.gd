# molecule_atom_data.gd
# Defines a single atom in a molecule structure.
# Used by MoleculeData to build the full molecular layout.
extends Resource

@export var element: String = "C"          # Element symbol: "C", "O", "H"
@export var label: String = ""             # Display text: "C1", "OH", "CH₂OH"
@export var position: Vector2 = Vector2.ZERO # Position in molecule local coordinates
@export var radius: float = 7.0              # Atom radius (base, before perspective scaling)
@export var color: Color = Color.WHITE       # Atom color
@export var label_color: Color = Color.BLACK # Label text color
@export var label_size: int = 0            # Label font size (0 = use default)
