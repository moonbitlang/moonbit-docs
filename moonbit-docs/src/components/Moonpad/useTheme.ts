import { useEffect, useState } from 'react'

type ThemeState = 'light' | 'dark'

export default function useTheme(): ThemeState {
  const [theme, setTheme] = useState<ThemeState>('light')

  useEffect(() => {
    const callback: MutationCallback = (mutationList) => {
      for (const mutation of mutationList) {
        switch (mutation.type) {
          case 'attributes':
            switch (mutation.attributeName) {
              case 'data-theme':
                // console.log((mutation.target as HTMLHtmlElement).dataset.theme as ThemeState)
                setTheme(
                  (mutation.target as HTMLHtmlElement).dataset
                    .theme as ThemeState
                )
                break
            }
            break
        }
      }
    }
    const observer = new MutationObserver(callback)
    observer.observe(document.documentElement, {
      attributeFilter: ['data-theme']
    })
    return () => observer.disconnect()
  }, [])
  return theme
}
