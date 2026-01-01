# Unity/C# Development Rules

## Code Architecture

### Component Design
- Keep MonoBehaviours focused and small
- Use composition over inheritance
- Separate data from behavior (ScriptableObjects)
- Use interfaces for dependency injection
- Avoid singletons; prefer dependency injection

### Performance
- Cache component references in Awake/Start
- Avoid Find() calls in Update
- Use object pooling for frequently spawned objects
- Minimize garbage allocation in hot paths
- Use structs for small data containers

### Unity Lifecycle
```csharp
// Initialization order
private void Awake() { /* Initialize self */ }
private void OnEnable() { /* Subscribe to events */ }
private void Start() { /* Initialize with dependencies */ }
private void OnDisable() { /* Unsubscribe from events */ }
private void OnDestroy() { /* Cleanup */ }
```

## C# Best Practices

### Naming Conventions
- PascalCase for public members
- camelCase for private fields (with _ prefix optional)
- Use meaningful, descriptive names
- Prefix interfaces with 'I'

### Code Style
```csharp
// Properties over public fields
public float Health { get; private set; }

// Null-conditional operators
var damage = weapon?.GetDamage() ?? 0;

// Events with proper patterns
public event Action<int> OnScoreChanged;
```

### Common Patterns
```csharp
// Singleton (if really needed)
public static GameManager Instance { get; private set; }
private void Awake() => Instance = this;

// Object pooling
private Queue<GameObject> pool = new();
public GameObject Get() => pool.Count > 0 ? pool.Dequeue() : Instantiate(prefab);
public void Return(GameObject obj) { obj.SetActive(false); pool.Enqueue(obj); }
```

## Project Structure
```
Assets/
├── Scripts/
│   ├── Core/           # Game systems
│   ├── Player/         # Player-related
│   ├── Enemies/        # Enemy-related
│   ├── UI/             # UI scripts
│   └── Utils/          # Utilities
├── Prefabs/
├── Scenes/
├── ScriptableObjects/
└── Art/
```

## Testing
- Use Unity Test Framework
- Write unit tests for logic
- Use Play Mode tests for integration
- Mock MonoBehaviour dependencies
