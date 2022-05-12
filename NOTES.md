## Glossary

PnP - [Plug and Play](https://yarnpkg.com/features/pnp)

## Checklist:

## TYPESCRIPT

- [x] typescript cold start _LSP_ capabilities for workspaces
      Typescript in IDE ([LSP](https://microsoft.github.io/language-server-protocol/)) is working with the source code. However,
      _yarn_ (any execution command) uses a compiled codebase (e.g., _dist/index.js_), that has a different location.
      To solve the problem with different locations , we need to instruct typescript into thinking,
      that the source code is actually a distributed codebase. This will save us from build workspaces first and
      get LSP capabilities for them later.
      Notice that, "modules/ui/package.json" has _main" property pointing to "dist/index" file. This is
      for \_yarn_ commands. For typescript we create aliases in _paths_ property, with exact same
      names as yarn workspaces, and point to any file in the "src" (source) directory. This way an IDE
      can see the types of the referenced codebase without building it first.

## YARN

- [x] add editor integrations for yarn 3
      this requires installing _typescript_, _eslint_, _prettier_ dev-dependencies into the root
      and running `yarn dlx @yarnpkg/sdks base` command, that will create editor settings (here, for neovim).
      See how-to on [this page](https://yarnpkg.com/getting-started/editor-sdks) for other editors.
      This step is very important for _PnP_ modules, since it tells typescript where to look for modules.

- [x] investigate why workspace doesn't see an external dependency
      Seems the problem was in _PnP_ modules. Switched back to node linker.
      Need to investigate later, why it is broken.

- [x] Yarn workspaces tested
      A pretty evident solution, works with `yarn` command, after
      all dependencies are installed, including workspaces.
      The command `yarn install` in the root of the repo produces
      "yarn.lock" file with a following entry, that means, that _yarn_
      is aware of the workspace dependency.

  ```js
  "@sachets/ui@workspace:^, @sachets/ui@workspace:modules/ui":
  version: 0.0.0-use.local
  resolution: "@sachets/ui@workspace:modules/ui"
  languageName: unknown
  linkType: soft
  ```

- [x] Investigate why _PnP_ is not working correctly with node\*modules.
      Probably multiple installs with different _nodeLinker_ options broke yarn at some point.
      Removed all yarn generated files and directories, _PnP_ works again. Workspaces now see
      modules from _PnP_.

- [x] yarn workspaces advanced level

  - `yarn workspaces list --json --since=` command gives a very nice output of changed
    workspaces since a certain commit/tag/branch. The output can later be used in scripting.
  - `yarn workspaces foreach` has a significant value for optimizing CI and hooks runs. It
    also has `--since` flag that helps with targeting only changed workspaces.
    - `yarn workspaces foreach -p` runs common workspaces commands in parallel.
      For example, let's add to "@sachets/ui" and "react-client-app" workspaces
      _echo_ script and execute this command `yarn workspaces foreach -pv run echo`,
      which should print "Hello from %workspace name%".
      The output may differ, since the workspaces commands run in parallel and don't wait for
      each other and ignore exit status codes.
    ```bash
    ➤ YN0000: [@sachets/ui]: Process started
    ➤ YN0000: [react-client-app]: Process started
    ➤ YN0000: [@sachets/ui]: Hello from @sachets/ui
    ➤ YN0000: [@sachets/ui]: Process exited (exit code 0), completed in 0s 80ms
    ➤ YN0000: [react-client-app]: Hello from react-client-app
    ➤ YN0000: [react-client-app]: Process exited (exit code 0), completed in 0s 76ms
    ➤ YN0000: Done in 0s 85ms
    ```
    - `yarn workspaces foreach -pt` in turn makes yarn to wait for workspace dependencies
      to finish, even if the parallel flag is on. In our example "react-client-app" depends on
      "@sachets/ui", so the output will be:
    ```bash
    ➤ YN0000: [@sachets/ui]: Process started
    ➤ YN0000: [@sachets/ui]: Hello from @sachets/ui
    ➤ YN0000: [@sachets/ui]: Process exited (exit code 0), completed in 0s 46ms
    ➤ YN0000: [react-client-app]: Process started
    ➤ YN0000: [react-client-app]: Hello from react-client-app
    ➤ YN0000: [react-client-app]: Process exited (exit code 0), completed in 0s 39ms
    ```
    This command interupts execution if the dependent workspace exits with the status
    code other than **0**. So it is quite handy to control the flow, when we need all
    dependencies to succeed.
    ```bash
    ➤ YN0000: [@sachets/ui]: Process started
    ➤ YN0000: [@sachets/ui]: Hello from @sachets/ui
    ➤ YN0000: [@sachets/ui]: Process exited (exit code 1), completed in 0s 49ms
    ➤ YN0000: The command failed for workspaces that are depended upon by other workspaces; can't satisfy the dependency graph
    ➤ YN0000: Failed with errors in 0s 53ms
    ```

- [] Discover possibilities of `foreach` command on nested workspaces

## ESBUILD

- [x] Test out _esbuild_ in monorepo
      Seems like (esbuild) knows how to resolve chunks from node*modules.
      Nothing special, if it uses node approach, that relies on climbing
      the directories, until node_modules directory is found.
      However it doesn't work with workspaces imports. It can import the modules from workspaces, but
      dependencies (from "node_modules", so far) of that modules remain unresolved. The strange thing is
      that \_esbuild* bundles modules from workspaces from the source directory and not uses distributed
      version of the code. Probably it is related to tsconfig aliases. A possible solution might be in
      using another tsconfig, that have aliases to dist directories.

- [x] Try to alias dist directories to solve the problem with workspaces imports
      Seems to work. When alias is pointing to the dist directory, execution of the bundled file
      doesn't fall.

- [x] Test if _esbuild_ is not increasing the bundle size when it
      uses processed by TS compiler code. :exclamation: _nodeLinker_: _node_modules_ is used

  - Compiled TS code is imported from workspace with explicit imports of React in importing file only
    (packages/react-client-app/testCompiledImportsOnly.tsx). UI module needs
    to be built first before executing the script `yarn buildCompiledImports`. Size **546Kb**
  - Source code is imported with explicit imports of React in all workspaces. (packages/react-client-app/testSourceImportsOnly.tsx).
    Execute the script `yarn buildSourceImports`. Size **508Kb**
  - Source code in one package contains all the code, without workspaces
    imports (packages/react-client-app/testSourceBuild.tsx). Size **508Kb**.

  **Result**: Builds with imported source modules are lighter, than with imported compiled (TS compiler) modules.

- [x] Test if _esbuild_ is not increasing the bundle size when it
      uses processed by TS compiler code. :exclamation: _nodeLinker_: _pnp_ is used

  - Source code in one package contains all the code, without workspaces
    imports (packages/react-client-app/testSourceBuild.tsx). Size **510Kb**
    It turns out that _PnP_ modules ignore tsconfig alias settings and use package.json
    main directive to get the location of the module. So the size remains the same (**549Kb**), because only compiled (by TS)
    modules are used.

  **Result** Seems OK to sacrifice some disk space in order to follow _PnP_ approach.

- [x] Use _esbuild_ to bundle the _modules/_ workspace instead of TS.

  **Result** This is very inefficient, because TS only transforms the _.ts_ code into _.js_,
  leaving minimum imprint on the resulting codebase ("Button.tsx" with exports is around 1.5KB).
  When _esbuild_ adds a lot of polyfills for target environment, bloating the size
  of a resulting module (index.js is around 74Kb). When the bundled module is imported,
  it also increases the result application bundle to 584Kb

- [x] Try out _esbuild_ watch mode

  - Change code in the same workspace
  - Change code in the imported workspace
    All changes are detected correctly.

- [x] Try out _esbuild_ minification
      **Result** 584Kb minified to 74Kb

## TS-NODE

- [x] FIX: ts-node falls when running compiled code
      This happens because of compiled code that has lots of
      chunks, that violate typescript rules in the project.
      This can be fixed by switching off in the root _tsconfig_
      file type checking for ts-node: `transpileOnly: true`
