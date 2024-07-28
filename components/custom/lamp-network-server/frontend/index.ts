import { createApp } from 'vue'
import ToastPlugin from 'vue-toast-notification';
import App from './App.vue'

const app = createApp(App)
app.use(ToastPlugin.default);
app.mount('#app')
