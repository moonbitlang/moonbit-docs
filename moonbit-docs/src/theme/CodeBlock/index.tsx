import React from 'react'
import CopyButton from '@theme/CodeBlock/CopyButton'
import codeBlockStyles from './CodeBlock.module.css'
import clsx from 'clsx'
import Moonpad from '@site/src/components/Moonpad'
import useTheme from '@site/src/components/Moonpad/useTheme'
import CodeBlockType from '@theme/CodeBlock'
import { WrapperProps } from '@docusaurus/types'

function getTextForCopy(node: React.ReactNode): string {
  if (node === null) return ''

  switch (typeof node) {
    case 'string':
    case 'number':
      return node.toString()
    case 'object':
      if (node instanceof Array) return node.map(getTextForCopy).join('')
      if ('props' in node) return getTextForCopy(node.props.children)
    default:
      return ''
  }
}

type Props = WrapperProps<typeof CodeBlockType> & { live: boolean }

function CodeBlock(props: Props): JSX.Element {
  const codeRef = React.useRef<HTMLElement>(null)
  const code = getTextForCopy(props.children)

  return (
    <div className={codeBlockStyles.CodeBlock}>
      <pre className={clsx(codeBlockStyles.pre, 'shiki')}>
        <code {...props} ref={codeRef} />
      </pre>
      <CopyButton className={codeBlockStyles.button} code={code} />
    </div>
  )
}

export default function CodeBlockWrapper(props: Props): JSX.Element {
  const code = getTextForCopy(props.children)
  const theme = useTheme()
  if (props.live) {
    return <Moonpad code={code} theme={theme} />
  }
  return (
    <>
      <CodeBlock {...props} />
    </>
  )
}
