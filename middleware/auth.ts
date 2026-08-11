export default defineNuxtRouteMiddleware(async (to) => {
    const supabase = useSupabaseClient();
    const isGuestAuthPage = to.path === '/auth/login' || to.path === '/auth/sign-up';
    const isAdminRoute = to.path === '/admin' || to.path.startsWith('/admin/');

    const { data: { user }, error: userError } = await supabase.auth.getUser();

    // Login and customer registration must remain accessible to guests.
    if (isGuestAuthPage) {
        if (user) {
            return navigateTo('/', { replace: true });
        }

        return;
    }

    if (userError || !user) {
        return navigateTo({
            path: '/auth/login',
            query: { redirect: to.fullPath },
            replace: true,
        });
    }

    if (!isAdminRoute) {
        return;
    }

    const { data: profile, error: profileError } = await supabase
        .from('user_profiles')
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();

    const role = typeof profile?.role === 'string'
        ? profile.role.trim().toLowerCase()
        : '';

    // Deny access when the profile is missing, cannot be loaded, or is not admin.
    if (profileError || role !== 'admin') {
        return navigateTo('/', { replace: true });
    }
});
