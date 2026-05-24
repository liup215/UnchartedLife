# scene_paths.gd
# Global scene path constants for use with change_scene_to_file() and load().
# These remain string paths because Godot's scene switch API requires them.
extends Node

# Main game scenes
const MAIN_SCENE := "res://scenes/main.tscn"
const GAME_SCENE := "res://scenes/game_scene.tscn"
const OPENING_ANIMATION := "res://scenes/story/opening/opening_animation.tscn"
const PROLOGUE_SCENE_01 := "res://scenes/story/prologue/prologue_scene_01.tscn"
const PROLOGUE_SCENE_02 := "res://scenes/story/prologue/prologue_scene_02.tscn"

# UI scenes
const MAIN_MENU := "res://ui/main_menu/main_menu.tscn"
const LOAD_GAME_MENU := "res://ui/load_game/load_game_menu.tscn"
const SYSTEM_MENU := "res://ui/system_menu/system_menu.tscn"
const INVENTORY_UI := "res://ui/system_menu/inventory_ui.tscn"
const CHARACTER_CREATION := "res://ui/character_creation/character_creation.tscn"
const PROLOGUE_UI := "res://ui/prologue/prologue_ui.tscn"

# BioBlitz scenes
const BIO_BLITZ_SELECTION := "res://features/bio_blitz/bio_blitz_selection.tscn"
const BIO_BLITZ_BATTLE := "res://features/bio_blitz/bio_blitz_battle.tscn"

# Loading
const LOADING_SCREEN := "res://ui/loading_screen/loading_screen.tscn"

# Base actors / components
const BASE_ACTOR := "res://features/actor/base_actor.tscn"
const MOLECULE_SCENE := "res://features/interactive/molecule/molecule.tscn"
