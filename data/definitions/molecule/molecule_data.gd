# molecule_data.gd
# Defines the complete structure of a molecule: atoms, bonds, and visual identity.
# Pure data resource — no gameplay effects. Can be reused across scenes.
extends Resource

const MoleculeAtomData = preload("res://data/definitions/molecule/molecule_atom_data.gd")
const MoleculeBondData = preload("res://data/definitions/molecule/molecule_bond_data.gd")

@export var molecule_name: String = "molecule"     # Unique identifier (snake_case, e.g. "glucose")
@export var display_name: String = "Molecule"      # Human-readable name (e.g. "Glucose" / "葡萄糖")
@export var atoms: Array[MoleculeAtomData] = []    # Atomic structure
@export var bonds: Array[MoleculeBondData] = []    # Chemical bonds (refer to atoms by index)
@export var base_color: Color = Color.WHITE          # Theme color for labels / highlights


func validate() -> bool:
	var atom_count: int = atoms.size()
	if atom_count == 0:
		push_warning("MoleculeData '%s' has no atoms." % molecule_name)
		return false
	
	for bond in bonds:
		if bond.atom_a_index < 0 or bond.atom_a_index >= atom_count:
			push_error("MoleculeData '%s': bond references invalid atom_a_index %d (atom count: %d)." % [molecule_name, bond.atom_a_index, atom_count])
			return false
		if bond.atom_b_index < 0 or bond.atom_b_index >= atom_count:
			push_error("MoleculeData '%s': bond references invalid atom_b_index %d (atom count: %d)." % [molecule_name, bond.atom_b_index, atom_count])
			return false
		if bond.atom_a_index == bond.atom_b_index:
			push_error("MoleculeData '%s': bond connects atom %d to itself." % [molecule_name, bond.atom_a_index])
			return false
	
	return true
