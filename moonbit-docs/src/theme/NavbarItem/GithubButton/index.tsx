import clsx from 'clsx'
import styles from './index.module.css'
import { useEffect, useState } from 'react'
import { translate } from '@docusaurus/Translate'
import useDocusaurusContext from '@docusaurus/useDocusaurusContext'
import { getGithubStars } from '@site/lib/utils'

function GithubIcon() {
  return (
    <svg
      width='24px'
      height='24px'
      viewBox='0 0 32 32'
      fill='none'
      xmlns='http://www.w3.org/2000/svg'
    >
      <path
        fillRule='evenodd'
        clipRule='evenodd'
        d='M16 0C7.16 0 0 7.3411 0 16.4047C0 23.6638 4.58 29.795 10.94 31.9687C11.74 32.1122 12.04 31.6201 12.04 31.1894C12.04 30.7998 12.02 29.508 12.02 28.1341C8 28.8928 6.96 27.1293 6.64 26.2065C6.46 25.7349 5.68 24.279 5 23.8893C4.44 23.5818 3.64 22.823 4.98 22.8025C6.24 22.782 7.14 23.9919 7.44 24.484C8.88 26.9652 11.18 26.268 12.1 25.8374C12.24 24.7711 12.66 24.0534 13.12 23.6433C9.56 23.2332 5.84 21.8183 5.84 15.5435C5.84 13.7594 6.46 12.283 7.48 11.1347C7.32 10.7246 6.76 9.04309 7.64 6.78745C7.64 6.78745 8.98 6.35682 12.04 8.46893C13.32 8.09982 14.68 7.91527 16.04 7.91527C17.4 7.91527 18.76 8.09982 20.04 8.46893C23.1 6.33632 24.44 6.78745 24.44 6.78745C25.32 9.04309 24.76 10.7246 24.6 11.1347C25.62 12.283 26.24 13.7389 26.24 15.5435C26.24 21.8388 22.5 23.2332 18.94 23.6433C19.52 24.1559 20.02 25.1402 20.02 26.6781C20.02 28.8723 20 30.6358 20 31.1894C20 31.6201 20.3 32.1327 21.1 31.9687C27.42 29.795 32 23.6433 32 16.4047C32 7.3411 24.84 0 16 0Z'
        fill='currentColor'
      ></path>
    </svg>
  )
}

export default function GithubButton() {
  const githubStars = useDocusaurusContext().siteConfig.customFields
    ?.githubStars as string
  const [stars, setStars] = useState(githubStars)

  useEffect(() => {
    const getStarsCount = async () => {
      const stars = await getGithubStars()
      if (stars) {
        setStars(stars)
      }
    }
    getStarsCount()
  }, [])

  return (
    <div className='navbar__item'>
      <a
        href='https://github.com/moonbitlang/moonbit-docs'
        target='_blank'
        className={clsx('navbar__link', styles.wrapper)}
      >
        <GithubIcon />
        <div>
          {translate({
            id: 'theme.NavbarItem.GithubButton.starUs',
            message: 'Star us'
          })}
        </div>
        {stars !== '-1' && (
          <>
            <div>⭐️ {stars}</div>
          </>
        )}
      </a>
    </div>
  )
}
