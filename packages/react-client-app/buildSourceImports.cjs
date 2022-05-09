const {pnpPlugin} = require('@yarnpkg/esbuild-plugin-pnp')

require('esbuild').build({
  entryPoints: ['testSourceImportsOnly.tsx'],
  bundle: true,
  outfile: 'out.js',
  plugins: [pnpPlugin()],
  minify: true
}).catch(() => process.exit(1))
