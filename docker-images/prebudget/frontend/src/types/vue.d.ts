/// <reference types="vite/client" />

// This file basically silences editor warnings for importing "*.vue" files

declare module '*.vue' {
  import type { DefineComponent } from 'vue';

  const component: DefineComponent<{}, {}, any>;
  export default component;
}
