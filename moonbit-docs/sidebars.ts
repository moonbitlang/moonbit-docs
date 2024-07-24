import type { SidebarsConfig } from '@docusaurus/plugin-content-docs'

/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */
const sidebars: SidebarsConfig = {
  // By default, Docusaurus generates a sidebar from the docs folder structure
  docs: [
    {
      type: 'doc',
      id: 'syntax',
      label: 'MoonBit'
    },
    'build-system-tutorial',
    'ffi-and-wasm-host',
    'package-manage-tour',
    'build-system-configuration',
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
