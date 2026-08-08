export default defineNuxtRouteMiddleware((to) => {
    const user = useSupabaseUser();
    const isLoginPage = to.path === '/auth/login';

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
})
