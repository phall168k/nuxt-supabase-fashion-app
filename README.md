# Fashion Store

Fashion Store is a full-stack fashion e-commerce and inventory management application built with Nuxt and Supabase. It provides a bilingual customer storefront, an administrative dashboard, stock and sales management, user profiles, and Bakong KHQR payments.

Customers can browse products, filter by category, search the catalog, maintain a shopping cart, pay by scanning a dynamically generated KHQR code, and review their purchase history. Administrators can manage products, categories, banners, inventory, payment methods, sales, and user roles from a protected dashboard.

## Main features

### Customer storefront

- Responsive fashion storefront with English and Khmer localization
- Product search and parent/child category filtering
- Product details, related products, prices, discounts, images, and stock availability
- Authenticated shopping cart with quantity management
- Customer registration, login, profile image, profile editing, and password changes
- Purchase-order history with product images
- Dynamic SEO, Open Graph, Twitter cards, canonical URLs, and Product structured data

### KHQR payments

- Dynamic merchant KHQR generation using the selected payment method
- USD and KHR support
- Configurable QR expiration in minutes
- KHQR payload verification
- Bakong transaction status polling
- Automatic sale completion after successful payment
- Payment success notification and sound

### Administration

- Dashboard statistics and Chart.js visualizations
- Category management with hierarchical parent/child categories
- Automatic category codes such as `CAT00001`
- Product management with UUID identifiers, multiple images, discounts, and stock records
- Stock-in and stock-adjustment workflows
- Sales and picked-product management
- Dynamic payment methods and merchant accounts
- Homepage banner management
- User-profile and administrator-role management
- Middleware-protected `/admin` routes

## Technology stack

- [Nuxt 4](https://nuxt.com/) and Vue 3
- TypeScript
- [Supabase](https://supabase.com/) Auth, PostgreSQL, Row Level Security, and Storage
- Element Plus
- Tailwind CSS
- Pinia
- Nuxt i18n
- Chart.js
- `bakong-khqr`
- `qrcode`

## Project structure

```text
components/          Reusable storefront components
composables/         Shared reactive application logic
i18n/locales/        English and Khmer translations
layouts/             Customer, admin, and authentication layouts
middleware/          Authentication and administrator authorization
pages/               Storefront, authentication, and admin pages
public/              Logo, favicon assets, robots.txt, and payment sound
server/api/khqr/     KHQR generation, validation, and payment-status APIs
server/utils/        KHQR utility functions
stores/              Pinia stores
supabase/migrations/ Database schema, functions, policies, and storage setup
```

## Environment variables

Create a `.env` file in the project root:

```env
NUXT_PUBLIC_URL=http://localhost:3000

NUXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT.supabase.co
NUXT_PUBLIC_SUPABASE_KEY=YOUR_SUPABASE_ANON_KEY

NUXT_BAKONG_API_TOKEN=YOUR_BAKONG_API_TOKEN
NUXT_BAKONG_API_BASE_URL=https://api-bakong.nbc.gov.kh

NODE_ENV=development
```

Never expose a Supabase service-role key or Bakong API token through a `NUXT_PUBLIC_*` variable. Bakong credentials are read only by server API routes.

## Installation

Install the dependencies:

```bash
npm install
```

Start the development server:

```bash
npm run dev
```

The application is available at `http://localhost:3000` by default.

## Supabase setup

Install or run the Supabase CLI through `npx`, then authenticate and link the project:

```bash
npx supabase login
npx supabase link --project-ref YOUR_PROJECT_REF
```

Preview pending migrations:

```bash
npx supabase db push --dry-run
```

Apply them to the linked project:

```bash
npx supabase db push
```

The migrations create the application tables, database functions, Row Level Security policies, storage bucket, UUID product relationships, automatic category codes, user profiles, and signup-avatar flow.

### Fresh local database

Docker must be running for the local Supabase stack:

```bash
npx supabase start
npx supabase db reset
```

`db reset` deletes local database data and reapplies every migration under `supabase/migrations`.

### Fresh linked database

The following command is destructive and should only be used for a development or staging project:

```bash
npx supabase db reset --linked
```

It removes the linked database schema and rebuilds it from the local migrations. Back up important data before using it.

## Authentication and roles

Every Supabase Auth user is mapped to one row in `public.user_profiles`.

```text
auth.users.id → user_profiles.user_id
```

New registrations receive the `customer` role automatically. Only profiles whose role is exactly `admin` can access `/admin` routes. Non-admin users attempting to visit an admin route are redirected to the storefront.

The bootstrap migration promotes the first eligible profile to administrator when setting up a fresh database. Administrator roles can later be managed from the User Profiles page.

## Payment flow

1. The customer adds available products to the cart.
2. The customer selects an active payment method.
3. The server generates a merchant KHQR using that payment method's account and currency.
4. The customer scans the QR code with a supported banking application.
5. The storefront periodically checks the transaction MD5 through the Bakong API.
6. After payment is confirmed, the database creates/completes the sale and updates stock.
7. The checkout dialog closes, a success message appears, and `public/success-sound.mp3` is played.

Payment accounts, currencies, merchant cities, labels, and logos are managed dynamically from the admin Payment Methods page.

## Production

Create a production build:

```bash
npm run build
```

Preview the production server locally:

```bash
npm run preview
```

Nuxt DevTools are enabled only when `NODE_ENV=development`.

## Important notes

- Product IDs use UUIDs throughout the product and related inventory/sales tables.
- Product images and user avatars are stored in the public `fashion-images` bucket.
- Database authorization is enforced with Supabase Row Level Security and security-definer functions.
- Client-side admin menu visibility is only a UI convenience; the auth middleware and database policies provide the actual access control.
- Test KHQR payments and database migrations in a non-production environment before deployment.
