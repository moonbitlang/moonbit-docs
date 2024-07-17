import React, { useId, useRef, useState } from 'react'
import BrowserOnly from '@docusaurus/BrowserOnly'
import type { Moonpad as MoonpadWc } from '@moonbit/moonpad'
import styles from './styles.module.css'

declare module 'react' {
  namespace JSX {
    interface IntrinsicElements {
      'moonpad-wc': React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement>,
        HTMLElement
      >
    }
  }
}

interface MoonpadProps {
  code: string | undefined
  theme: 'light' | 'dark'
}

export default function Moonpad({ code, theme }: MoonpadProps): JSX.Element {
  const id = useId()
  const code_ = code ?? ''
  const moonpadRef = useRef<MoonpadWc>(null)
  const [output, setOutput] = useState('')

  return (
    <BrowserOnly
      fallback={
        <pre>
          <code>{code_}</code>
        </pre>
      }
    >
      {() => {
        const MoonpadWc = require('@moonbit/moonpad').Moonpad
        if (customElements.get('moonpad-wc') === undefined) {
          customElements.define('moonpad-wc', MoonpadWc)
        }
        return (
          <div className={styles['wrapper']}>
            <div className={styles['buttons-wrapper']}>
              <button
                className='button button--secondary'
                onClick={async (e) => {
                  e.preventDefault()
                  try {
                    const output = await moonpadRef.current?.run()
                    setOutput(output ?? '')
                  } catch {
                    setOutput('Compile error')
                  }
                }}
              >
                Run
              </button>
              <button
                className='button button--secondary'
                onClick={(e) => {
                  e.preventDefault()
                  moonpadRef.current?.reset()
                }}
              >
                Reset
              </button>
              <button
                className='button button--secondary'
                onClick={(e) => {
                  e.preventDefault()
                  moonpadRef.current?.format()
                }}
              >
                Format
              </button>
            </div>

            <moonpad-wc
              ref={moonpadRef}
              data-theme={theme}
              data-key={id}
              data-content={code}
            >
              <link rel='stylesheet' href='/styles/moonpad.css' />
            </moonpad-wc>

            <div>
              <div style={{ marginTop: '1em' }}>Output</div>
              <div style={{ whiteSpace: 'pre-wrap' }}>{output}</div>
            </div>
          </div>
        )
      }}
    </BrowserOnly>
  )
}
