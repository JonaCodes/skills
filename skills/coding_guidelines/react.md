## React specific guidelines

- Use Mantine components and their attributes as much as possible instead of custom CSS
  - For example, use `<Text fz='xs'>` instead of `<div style={{ fontSize: '0.75rem' }}>` or a class with that styling. This applies to all available mantine props, such as `fz`, `fw`, `c`, `w`, etc.
  - Use the `Flex`, `Group`, or `Stack` component for layout. Avoid custom CSS for layout.
  - There should be virtually no "raw" HTML elements in JSX files. Use mantine components.
- Use mobx as a state management. Avoid prop drilling, and even passing props altogether if you can just use the store
- Re-use existing components, staying as DRY as possible
