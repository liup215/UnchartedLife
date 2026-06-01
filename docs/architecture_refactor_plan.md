# Player 系统解耦长期重构方案

## 现状诊断摘要

### 核心问题：Player.gd 是"上帝脚本"
Player.gd 目前承担了以下职责：
- **输入处理**（移动、冲刺、闪避、战斗、载具交互）
- **代谢逻辑**（ATP/葡萄糖消耗、恢复、枯竭惩罚）
- **状态管理**（步行/载具双状态机）
- **视觉控制**（武器朝向、玩家显隐）
- **战斗调度**（轻攻击/重攻击输入转发到 CombatComponent）
- **载具交互**（进入/退出载具、相机切换）
- **闪避协调**（无敌帧与 HealthComponent 的联动）

### 耦合热点统计

| 被引用对象 | Player.gd 直接访问次数 | 问题 |
|---|---|---|
| `attribute_component.metabolism_component` | **17+** | 代谢逻辑完全外泄 |
| `attribute_component.health_component` | **5+** | 不应绕过 AttributeComponent 直接拿 Health |
| `attribute_component.speed_component` | **2+** | 速度获取直接穿透 |
| `attribute_component.toughness_component` | **1** | 硬 stagger 检查 |
| `actor_combat_component` | **6+** | 战斗输入侵入 Player |
| `dodge_component` | **5+** | 闪避编排逻辑在 Player 中 |
| `CollisionShape2D` | **1** | 直接操作物理节点 |
| `visuals` | **1** | 直接操作渲染节点 |
| `input_component` | **15+** | 合理，但 vehicle 输入数据也混在这里 |

### 组件间直接引用关系（当前）

```
Player
 ├─→ Actor (继承)
 ├─→ AttributeComponent (直接 .metabolism_component .health_component etc)
 ├─→ DodgeComponent (直接管理状态和信号)
 ├─→ ActorCombatComponent (直接调度攻击)
 ├─→ Vehicle (直接设置 input_component、直接调用 enter/exit)
 └─→ PlayerInputComponent (直接读取意图)

ActorCombatComponent
 ├─→ AttributeComponent (直接消耗 ATP)
 ├─→ ChargeComponent (直接启动/停止蓄力)
 ├─→ HeavyAttackSystem / ComboSystem (直接初始化)
 ├─→ HitDamageCalculator (直接传入武器/蓄力/连击引用)
 ├─→ get_parent().play_combat_animation() (越级调用)
 └─→ get_global_mouse_position() (输入泄漏)

VehicleCombatComponent
 ├─→ vehicle.driver.attribute_component.metabolism_component (链式穿透)
 └─→ weapon_effect 节点 (直接引用视觉节点)

WeaponComponent
 ├─→ get_global_mouse_position() (输入泄漏)
 ├─→ get_parent().get_parent() (链式穿透获取 shooter)
 └─→ EventBus.quiz_completed (全局信号耦合)

DodgeComponent
 ├─→ actor.attribute_component.metabolism_component (链式穿透)
 ├─→ actor.global_position (直接操作位置)
 └─→ actor.get_last_direction() (侵入式调用)

HitDamageCalculator
 ├─→ actor_weapons (直接引用数组)
 ├─→ charge_component / heavy_attack_system / combo_system (直接读取状态)
 ├─→ attacker.get_parent() (链式穿透)
 ├─→ target.take_damage() (硬编码调用)
 └─→ target_actor.attribute_component.toughness_component (链式穿透)
```

---

## 重构目标

**总体架构：ECS-lite + Command Bus + Pipeline System**

核心原则：
1. **数据与行为分离**：所有配置由 `Resource` 驱动，运行时状态由 `System` 管理
2. **组件只发信号，不做决策**：组件通知事件，System 执行业务逻辑
3. **消灭跨级穿透**：`get_parent().xxx` 和 `actor.attribute_component.yyy.zzz` 全部消除
4. **输入完全隔离**：只有 Input System 知道 `Input.is_action_pressed`
5. **命令驱动**：任何状态改变都通过 Command Bus 分发，便于日志/回放/网络同步
6. **通用系统替代专用逻辑**：代谢系统、蓄力系统、伤害系统全部泛化为可配置 System

---

## Phase 1: 核心基础设施（2-3周）

### 1.1 Entity Component System 运行时

创建 `systems/ecs/` 目录，引入轻量级 ECS：

```gdscript
# systems/ecs/entity_manager.gd
extends Node
class_name EntityManager

var _entities: Dictionary[int, Dictionary] = {} # entity_id -> {components}
var _next_entity_id: int = 1

func create_entity() -> int:
    var id = _next_entity_id
    _next_entity_id += 1
    _entities[id] = {}
    return id

func add_component(entity_id: int, component_type: String, component: Object) -> void:
    if not _entities.has(entity_id):
        push_error("Entity %d does not exist" % entity_id)
        return
    _entities[entity_id][component_type] = component

func get_component(entity_id: int, component_type: String) -> Object:
    if not _entities.has(entity_id):
        return null
    return _entities[entity_id].get(component_type)

func has_component(entity_id: int, component_type: String) -> bool:
    return get_component(entity_id, component_type) != null

func remove_entity(entity_id: int) -> void:
    _entities.erase(entity_id)
```

**所有 Actor / Vehicle 实体都必须在 EntityManager 中注册**，获得全局唯一的 `entity_id`。这是跨系统通信的基础。

### 1.2 Command Bus（命令总线）

```gdscript
# systems/command_bus.gd
extends Node
class_name CommandBus

enum CommandType {
    MOVE_REQUEST,
    DODGE_REQUEST,
    ATTACK_REQUEST,
    HEAVY_CHARGE_START,
    HEAVY_CHARGE_RELEASE,
    ENTER_VEHICLE_REQUEST,
    EXIT_VEHICLE_REQUEST,
    CONSUME_RESOURCE,
    APPLY_DAMAGE,
    PLAY_ANIMATION,
    SPAWN_PROJECTILE,
    # ... etc
}

## A Command is a pure data packet. No logic, no references to nodes.
## All data must be serializable (entity_ids, Vector2, float, int, String, Dictionary).
class Command:
    var type: CommandType
    var issuer_entity: int    # Who issued this command
    var target_entity: int    # Who is the target (optional)
    var payload: Dictionary   # Type-specific data
    var timestamp: float      # Game time when command was issued

signal command_issued(command: Command)
signal command_validated(command: Command, valid: bool)
signal command_executed(command: Command)

func issue(command: Command) -> void:
    ## 1. Validation phase
    var validation_result = _validate(command)
    command_validated.emit(command, validation_result)
    if not validation_result:
        return
    ## 2. Execution phase
    _execute(command)
    command_executed.emit(command)

func _validate(command: Command) -> bool:
    ## Dispatch to registered validators
    pass

func _execute(command: Command) -> void:
    ## Dispatch to registered executors
    pass
```

**为什么需要 Command Bus？**
- 任何系统可以观察、拦截、修改命令（做 Buff 效果、权限控制、日志记录）
- 可以序列化所有游戏行为，为回放/网络同步/存档复现打下基础
- 玩家 Replay、Debug、反作弊都依赖此层

### 1.3 Service Registry（服务注册表）

```gdscript
# systems/service_registry.gd
extends Node
class_name ServiceRegistry

var _services: Dictionary[String, Object] = {}

func register(name: String, service: Object) -> void:
    _services[name] = service

func get_service(name: String) -> Object:
    return _services.get(name)

func has_service(name: String) -> bool:
    return _services.has(name)
```

注册的核心服务：
- `"entity_manager"` -> EntityManager
- `"command_bus"` -> CommandBus
- `"stat_system"` -> StatSystem
- `"resource_system"` -> ResourcePoolSystem
- `"damage_pipeline"` -> DamagePipeline
- `"animation_system"` -> AnimationSystem
- `"effect_system"` -> EffectSystem
- `"target_resolver"` -> TargetResolverSystem

**消灭所有全局单例的直接引用**。System 之间只通过 ServiceRegistry 交互，或通过 Command Bus 通信。

### 1.4 Tick System（统一的时钟管道）

```gdscript
# systems/tick_system.gd
extends Node
class_name TickSystem

## All gameplay systems register here and receive delta time in priority order.
## This replaces scattered _process/_physics_process logic across components.

var _systems: Array[Tickable] = []

func register_system(system: Tickable, priority: int = 0) -> void:
    _systems.append(system)
    _systems.sort_custom(func(a, b): return a.priority < b.priority)

func tick(delta: float) -> void:
    for system in _systems:
        system.on_tick(delta)

## Interface
class Tickable:
    var priority: int = 0
    func on_tick(delta: float) -> void:
        pass
```

Player.gd、ActorCombatComponent 等不再自己做 `_process`/`_physics_process` 计算，而是让对应的 System 在 Tick System 中处理。这样可以把代谢计算、蓄力计算、连击计时器全部移出组件，放入专门的 System 中。

---

## Phase 2: 数值系统解耦（2周）

### 2.1 StatSystem（属性系统）

彻底废弃 `AttributeComponent` 的硬编码子组件发现模式。

**数据层：**
```gdscript
# data/definitions/stat_definition.gd
class_name StatDefinition
extends Resource

@export var stat_id: String  # "health", "max_health", "atp", "max_atp", "speed", "toughness"...
@export var base_value: float
@export var min_value: float = 0.0
@export var max_value: float = 999999.0
@export var is_resource_pool: bool = false  # If true, has current/max pair
```

**运行时组件（仅持 entity_id）：**
```gdscript
# features/components/stat_component.gd
extends Node
class_name StatComponent

@export var entity_id: int = -1

func _ready():
    if entity_id < 0:
        push_error("StatComponent requires entity_id")
        return
    ## Register self with StatSystem via ServiceRegistry
    var stat_sys: StatSystem = ServiceRegistry.get_service("stat_system") as StatSystem
    stat_sys.register_entity(entity_id, self)
```

**StatSystem（全局服务）：**
```gdscript
# systems/stat_system.gd
class_name StatSystem
extends Node

## Manages all stat instances for all entities.
## No node references — only entity_id lookups.

var _entity_stats: Dictionary[int, Dictionary] = {} # entity_id -> {stat_id -> StatInstance}

class StatInstance:
    var stat_id: String
    var base_value: float
    var current_value: float
    var modifiers: Array[StatModifier] = []
    
    signal value_changed(current: float, max_value: float)
    
    func get_final_value() -> float:
        var result = base_value
        for mod in modifiers:
            result = mod.apply(result)
        return result
    
    func set_current(value: float) -> void:
        var old = current_value
        current_value = clamp(value, 0, get_max_value())
        if current_value != old:
            value_changed.emit(current_value, get_max_value())
    
    func get_max_value() -> float:
        return get_final_value()  # After all modifiers
    
    func add_modifier(mod: StatModifier) -> void:
        modifiers.append(mod)
        modifiers.sort_custom(func(a, b): return a.priority - b.priority)
        value_changed.emit(current_value, get_max_value())
    
    func remove_modifier(mod: StatModifier) -> void:
        modifiers.erase(mod)
        value_changed.emit(current_value, get_max_value())

func get_stat(entity_id: int, stat_id: String) -> StatInstance:
    if not _entity_stats.has(entity_id):
        return null
    return _entity_stats[entity_id].get(stat_id)

func modify_stat(entity_id: int, stat_id: String, delta: float) -> void:
    var stat = get_stat(entity_id, stat_id)
    if stat:
        stat.set_current(stat.current_value + delta)

func add_modifier(entity_id: int, stat_id: String, mod: StatModifier) -> void:
    var stat = get_stat(entity_id, stat_id)
    if stat:
        stat.add_modifier(mod)
```

**好处：**
- `HealthComponent` 不再存在，取而代之的是 `"health"` stat 和 `"max_health"` stat
- `"atp"` / `"glucose"` / `"speed"` / `"toughness"` 全部统一为 StatSystem 中的条目
- 任何 Buff/Debuff 只需要向 StatSystem 添加/移除 Modifier
- 消灭 `attribute_component.metabolism_component.get_current_atp()` 这种链式穿透

### 2.2 ResourcePoolSystem（资源池系统）

对 `health` / `atp` / `glucose` / `toughness` 这种有当前值/最大值配对的资源：

```gdscript
# systems/resource_pool_system.gd
class_name ResourcePoolSystem
extends Node

## High-level API for consuming / recovering resources.
## Emits events that other systems can listen to.

signal resource_depleted(entity_id: int, resource_type: String)
signal resource_changed(entity_id: int, resource_type: String, current: float, max_value: float)

func consume(entity_id: int, resource_type: String, amount: float) -> bool:
    var stat_sys: StatSystem = ServiceRegistry.get_service("stat_system")
    var stat = stat_sys.get_stat(entity_id, resource_type)
    if not stat:
        return false
    var current = stat.current_value
    if current < amount:
        stat.set_current(0)
        resource_depleted.emit(entity_id, resource_type)
        return false
    stat.set_current(current - amount)
    resource_changed.emit(entity_id, resource_type, stat.current_value, stat.get_max_value())
    return true

func recover(entity_id: int, resource_type: String, amount: float) -> void:
    var stat_sys: StatSystem = ServiceRegistry.get_service("stat_system")
    var stat = stat_sys.get_stat(entity_id, resource_type)
    if stat:
        stat.set_current(stat.current_value + amount)
```

Player 中所有的 `attribute_component.metabolism_component.consume_atp()` 变为：
```gdscript
var res_sys: ResourcePoolSystem = ServiceRegistry.get_service("resource_pool_system")
res_sys.consume(entity_id, "atp", amount)
```

### 2.3 EffectSystem（Buff/Debuff 系统）

```gdscript
# systems/effect_system.gd
class_name EffectSystem
extends Node

## Applies timed stat modifications and status effects.

class ActiveEffect:
    var effect_id: String
    var entity_id: int
    var duration: float
    var remaining: float
    var stat_modifiers: Array[StatModifier] = []
    ## On-expire callbacks
    var on_expire: Callable
    
    func tick(delta: float) -> bool:
        remaining -= delta
        return remaining <= 0

var _active_effects: Array[ActiveEffect] = []

func apply_effect(entity_id: int, effect_data: EffectData) -> ActiveEffect:
    var effect = ActiveEffect.new()
    effect.effect_id = effect_data.effect_id
    effect.entity_id = entity_id
    effect.duration = effect_data.duration
    effect.remaining = effect_data.duration
    
    var stat_sys: StatSystem = ServiceRegistry.get_service("stat_system")
    for mod_data in effect_data.stat_modifiers:
        var mod = StatModifier.new(mod_data.stat_id, mod_data.operation, mod_data.value, mod_data.priority)
        effect.stat_modifiers.append(mod)
        stat_sys.add_modifier(entity_id, mod_data.stat_id, mod)
    
    _active_effects.append(effect)
    return effect

func tick(delta: float) -> void:
    var expired: Array[ActiveEffect] = []
    for effect in _active_effects:
        if effect.tick(delta):
            expired.append(effect)
    for effect in expired:
        _remove_effect(effect)

func _remove_effect(effect: ActiveEffect) -> void:
    var stat_sys: StatSystem = ServiceRegistry.get_service("stat_system")
    for mod in effect.stat_modifiers:
        stat_sys.remove_modifier(effect.entity_id, mod.stat_id, mod)
    if effect.on_expire:
        effect.on_expire.call()
    _active_effects.erase(effect)
```

**从此：**
- 冲刺加速 = EffectSystem 给 `"speed"` stat 加一个 +80% 的限时 Modifier
- 无敌帧 = EffectSystem 给某个 `"invincible"` status 添加 effect
- ATP 枯竭伤害 = ResourcePoolSystem 的 `resource_depleted` 信号触发 DamagePipeline

---

## Phase 3: 战斗系统解耦（3周）

### 3.1 Attack Pipeline（攻击请求管道）

将攻击流程拆分为清晰的阶段：

```
Input System
    ↓ (生成 Command)
Command Bus
    ↓ (验证)
AttackRequestSystem
    ↓ (解析武器、计算 ATP 消耗)
CostValidationSystem
    ↓ (检查 ATP / ammo / cooldown)
ChargeSystem
    ↓ (如果是蓄力攻击，管理蓄力进度)
WeaponFireSystem
    ↓ (生成 projectile / hitscan / melee 攻击)
ProjectileSystem / MeleeHitSystem
    ↓ (碰撞检测)
DamagePipeline
    ↓ (伤害计算)
HealthSystem
    ↓ (扣除 HP)
VisualEffectSystem
    ↓ (播放命中特效)
AnimationSystem
    ↓ (播放受击/死亡动画)
```

每阶段只负责自己的逻辑，通过 Command Bus 传递数据包。

**核心数据结构：**
```gdscript
# data/definitions/attack_request.gd
class_name AttackRequest
extends RefCounted  # Not Resource; this is runtime transient data

var attacker_entity: int
var weapon_slot: String  # "main", "secondary", "actor"
var target_position: Vector2  # Resolved by TargetResolverSystem
var charge_level: float = 0.0
var is_heavy: bool = false
var combo_stage: int = 0
```

### 3.2 ChargeSystem（蓄力系统）

将 `ChargeComponent` 从组件升级为全局 System：

```gdscript
# systems/charge_system.gd
class_name ChargeSystem
extends Node

## Tracks charge state for ALL entities, not just the player.
## No longer a scene node component — pure data in a Dictionary.

class ChargeState:
    var entity_id: int
    var weapon_slot: String
    var current_level: int = 0
    var current_progress: float = 0.0
    var is_charging: bool = false
    var charge_rate: float = 50.0  # From weapon data
    var max_level: int = 5
    var progress_per_level: float = 100.0

var _charge_states: Dictionary[int, Dictionary] = {} # entity_id -> {slot: ChargeState}

func start_charge(entity_id: int, weapon_slot: String, weapon_data: WeaponData) -> void:
    var state = _get_or_create_state(entity_id, weapon_slot)
    state.is_charging = true
    state.charge_rate = weapon_data.charge_rate_per_second
    state.max_level = weapon_data.max_charge_level
    state.progress_per_level = weapon_data.progress_per_level

func tick(delta: float) -> void:
    for entity_id in _charge_states:
        for slot in _charge_states[entity_id]:
            var state: ChargeState = _charge_states[entity_id][slot]
            if state.is_charging:
                _update_charge(state, delta)

func release_charge(entity_id: int, weapon_slot: String) -> float:
    var state = _get_state(entity_id, weapon_slot)
    if not state:
        return 0.0
    state.is_charging = false
    var effective = float(state.current_level) + (state.current_progress / state.progress_per_level)
    ## Reset after release
    state.current_level = 0
    state.current_progress = 0.0
    return effective
```

**好处：**
- 任何实体（Boss、炮塔、载具武器）都可以蓄力，不需要添加节点
- 蓄力状态完全数据化，可以保存/同步/回放
- `ActorCombatComponent` 不再持有 `charge_component` 引用

### 3.3 TargetResolverSystem（目标解析系统）

消灭所有组件中的 `get_global_mouse_position()`。

```gdscript
# systems/target_resolver_system.gd
class_name TargetResolverSystem
extends Node

## Given an entity and a weapon, resolves the logical "target".
## This might be: mouse position, nearest enemy, lock-on target, etc.

enum TargetMode {
    MOUSE_POSITION,
    NEAREST_ENEMY,
    LOCK_ON,
    FORWARD_DIRECTION,
    CUSTOM
}

func resolve_target(attacker_entity: int, weapon_data: WeaponData) -> Vector2:
    match weapon_data.target_mode:
        TargetMode.MOUSE_POSITION:
            return _get_mouse_world_position()
        TargetMode.NEAREST_ENEMY:
            return _find_nearest_enemy(attacker_entity)
        TargetMode.LOCK_ON:
            return _get_lock_on_target(attacker_entity)
        TargetMode.FORWARD_DIRECTION:
            return _get_forward_direction(attacker_entity)
        _:
            return Vector2.ZERO

func _get_mouse_world_position() -> Vector2:
    ## THIS IS THE ONLY PLACE IN THE ENTIRE CODEBASE that calls get_global_mouse_position().
    var camera = get_viewport().get_camera_2d()
    if camera:
        return camera.get_global_mouse_position()
    return get_viewport().get_mouse_position()
```

### 3.4 DamagePipeline（伤害管道）

将 `HitDamageCalculator`、`DamageCalculator`、`health_component.take_damage` 全部纳入一个清晰的管道：

```gdscript
# systems/damage_pipeline.gd
class_name DamagePipeline
extends Node

## Phases of damage processing:

signal damage_pre_mitigation(entity_id: int, damage_request: DamageRequest)
signal damage_post_mitigation(entity_id: int, damage_result: DamageResult)
signal entity_died(entity_id: int, killer_entity: int)

class DamageRequest:
    var attacker_entity: int
    var victim_entity: int
    var base_damage: float
    var damage_type: int  # WeaponData.DamageType
    var damage_multiplier: float = 1.0
    var armor_break: float = 0.0
    var stagger_power: float = 0.0
    var charge_level: float = 0.0
    var is_crit: bool = false

class DamageResult:
    var final_damage: float
    var toughness_damage: float
    var was_mitigated: bool
    var damage_breakdown: Dictionary

func process_damage(request: DamageRequest) -> DamageResult:
    ## Phase 1: Pre-calculation (Buffs/Debuffs on attacker)
    damage_pre_mitigation.emit(request.victim_entity, request)
    
    ## Phase 2: Calculate raw damage
    var raw = request.base_damage * request.damage_multiplier
    
    ## Phase 3: Armor/resistance mitigation
    var mitigated = _apply_mitigation(request.victim_entity, raw, request.damage_type)
    
    ## Phase 4: Final calculation
    var result = DamageResult.new()
    result.final_damage = mitigated
    result.toughness_damage = mitigated * (1.0 + request.stagger_power / 100.0)
    result.damage_breakdown = {
        "base": request.base_damage,
        "multiplier": request.damage_multiplier,
        "charge_bonus": request.charge_level * HeavyAttackSystem.DAMAGE_CHARGE_SCALING_FACTOR,
        "mitigated_by": mitigated / raw if raw > 0 else 1.0
    }
    
    ## Phase 5: Apply to victim
    _apply_to_victim(request, result)
    
    damage_post_mitigation.emit(request.victim_entity, result)
    return result

func _apply_to_victim(request: DamageRequest, result: DamageResult) -> void:
    ## Apply HP damage
    var res_sys: ResourcePoolSystem = ServiceRegistry.get_service("resource_pool_system")
    res_sys.consume(request.victim_entity, "health", result.final_damage)
    
    ## Apply toughness damage
    var toughness = res_sys.get_current(request.victim_entity, "toughness")
    if toughness != null:
        res_sys.consume(request.victim_entity, "toughness", result.toughness_damage)
        if toughness <= result.toughness_damage:
            ## Trigger stagger — but NOT by directly calling a component method.
            ## Instead, issue a command:
            var cmd = Command.new()
            cmd.type = CommandType.APPLY_STATUS_EFFECT
            cmd.issuer_entity = request.attacker_entity
            cmd.target_entity = request.victim_entity
            cmd.payload = {"effect_id": "stagger", "duration": 2.0}
            CommandBus.issue(cmd)
    
    ## Check death
    var hp = res_sys.get_current(request.victim_entity, "health")
    if hp <= 0:
        entity_died.emit(request.victim_entity, request.attacker_entity)
```

**关键变化：**
- `HitDamageCalculator.on_enemy_hit()` 中所有的 `target.take_damage()`、`target_actor.attribute_component.toughness_component.apply_toughness_damage()` 全部消除
- 改为通过 `DamagePipeline.process_damage()` 走统一管道
- Stagger 不再由 HitDamageCalculator 直接触发，而是发出 Command 让 EffectSystem 处理

### 3.5 WeaponSystem（武器系统）

将武器从场景节点改为 **纯数据 + 运行时控制器** 模式：

```gdscript
# systems/weapon_system.gd
class_name WeaponSystem
extends Node

## Manages weapon instances for ALL entities.
## Weapon "instances" are just data + a reference to the owner entity.

class WeaponInstance:
    var owner_entity: int
    var weapon_data: WeaponData
    var current_ammo: int
    var current_charge: int = 0
    var slot: String  # "main", "secondary", "actor"
    var cooldown_remaining: float = 0.0

var _weapon_instances: Dictionary[int, Array] = {} # entity_id -> [WeaponInstance]

func equip_weapon(entity_id: int, weapon_data: WeaponData, slot: String) -> WeaponInstance:
    var inst = WeaponInstance.new()
    inst.owner_entity = entity_id
    inst.weapon_data = weapon_data
    inst.current_ammo = weapon_data.ammo_capacity
    inst.slot = slot
    
    if not _weapon_instances.has(entity_id):
        _weapon_instances[entity_id] = []
    _weapon_instances[entity_id].append(inst)
    return inst

func get_weapons_in_slot(entity_id: int, slot: String) -> Array[WeaponInstance]:
    if not _weapon_instances.has(entity_id):
        return []
    return _weapon_instances[entity_id].filter(func(w): return w.slot == slot)

func fire_weapon(instance: WeaponInstance, target_pos: Vector2, effect_node: Node = null) -> bool:
    if instance.cooldown_remaining > 0:
        return false
    if instance.current_ammo <= 0:
        EventBus.weapon_out_of_ammo.emit(instance.weapon_data)
        return false
    
    instance.current_ammo -= 1
    
    ## Create the actual projectile/visual effect
    var spawn_sys: SpawnSystem = ServiceRegistry.get_service("spawn_system")
    var projectile = spawn_sys.spawn_projectile(
        instance.weapon_data.projectile_scene,
        _get_muzzle_position(instance),
        target_pos,
        instance.owner_entity,
        instance.weapon_data
    )
    
    return true

func reload(instance: WeaponInstance) -> void:
    if instance.weapon_data.requires_quiz_reload:
        ## Emit request — but response will come back as a command
        EventBus.request_quiz_reload.emit(instance.weapon_data)
    else:
        instance.current_ammo = instance.weapon_data.ammo_capacity
```

**WeaponComponent 的消亡：**
- `WeaponComponent` 这个 Node2D 类将不再承载逻辑，仅作为视觉表现（Sprite、动画）
- 所有 `fire()`、`reload()`、`start_charging()` 逻辑迁移到 `WeaponSystem`
- 武器朝向调整由 `VisualEffectSystem` 处理，而不是 Player.gd 直接旋转 `WeaponComponent`

---

## Phase 4: 输入与状态解耦（2周）

### 4.1 PlayerStateMachine（玩家状态机）

废除 Player.gd 中的 `match current_state:` 硬编码分支。

```gdscript
# systems/player_state_machine.gd
class_name PlayerStateMachine
extends Node

enum State {
    ON_FOOT,
    DODGING,
    STAGGERED,
    IN_VEHICLE,
    DEAD
}

class StateConfig:
    var state_id: State
    var can_move: bool = true
    var can_attack: bool = true
    var can_dodge: bool = true
    var can_interact: bool = true
    var metabolic_rate: float = 1.0  # Multiplier for metabolism
    var physics_mode: int = 0  # 0=CharacterBody2D, 1=RigidBody2D proxy

var current_state: State = State.ON_FOOT
var _state_configs: Dictionary[State, StateConfig] = {}

func configure_state(state: State, config: StateConfig) -> void:
    _state_configs[state] = config

func transition_to(new_state: State, entity_id: int) -> bool:
    var config = _state_configs.get(new_state)
    if not config:
        return false
    
    ## Emit pre-transition event
    EventBus.player_state_changing.emit(entity_id, current_state, new_state)
    
    var old_state = current_state
    current_state = new_state
    
    ## State-specific side effects go here, dispatched via commands
    if new_state == State.DODGING:
        _on_enter_dodge(entity_id)
    elif new_state == State.IN_VEHICLE:
        _on_enter_vehicle(entity_id)
    elif old_state == State.IN_VEHICLE:
        _on_exit_vehicle(entity_id)
    
    EventBus.player_state_changed.emit(entity_id, old_state, new_state)
    return true

func can_perform_action(action: String) -> bool:
    var config = _state_configs.get(current_state)
    if not config:
        return false
    match action:
        "move": return config.can_move
        "attack": return config.can_attack
        "dodge": return config.can_dodge
        "interact": return config.can_interact
        _: return false
```

**Player.gd 的变化：**
```gdscript
# Before:
match current_state:
    PlayerState.ON_FOOT:
        _handle_on_foot_logic(delta)
    PlayerState.IN_VEHICLE:
        _handle_in_vehicle_logic(delta)

# After:
var sm: PlayerStateMachine = ServiceRegistry.get_service("player_state_machine")
if sm.can_perform_action("move"):
    CommandBus.issue(move_command)
```

### 4.2 InputCommandSystem（输入命令转换）

```gdscript
# systems/input_command_system.gd
class_name InputCommandSystem
extends Node

## The ONLY system that reads raw Input. All other systems only see Commands.

func _process(_delta: float) -> void:
    ## Movement
    var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if dir.length() > 0:
        CommandBus.issue(Command.new(CommandType.MOVE_REQUEST, {
            "direction": dir,
            "is_sprinting": Input.is_action_pressed("shift")
        }))
    
    ## Dodge
    if Input.is_action_just_pressed("dodge"):
        CommandBus.issue(Command.new(CommandType.DODGE_REQUEST, {}))
    
    ## Combat
    if Input.is_action_just_pressed("light_attack"):
        CommandBus.issue(Command.new(CommandType.ATTACK_REQUEST, {
            "attack_type": "light",
            "weapon_slot": "actor"
        }))
    
    if Input.is_action_just_pressed("heavy_attack"):
        CommandBus.issue(Command.new(CommandType.HEAVY_CHARGE_START, {}))
    
    if Input.is_action_just_released("heavy_attack"):
        CommandBus.issue(Command.new(CommandType.HEAVY_CHARGE_RELEASE, {}))
    
    ## Vehicle / Interaction
    if Input.is_action_just_pressed("enter_vehicle"):
        CommandBus.issue(Command.new(CommandType.INTERACT_REQUEST, {}))
    
    ## Aim (sent as continuous data, not command)
    var aim_pos = get_global_mouse_position()
    ServiceRegistry.get_service("target_resolver").set_player_aim(aim_pos)
```

**Player.gd 中的所有 Input 读取全部消除。**

### 4.3 MovementSystem（移动系统）

```gdscript
# systems/movement_system.gd
class_name MovementSystem
extends Node

## Processes MOVE_REQUEST commands for all entities.

func _on_command_issued(command: Command) -> void:
    if command.type != CommandType.MOVE_REQUEST:
        return
    
    var entity_id = command.issuer_entity
    var node: Node2D = EntityManager.get_component(entity_id, "node")
    if not node:
        return
    
    var sm: PlayerStateMachine = ServiceRegistry.get_service("player_state_machine")
    if not sm.can_perform_action("move"):
        return
    
    var dir: Vector2 = command.payload.get("direction", Vector2.ZERO)
    var is_sprinting: bool = command.payload.get("is_sprinting", false)
    
    ## Resolve speed from StatSystem
    var stat_sys: StatSystem = ServiceRegistry.get_service("stat_system")
    var speed_stat = stat_sys.get_stat(entity_id, "speed")
    var base_speed = speed_stat.get_final_value() if speed_stat else 100.0
    var move_speed = base_speed * (1.8 if is_sprinting else 1.0)
    
    ## Apply velocity
    if node is CharacterBody2D:
        node.velocity = dir * move_speed
        node.move_and_slide()
    elif node is RigidBody2D:
        ## Vehicle case — handled differently
        pass
    
    ## Consume ATP for movement
    var move_cost = _calculate_movement_cost(base_speed, is_sprinting, dir.length())
    var res_sys: ResourcePoolSystem = ServiceRegistry.get_service("resource_pool_system")
    res_sys.consume(entity_id, "atp", move_cost)
```

**Player.gd 的移动逻辑全部迁移到这里。**

---

## Phase 5: 载具系统解耦（1周）

### 5.1 VehicleOccupancySystem（载具占用系统）

```gdscript
# systems/vehicle_occupancy_system.gd
class_name VehicleOccupancySystem
extends Node

class OccupancyData:
    var vehicle_entity: int
    var driver_entity: int = -1
    var is_occupied: bool = false

var _occupancy: Dictionary[int, OccupancyData] = {} # vehicle_entity -> data

func register_vehicle(vehicle_entity: int) -> void:
    var data = OccupancyData.new()
    data.vehicle_entity = vehicle_entity
    _occupancy[vehicle_entity] = data

func enter_vehicle(driver_entity: int, vehicle_entity: int) -> bool:
    var data = _occupancy.get(vehicle_entity)
    if not data or data.is_occupied:
        return false
    
    data.driver_entity = driver_entity
    data.is_occupied = true
    
    ## Transition player state
    var sm: PlayerStateMachine = ServiceRegistry.get_service("player_state_machine")
    sm.transition_to(PlayerStateMachine.State.IN_VEHICLE, driver_entity)
    
    ## Transfer input control
    var input_sys: InputCommandSystem = ServiceRegistry.get_service("input_command_system")
    input_sys.set_controlled_entity(vehicle_entity)
    
    ## Handle visual/camera transitions via commands
    CommandBus.issue(Command.new(CommandType.PLAYER_ENTERED_VEHICLE, {
        "player_entity": driver_entity,
        "vehicle_entity": vehicle_entity
    }))
    
    return true

func exit_vehicle(vehicle_entity: int) -> bool:
    var data = _occupancy.get(vehicle_entity)
    if not data or not data.is_occupied:
        return false
    
    var driver = data.driver_entity
    data.driver_entity = -1
    data.is_occupied = false
    
    var sm: PlayerStateMachine = ServiceRegistry.get_service("player_state_machine")
    sm.transition_to(PlayerStateMachine.State.ON_FOOT, driver)
    
    var input_sys: InputCommandSystem = ServiceRegistry.get_service("input_command_system")
    input_sys.set_controlled_entity(driver)
    
    CommandBus.issue(Command.new(CommandType.PLAYER_EXITED_VEHICLE, {
        "player_entity": driver,
        "vehicle_entity": vehicle_entity
    }))
    
    return true
```

**消除的耦合：**
- Player 不再直接操作 Vehicle 的 `input_component`
- Vehicle 不再直接操作 Player 的 `Camera2D.enabled`
- 所有视觉变化由 `VisualEffectSystem` 响应 Command 执行

---

## Phase 6: 代谢系统解耦（1周）

### 6.1 MetabolismSystem（新代谢系统）

将 Player.gd 中 **200 多行的代谢逻辑** 提取为独立 System：

```gdscript
# systems/metabolism_system.gd
class_name MetabolismSystem
extends Node

## Processes metabolism for ALL entities, not just the player.
## Driven by entity state (resting, moving, sprinting, in_vehicle).

var _entity_metabolic_states: Dictionary[int, MetabolicState] = {}

class MetabolicState:
    var entity_id: int
    var activity_level: float = 1.0  # 0.2=vehicle, 1.0=rest, 3.0=move, 11.0=sprint
    var atp_depletion_timer: float = 0.0

func set_activity_level(entity_id: int, level: float) -> void:
    var state = _get_or_create_state(entity_id)
    state.activity_level = level

func tick(delta: float) -> void:
    for entity_id in _entity_metabolic_states:
        _process_metabolism(entity_id, delta)

func _process_metabolism(entity_id: int, delta: float) -> void:
    var state = _entity_metabolic_states[entity_id]
    var res_sys: ResourcePoolSystem = ServiceRegistry.get_service("resource_pool_system")
    var stat_sys: StatSystem = ServiceRegistry.get_service("stat_system")
    
    ## 1. ATP consumption based on activity
    var atp_cost = state.activity_level * delta
    var had_atp = res_sys.get_current(entity_id, "atp") > 0
    var success = res_sys.consume(entity_id, "atp", atp_cost)
    
    ## 2. ATP recovery from glucose
    var atp_stat = stat_sys.get_stat(entity_id, "atp")
    var glucose_stat = stat_sys.get_stat(entity_id, "glucose")
    if atp_stat and glucose_stat and atp_stat.current_value < atp_stat.get_max_value():
        var atp_needed = atp_stat.get_max_value() - atp_stat.current_value
        var conversion_rate = _get_conversion_rate(entity_id)
        var atp_to_recover = min(atp_stat.base_value * delta, atp_needed)  # Use base recovery rate
        var glucose_cost = atp_to_recover / conversion_rate
        
        if glucose_stat.current_value >= glucose_cost:
            res_sys.consume(entity_id, "glucose", glucose_cost)
            res_sys.recover(entity_id, "atp", atp_to_recover)
        elif glucose_stat.current_value > 0:
            var partial_atp = glucose_stat.current_value * conversion_rate
            res_sys.consume(entity_id, "glucose", glucose_stat.current_value)
            res_sys.recover(entity_id, "atp", partial_atp)
    
    ## 3. Basal glucose consumption
    var basal_glucose = _get_basal_glucose_rate(entity_id) * delta * _get_basal_multiplier(state.activity_level)
    res_sys.consume(entity_id, "glucose", basal_glucose)
    
    ## 4. ATP depletion damage
    var current_atp = res_sys.get_current(entity_id, "atp")
    if current_atp < 0.001:
        state.atp_depletion_timer += delta
        if state.atp_depletion_timer >= 1.0:
            var hp = res_sys.get_current(entity_id, "health")
            if hp > 1:
                res_sys.consume(entity_id, "health", 1.0)
            state.atp_depletion_timer = fmod(state.atp_depletion_timer, 1.0)
    else:
        state.atp_depletion_timer = 0.0
```

**Player.gd 的所有代谢逻辑消失，仅剩：**
```gdscript
# Player.gd (after refactor)
func _ready():
    entity_id = EntityManager.create_entity()
    EntityManager.add_component(entity_id, "node", self)
    EntityManager.add_component(entity_id, "actor_data", actor_data)
    
    var stat_sys: StatSystem = ServiceRegistry.get_service("stat_system")
    stat_sys.initialize_from_actor_data(entity_id, actor_data)
```

---

## Phase 7: 动画与视觉系统解耦（1周）

### 7.1 AnimationSystem

```gdscript
# systems/animation_system.gd
class_name AnimationSystem
extends Node

## All animation requests go through here.

func play_animation(entity_id: int, animation_name: String, options: Dictionary = {}) -> void:
    var node: Node2D = EntityManager.get_component(entity_id, "node")
    if not node:
        return
    var sprite: AnimatedSprite2D = _find_animated_sprite(node)
    if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_name):
        sprite.play(animation_name)

func update_movement_animation(entity_id: int, velocity: Vector2, last_direction: Vector2) -> void:
    ## Centralized animation state machine
    var anim_name = "idle"
    if velocity.length_squared() > 0:
        anim_name = "walk"
    
    var dir_suffix = _resolve_direction_suffix(last_direction)
    var full_name = anim_name + "_" + dir_suffix
    
    play_animation(entity_id, full_name)
```

Actor 中 `_update_animation()` 的逻辑完全迁移到这里。

### 7.2 VisualEffectSystem（特效系统）

```gdscript
# systems/visual_effect_system.gd
class_name VisualEffectSystem
extends Node

func spawn_afterimage(entity_id: int) -> void:
    var node = EntityManager.get_component(entity_id, "node")
    ## Find sprite, clone it, add to scene, fade out
    pass

func show_damage_number(position: Vector2, amount: float) -> void:
    ## Centralized damage number spawning
    pass

func set_weapon_aim(entity_id: int, aim_target: Vector2) -> void:
    ## Aim all weapon visual nodes toward target
    var weapons: Array = EntityManager.get_component(entity_id, "weapon_visuals")
    for w in weapons:
        w.look_at(aim_target)
        w.rotation_degrees += 90
```

---

## Phase 8: 清理遗留组件（1周）

### 消亡的组件

| 组件 | 原因 | 替代方案 |
|---|---|---|
| `AttributeComponent` | 硬编码子组件发现，直接穿透访问 | `StatSystem` + `ResourcePoolSystem` |
| `HealthComponent` | 与 metabolism 同层级，但逻辑不同 | `"health"` stat in `StatSystem` |
| `MetabolismComponent` | 代谢逻辑散落在 Player 里 | `MetabolismSystem` |
| `SpeedComponent` | 单一数值，无需独立组件 | `"speed"` stat in `StatSystem` |
| `ToughnessComponent` | 与 Health 同模式 | `"toughness"` stat + `EffectSystem` |
| `ChargeComponent` | 作为节点存在，限制了灵活性 | `ChargeSystem` (全局数据) |
| `WeaponComponent` | 承载太多逻辑 + 输入泄漏 | `WeaponSystem` (数据) + `WeaponVisual` (纯视觉节点) |
| `HitDamageCalculator` | 穿透 target 组件 | `DamagePipeline` |
| `DodgeComponent` | 直接操作 actor 位置 + 侵入 metabolism | `MovementSystem` + `EffectSystem` + `PlayerStateMachine` |

### 保留但简化的组件

| 组件 | 保留原因 | 简化方式 |
|---|---|---|
| `ActorCombatComponent` | 仍需作为 Actor 的"战斗能力"标记 | 仅持有 `entity_id`，所有逻辑委托给 System |
| `VehicleCombatComponent` | 同上 | 仅持有 `entity_id`，委托给 System |
| `ComboSystem` | 连击逻辑复杂但自洽 | 保留为数据处理器，但由 `AttackPipeline` 调用 |
| `HeavyAttackSystem` | 重击规则复杂但自洽 | 保留为数据处理器，由 `ChargeSystem` + `AttackPipeline` 调用 |
| `PlayerInputComponent` | 输入抽象层有价值 | 保留，但只被 `InputCommandSystem` 读取 |
| `InventoryComponent` | 库存逻辑相对独立 | 保留，但物品使用需通过 CommandBus |

---

## 重构后的架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    GODOT ENGINE LAYER                        │
│  (Rendering, Physics, Input, Audio — not our concern)       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  AnimationSystem    VisualEffectSystem    AudioSystem         │
│   ( speakers only — all commands from below )                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     GAME SYSTEMS LAYER                       │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  StatSystem  │  │ ResourcePool │  │ EffectSystem │       │
│  │  (数值定义)   │  │   (消耗/恢复) │  │ (Buff/Debuff)│      │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ ChargeSystem │  │ WeaponSystem │  │ Metabolism   │       │
│  │  (蓄力状态)   │  │  (武器实例)   │  │   (代谢时钟)  │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │TargetResolver│  │DamagePipeline│  │PlayerState   │       │
│  │(目标解析)    │  │  (伤害计算)   │  │   Machine    │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Movement   │  │   Vehicle    │  │ Inventory    │       │
│  │   System     │  │  Occupancy   │  │  System      │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    COMMAND & CONTROL LAYER                     │
│                                                              │
│   ┌────────────────┐      ┌────────────────┐              │
│   │   InputCommand   │  →   │   CommandBus   │              │
│   │     System       │      │ (验证+分发)     │              │
│   └────────────────┘      └────────────────┘              │
│                                │                           │
│                    ┌───────────┴───────────┐                │
│                    ▼                       ▼                │
│              ┌─────────┐           ┌─────────────┐          │
│              │ Tick    │           │   EventBus  │          │
│              │ System  │           │  (UI/decoupled)│         │
│              └─────────┘           └─────────────┘          │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    ENTITY / DATA LAYER                       │
│                                                              │
│   EntityManager ──→ Dictionary[entity_id → {components}]     │
│                                                              │
│   ActorData (Resource) ──→ StatDefinition[]                 │
│   WeaponData (Resource) ──→ AttackDefinition[]              │
│   ItemData (Resource)                                     │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    SCENE / NODE LAYER （最薄）                  │
│                                                              │
│   Player (CharacterBody2D)                                   │
│     ├── Sprite2D (visuals)    ← 仅视觉，无逻辑                 │
│     ├── CollisionShape2D                                     │
│     └── ActorCombatComponent  ← 仅 entity_id + 委托            │
│                                                              │
│   Vehicle (RigidBody2D)                                      │
│     ├── AnimatedSprite2D                                     │
│     ├── CollisionShape2D                                     │
│     └── VehicleCombatComponent ← 仅 entity_id + 委托           │
│                                                              │
│   WeaponVisual (Node2D)     ← 纯视觉节点，无 fire() 逻辑       │
│     └── Sprite2D                                             │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 迁移路线图

### Wave 1: 不破坏功能的基础设施（1周）
- [ ] 新建 `systems/ecs/`、`systems/pipeline/` 目录
- [ ] 实现 `EntityManager`、`ServiceRegistry`、`CommandBus`（空壳版）
- [ ] 让 `Player` 和 `Actor` 注册 entity_id
- [ ] 在旧代码旁边并行写新 System，**不替换旧逻辑**

### Wave 2: 数值系统（1周）
- [ ] 实现 `StatSystem`、`ResourcePoolSystem`
- [ ] 将 `ActorRuntimeState` / `ActorData` 映射到 StatSystem
- [ ] 为 Player 注册所有 stats
- [ ] 逐步替换 `attribute_component.metabolism_component` 调用为 ResourcePoolSystem 调用
- [ ] 保留旧代码作为 fallback，通过开关切换

### Wave 3: 攻击管道（2周）
- [ ] 实现 `WeaponSystem`（与 WeaponComponent 并行）
- [ ] 实现 `ChargeSystem`（全局数据版）
- [ ] 实现 `TargetResolverSystem`
- [ ] 实现 `DamagePipeline`
- [ ] 重构 `ActorCombatComponent` 为委托模式
- [ ] 消灭 `get_global_mouse_position()` 的所有泄漏点

### Wave 4: 输入与状态（1周）
- [ ] 实现 `InputCommandSystem`
- [ ] 实现 `PlayerStateMachine`
- [ ] 重构 Player.gd 的移动/战斗/载具逻辑为 Command 分发
- [ ] Player.gd 仅剩 `_ready()` 初始化和最小化的信号连接

### Wave 5: 代谢与特效（1周）
- [ ] 实现 `MetabolismSystem`
- [ ] 迁移 Player.gd 的 `_process_metabolism()` 全部逻辑
- [ ] 实现 `AnimationSystem`、`VisualEffectSystem`
- [ ] 迁移 Actor._update_animation()

### Wave 6: 载具与收尾（1周）
- [ ] 实现 `VehicleOccupancySystem`
- [ ] 消除 Player-Vehicle 直接耦合
- [ ] 删除所有被取代的旧组件（.AttributeComponent、.MetabolismComponent 等）
- [ ] 全面回归测试

### Wave 7: 高级优化（可选，1-2周）
- [ ] `SpawnSystem`（对象池化 bullets/projectiles）
- [ ] `SaveReplaySystem`（基于 Command 序列的存档/回放）
- [ ] `NetworkSyncSystem`（Command 序列网络同步）

---

## 风险与缓解

| 风险 | 缓解措施 |
|---|---|
| 重构周期过长，中途放弃 | Wave 1-2 完成后即可逐步替换，每波都可独立合入 |
| 性能下降（Dictionary 查找 vs 直接引用） | 使用 entity_id int 作为 key，GDScript Dictionary 查找很快；瓶颈在真实 profiling 后优化 |
| 多人团队协作冲突 | 每人负责一个 Wave，互不干扰 |
| Godot 信号跨 System 通信延迟 | 对高频系统（如 MovementSystem）保留直接委托，少用信号 |
| 调试难度增加 | CommandBus 可记录完整日志，Debug UI 可可视化所有 System 状态 |

---

## 一句话总结

> **从 "组件持有节点引用并直接操作" 转变为 "纯数据实体 + 全局无状态 System + 命令管道"。**
> 
> Player.gd 的 400 行将缩减到 50 行以内，所有业务逻辑被 10+ 个专注单一职责的 System 接管，
> 系统之间仅通过 `entity_id`、`Command` 和 `ServiceRegistry` 交互。
