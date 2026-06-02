# molecule_bond_data.gd
# Defines a chemical bond connecting two atoms within a molecule.
# Referenced by atom indices pointing into MoleculeData.atoms[].
extends Resource

enum BondType {
	SOLID,             # Normal solid line
	DASHED,            # Dashed line (away from viewer)
	WEDGE              # Wedge/thick line (toward viewer)
}

@export var atom_a_index: int = 0            # Index of first atom in MoleculeData.atoms[]
@export var atom_b_index: int = 1            # Index of second atom in MoleculeData.atoms[]
@export var bond_type: BondType = BondType.SOLID
@export var width: float = 3.0             # Bond line width
@export var color: Color = Color(0.0, 0.85, 0.65, 0.92)
