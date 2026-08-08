# Nuxt Minimal Starter

Look at the [Nuxt documentation](https://nuxt.com/docs/getting-started/introduction) to learn more.

## Setup

Make sure to install dependencies:

```bash
# npm
npm install

# pnpm
pnpm install

# yarn
yarn install

# bun
bun install
```

## Development Server

Start the development server on `http://localhost:3000`:

```bash
# npm
npm run dev

# pnpm
pnpm dev

# yarn
yarn dev

# bun
bun run dev
```

## Production

Build the application for production:

```bash
# npm
npm run build

# pnpm
pnpm build

# yarn
yarn build

# bun
bun run build
```

Locally preview production build:

```bash
# npm
npm run preview

# pnpm
pnpm preview

# yarn
yarn preview

# bun
bun run preview
```

Check out the [deployment documentation](https://nuxt.com/docs/getting-started/deployment) for more information.


# 1. Check CLI
npx supabase --version

# 2. Update CLI
npm install -D supabase@latest

# 3. Login again
npx supabase logout
npx supabase login

# 4. Check your Supabase projects
npx supabase projects list

# 5. Re-link
npx supabase link --project-ref YOUR_PROJECT_REF

# 6. Preview migrations
npx supabase db push --dry-run

# 7. Push
npx supabase db push

<!-- hzgtzadaduhyxqahebvu -->