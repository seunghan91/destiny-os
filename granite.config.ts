import { defineConfig } from '@apps-in-toss/web-framework/config';

export default defineConfig({
  appName: 'REPLACE_WITH_APPS_IN_TOSS_APPNAME',
  brand: {
    displayName: '2026 신년운세',
    primaryColor: '#3182F6',
    icon: '',
  },
  web: {
    host: 'localhost',
    port: 5173,
    commands: {
      dev: 'python3 -m http.server 5173 --directory build/web',
      build: 'flutter build web --release',
    },
  },
  permissions: [],
  outdir: 'build/web',
  webViewProps: {
    type: 'partner',
  },
});
