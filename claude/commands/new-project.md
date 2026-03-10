Scaffold a new project using the workspace's default stack.

Project name: $ARGUMENTS

If no name is provided, ask for one.

## Steps

1. Create the project directory under the current working directory
2. Initialize with `npm init -y`
3. Set up the stack based on project type:

### Next.js Web App (default)

- `npx create-next-app@latest` with: TypeScript, Tailwind, ESLint, App Router, `src/` directory off, import alias `@/*`
- Add dependencies: `zod`
- Add dev dependencies: `vitest @testing-library/react`
- Set up strict TypeScript in `tsconfig.json`
- Create a basic project structure following workspace conventions (kebab-case files, named exports)

### If the user specifies a different type, adapt accordingly

4. Initialize git with `git init`
5. Create a `CLAUDE.md` with project-specific rules inheriting from the workspace conventions
6. Create an initial commit: `chore: scaffold project`
7. Report what was created and suggest next steps
