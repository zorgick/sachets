const {pnpPlugin} = require('@yarnpkg/esbuild-plugin-pnp')

require('esbuild').build({
  entryPoints: ['./src/index.ts'],
  bundle: true,
  format: 'cjs',
  outdir: 'dist',
  plugins: [pnpPlugin()],
}).catch(() => process.exit(1))
