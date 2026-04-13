import { useSession, signIn, signUp, signOut } from '../lib/auth-client';

export function useAuth() {
    const session = useSession();

    return {
        user: session.data?.user ?? null,
        session: session.data?.session ?? null,
        isPending: session.isPending,
        isAuthenticated: !!session.data?.user,
        signIn: {
            email: (email, password) => signIn.email({ email, password }),
        },
        signUp: {
            email: (email, password, name) => signUp.email({ email, password, name }),
        },
        signOut: () => signOut(),
    };
}
