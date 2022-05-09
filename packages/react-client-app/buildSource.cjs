const {pnpPlugin} = require('@yarnpkg/esbuild-plugin-pnp')

require('esbuild').build({
  entryPoints: ['App.tsx'],
  bundle: true,
  outfile: 'out.js',
  minify: true,
  plugins: [pnpPlugin()],
}).catch(() => process.exit(1))
