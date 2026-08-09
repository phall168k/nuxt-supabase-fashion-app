export default defineNuxtRouteMiddleware((to) => {
    const user = useSupabaseUser();
    const isLoginPage = to.path === '/auth/login';
    const isAdminRoute = to.path === '/admin' || to.path.startsWith('/admin/');

    if (isLoginPage) {
        if (user.value) {
            return navigateTo('/', { replace: true });
        }

        return;
    }

    if (!user.value) {
        return navigateTo({
            path: '/auth/login',
            query: { redirect: to.fullPath },
            replace: true,
        });
    }

    const metadataRole = typeof user.value.user_metadata?.role === 'string'
        ? user.value.user_metadata.role.toLowerCase()
        : '';
    const appRole = typeof user.value.app_metadata?.role === 'string'
        ? user.value.app_metadata.role.toLowerCase()
        : '';

    if (isAdminRoute && (metadataRole === 'customer' || appRole === 'customer')) {
        return navigateTo('/', { replace: true });
    }
})
