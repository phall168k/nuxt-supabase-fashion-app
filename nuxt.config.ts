// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  modules: [
    '@element-plus/nuxt',
    '@nuxtjs/tailwindcss',
    '@nuxtjs/i18n',
    '@nuxt/icon',
    '@pinia/nuxt',
    '@nuxtjs/google-fonts',
    '@nuxtjs/supabase',
  ],
  googleFonts: {
    families: {
      Nokora: true,
    }
  },
  tailwindcss: {
    config: {
      theme: {
        fontFamily: {
          sans: ['"Nokora"', 'ui-sans-serif', 'system-ui', 'sans-serif'],
          Nokora: ['"Nokora"', 'ui-sans-serif', 'system-ui', 'sans-serif'],
        }
      }
    }
  },
  i18n: {
    locales: [
      { code: 'en', file: 'en.json', language: 'en-US' },
      { code: 'km', file: 'km.json', language: 'KH' }
    ],
    defaultLocale: 'en',
    langDir: 'locales/',     
    strategy: 'no_prefix',  
  },
  supabase: {
    redirect: false,
    types: false,
  },
  runtimeConfig: {
    bakongApiToken: process.env.NUXT_BAKONG_API_TOKEN,
    bakongApiBaseUrl: process.env.NUXT_BAKONG_API_BASE_URL || 'https://api-bakong.nbc.gov.kh',
    public: {
      apiBaseUrl: process.env.API_BASE_URL
    }
  },
})
