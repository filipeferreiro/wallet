import { createRouter, createWebHistory } from 'vue-router';
import { useWalletStore } from '../stores/walletStore';
import Login from '../views/Login.vue';
import Dashboard from '../views/Dashboard.vue';

const Register = () => import('../views/Register.vue');
const History = () => import('../views/History.vue');

const routes = [
    {
        path: '/login',
        name: 'Login',
        component: Login,
        meta: { guest: true }
    },
    {
        path: '/register',
        name: 'Register',
        component: Register,
        meta: { guest: true }
    },
    {
        path: '/',
        name: 'Dashboard',
        component: Dashboard,
        meta: { auth: true }
    },
    {
        path: '/historico',
        name: 'History',
        component: History,
        meta: { auth: true }
    }
];

const router = createRouter({
    history: createWebHistory(),
    routes,
});

router.beforeEach((to, from, next) => {
    const walletStore = useWalletStore();   

    if (to.meta.auth && !walletStore.isAuthenticated) {
        return next({ name: 'Login' });
    }

    if (to.meta.guest && walletStore.isAuthenticated) {
        return next({ name: 'Dashboard' });
    }

    next();
});

export default router;