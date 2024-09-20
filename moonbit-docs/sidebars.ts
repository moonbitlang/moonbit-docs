import type { SidebarsConfig } from '@docusaurus/plugin-content-docs'

const isZh = process.env.DOCUSAURUS_CURRENT_LOCALE === 'zh'

const sidebars: SidebarsConfig = {
  // By default, Docusaurus generates a sidebar from the docs folder structure
  docs: [
    {
      type: 'doc',
      id: 'README',
      label: 'MoonBit'
    },
    {
      type: 'link',
      label: isZh ? 'MoonBit 构建系统教程' : `MoonBit's Build System Tutorial`,
      href: isZh
        ? 'https://moonbitlang.github.io/moon/zh/'
        : 'https://moonbitlang.github.io/moon/'
    },
    'ffi-and-wasm-host',
    'package-manage-tour',
    'tour',
    'error-handling',
    {
      type: 'category',
      label: 'Examples',
      collapsed: true,
      link: {
        type: 'generated-index'
      },
      items: isZh
        ? [
            'examples/sudoku/index',
            'examples/lambda',
            'examples/gmachine-1/index',
            'examples/gmachine-2',
            'examples/gmachine-3',
            'examples/myers-diff',
            'examples/myers-diff2',
            'examples/myers-diff3',
            'examples/pingpong/index',
            'examples/segment-tree/index'
          ]
        : [
            'examples/sudoku/index',
            'examples/lambda',
            'examples/gmachine-1/index',
            'examples/gmachine-2',
            'examples/gmachine-3',
            'examples/myers-diff',
            'examples/myers-diff2',
            'examples/myers-diff3'
          ]
    }
  ]
}

export default sidebars
