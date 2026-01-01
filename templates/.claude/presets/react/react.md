# React/TypeScript Development Rules

## Component Design

### Functional Components
- Use functional components with hooks
- Keep components small and focused
- Extract custom hooks for reusable logic
- Use TypeScript for all components

### Component Structure
```tsx
// Standard component template
interface Props {
  title: string;
  onAction?: () => void;
}

export function MyComponent({ title, onAction }: Props) {
  const [state, setState] = useState<string>('');

  const handleClick = useCallback(() => {
    onAction?.();
  }, [onAction]);

  return (
    <div onClick={handleClick}>
      {title}
    </div>
  );
}
```

## Hooks Best Practices

### useState
- Use descriptive state names
- Group related state or use useReducer
- Avoid derived state (compute from existing)

### useEffect
- Always specify dependencies
- Clean up subscriptions/timers
- Avoid objects in dependency array

### useMemo/useCallback
- Use for expensive computations
- Use for stable references passed to children
- Don't overuse; measure first

## State Management

### Local State
- useState for simple component state
- useReducer for complex state logic

### Global State
- Context for theme/auth/localization
- Zustand/Redux for complex app state
- React Query/SWR for server state

## TypeScript

### Type Definitions
```tsx
// Props with children
interface Props extends PropsWithChildren {
  variant: 'primary' | 'secondary';
}

// Event handlers
const handleChange = (e: ChangeEvent<HTMLInputElement>) => {};

// Generic components
function List<T>({ items, renderItem }: ListProps<T>) {}
```

## Project Structure
```
src/
├── components/
│   ├── ui/              # Reusable UI components
│   └── features/        # Feature-specific components
├── hooks/               # Custom hooks
├── lib/                 # Utilities and helpers
├── pages/               # Page components
├── styles/              # Global styles
└── types/               # TypeScript types
```

## Testing
- Jest + React Testing Library
- Test user behavior, not implementation
- Use data-testid sparingly
- Mock external dependencies
