# Loading Screen System

## Overview

The loading screen system provides a configurable loading display during scene transitions and asset loading.

## Components

### LoadingScreen Scene (`ui/loading_screen/loading_screen.tscn`)
- **Center Image**: Configurable image displayed in the center (300x300px)
- **Loading Text**: Configurable text below the image (bilingual support)
- **Progress Bar**: Optional progress indicator

### SceneManager Autoload (`systems/scene_manager.gd`)
Global manager for controlling scene transitions and loading screens throughout the game.

## Usage

### Basic Usage

```gdscript
# Show loading screen with default settings
SceneManager.show_loading_screen()

# Show loading screen with custom image and text
var custom_image = preload("res://path/to/image.png")
SceneManager.show_loading_screen(custom_image, "自定义加载文字 / Custom loading text")

# Update progress (0.0 to 1.0)
SceneManager.set_progress(0.5)

# Hide loading screen
SceneManager.hide_loading_screen()
```

### Loading Scene with Progress

```gdscript
# Load scene with automatic progress display
SceneManager.load_scene_with_progress("res://scenes/main.tscn")

# With custom image and text
var custom_image = preload("res://icon.svg")
SceneManager.load_scene_with_progress(
    "res://scenes/main.tscn",
    custom_image,
    "加载主场景... / Loading main scene..."
)
```

### Manual Control

```gdscript
# Direct control of the loading screen instance
SceneManager.show_loading_screen()

# Simulate loading process
for i in range(100):
    await get_tree().create_timer(0.05).timeout
    SceneManager.set_progress(i / 100.0)

# When done
SceneManager.hide_loading_screen()
```

## Configuration

### In Editor

Open `ui/loading_screen/loading_screen.tscn` and configure:
- **Loading Image**: The texture to display in the center
- **Loading Text**: The text to display below the image
- **Show Progress Bar**: Whether to show the progress bar

### At Runtime

```gdscript
# Set custom image
var image = load("res://path/to/image.png")
SceneManager.loading_screen_instance.set_image(image)

# Set custom text
SceneManager.loading_screen_instance.set_text("自定义文字 / Custom text")
```

## Features

- ✅ **Centered Image Layout**: Image prominently displayed in center
- ✅ **Text Below Image**: Descriptive text below the image
- ✅ **Bilingual Support**: Chinese + English text support
- ✅ **Progress Bar**: Optional progress indicator
- ✅ **Smooth Transitions**: Fade in/out animations
- ✅ **Configurable**: Image and text can be set dynamically
- ✅ **Global Access**: SceneManager autoload for easy access

## Integration Examples

### Scene Transition with Loading Screen

```gdscript
# In your scene transition code
func go_to_next_level():
    var custom_image = preload("res://assets/level_icon.png")
    SceneManager.load_scene_with_progress(
        "res://scenes/levels/level_02.tscn",
        custom_image,
        "加载关卡2... / Loading Level 2..."
    )
```

### Asset Loading with Progress

```gdscript
func load_assets():
    SceneManager.show_loading_screen(null, "加载资源... / Loading assets...")
    
    var assets = ["asset1.png", "asset2.png", "asset3.png"]
    for i in range(assets.size()):
        # Load asset
        var asset = load("res://assets/" + assets[i])
        # Update progress
        SceneManager.set_progress((i + 1) / float(assets.size()))
        await get_tree().process_frame
    
    SceneManager.hide_loading_screen()
```

## Technical Details

### File Structure
```
ui/loading_screen/
├── loading_screen.gd    # Loading screen script
└── loading_screen.tscn  # Loading screen scene

systems/
└── scene_manager.gd     # Global scene and loading manager autoload
```

### Properties

**LoadingScreen (loading_screen.gd)**
- `loading_image: Texture2D` - The image to display
- `loading_text: String` - The text to display
- `show_progress_bar: bool` - Whether to show progress bar

**SceneManager (scene_manager.gd)**
- `loading_screen_instance: Control` - The loading screen instance
- `_is_loading: bool` - Current loading state

### Signals

**LoadingScreen**
- `loading_complete` - Emitted when loading reaches 100%

## Best Practices

1. **Use SceneManager**: Always use the SceneManager autoload rather than instantiating loading screens directly
2. **Bilingual Text**: Provide both Chinese and English text for all loading messages
3. **Custom Images**: Use appropriate images that represent what's being loaded
4. **Progress Updates**: Update progress regularly for better user experience
5. **Error Handling**: Always handle loading failures gracefully

## Example Scenarios

### Main Menu to Game
```gdscript
# In main_menu.gd
func _on_new_game_confirmed(settings):
    var icon = preload("res://icon.svg")
    SceneManager.load_scene_with_progress(
        "res://scenes/story/opening/opening_animation.tscn",
        icon,
        "启动新游戏... / Starting new game..."
    )
```

### Level Transition
```gdscript
# In level manager
func load_next_level(level_path: String):
    SceneManager.show_loading_screen()
    await get_tree().create_timer(0.5).timeout
    SceneManager.load_scene_with_progress(level_path)
```
