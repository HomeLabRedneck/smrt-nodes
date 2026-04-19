extends RefCounted

enum STMWindowRoles {
    STM_ARTIFACT,
    STM_CONSUMER,
    STM_STORAGE,
    STM_MANAGER,
}

var window: WindowBase
var inputs: Dictionary[String, ResourceContainer]
var role: STMWindowRoles = STMWindowRoles.STM_ARTIFACT

var provided: Array = []
var dependent: Array = []
var icdata: Dictionary[String, STMContainerData]

func _init(window: WindowBase) -> void:
    self.window = window
    var _containers: Array = window.containers if "containers" in window else []
    var containers = _containers.filter(func(c): return c.is_in_group("input"))
    for container in containers:
        var cid: String = container.id if "id" in container else str(container.get_instance_id())
        inputs.set(cid, container)

    set_containers()

func set_containers(sources: Array = []) -> void:
    provided = inputs.keys().filter(sources.has)
    dependent = inputs.keys().filter(func(n): return !provided.has(n) && _is_material(inputs[n]))
    for name in provided:
        icdata.erase(name)
    for name in dependent:
        if !icdata.has(name):
            icdata[name] = STMContainerData.new(inputs[name])
    if "demand" in window:
        role = STMWindowRoles.STM_MANAGER
    elif !provided.is_empty():
        role = STMWindowRoles.STM_CONSUMER
    elif window.is_in_group("window"):
        role = STMWindowRoles.STM_STORAGE
    else:
        role = STMWindowRoles.STM_ARTIFACT

func get_demand() -> float:
    if provided.is_empty():
        return 0.0
    if role == STMWindowRoles.STM_MANAGER:
        return window.demand
    if "goal" in window && !dependent.is_empty():
        return get_min_prod() * window.goal
    var _req = provided.reduce(func(acc, n): return acc + (inputs[n].required if "required" in inputs[n] else 0.0), 0.0)
    if !is_zero_approx(_req):
        return _req
    return 1.0

func get_count_demand() -> float:
    if provided.is_empty():
        return 0.0
    if role == STMWindowRoles.STM_MANAGER:
        return window.demand
    if "goal" in window && !dependent.is_empty():
        return get_min_count() * window.goal
    var _req = provided.reduce(func(acc, n): return acc + (inputs[n].required if "required" in inputs[n] else 0.0), 0.0)
    if !is_zero_approx(_req):
        return _req
    return 1.0

func set_count(value: float) -> void:
    var size = provided.size()
    for container in provided.map(func(s): return inputs[s]):
        container.count = value/size

func get_min_prod() -> float:
    if dependent.is_empty():
        return 0.0
    if dependent.size() == 1:
        return icdata[dependent[0]].get_prod()
    return dependent.map(func(name): return icdata[name].get_prod()).reduce(min)

func get_min_count() -> float:
    if dependent.is_empty():
        return 0.0
    if dependent.size() == 1:
        return icdata[dependent[0]].get_count()
    return dependent.map(func(name): return icdata[name].get_count()).reduce(min)


func get_goal() -> float:
    return window.goal if role == STMWindowRoles.STM_CONSUMER else 0.0

func update():
    for cd in icdata.values():
        cd.update()

func _is_material(c: ResourceContainer) -> bool:
    if "type" not in c:
        return false
    return c.type == Utils.resource_types.MATERIAL || c.type == Utils.resource_types.MATERIAL_LIMITED


class STMContainerData extends RefCounted:
    var container: ResourceContainer
    var multiplier: float = 0.0

    func _init(c: ResourceContainer) -> void:
        container = c
        multiplier = _get_multi()

    func get_prod() -> float:
        var prod: float = container.production if "production" in container else 0.0
        return multiplier * prod

    func get_count() -> float:
        var cnt: float = container.count if "count" in container else 0.0
        return multiplier * cnt

    func _get_multi() -> float:
        var req: float = container.required if "required" in container else 1.0
        var divisor = req if !is_zero_approx(req) else 1.0
        return pow(divisor, -1)

    func update() -> void:
        multiplier = _get_multi()
