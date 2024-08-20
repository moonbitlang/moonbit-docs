import type { SidebarsConfig } from '@docusaurus/plugin-content-docs'

const sidebars: SidebarsConfig = {
  // By default, Docusaurus generates a sidebar from the docs folder structure
  docs: [
    {
      type: 'doc',
      id: 'README',
      label: 'MoonBit'
    },
    'build-system-tutorial',
    'ffi-and-wasm-host',
    'package-manage-tour',
    'build-system-configuration',
    'tour',
    'error-handling',
    {
      type: 'category',
      label: 'Examples',
      collapsed: true,
      link: {
        type: 'generated-index'
      },
      items: [
        'examples/sudoku/index',
        'examples/lambda',
        'examples/gmachine-1/index',
        'examples/gmachine-2',
        'examples/gmachine-3',
        'examples/myers-diff',
        'examples/myers-diff2'
      ]
    }
  ]
}

export default sidebars
