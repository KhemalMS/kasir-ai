export const ROLE_HOME = {
    admin: '/dashboard',
    kasir: '/mulai-shift',
    kitchen: '/dapur',
};

export const ROLE_ROUTES = {
    admin: null,
    kasir: ['/kasir', '/mulai-shift', '/tutup-shift'],
    kitchen: ['/dapur'],
};

export function getHomeForRole(role) {
    return ROLE_HOME[role] || '/dashboard';
}
