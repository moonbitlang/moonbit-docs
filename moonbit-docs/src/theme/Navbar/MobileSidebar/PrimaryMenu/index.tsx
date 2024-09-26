import React from 'react'
import { useThemeConfig } from '@docusaurus/theme-common'
import { useNavbarMobileSidebar } from '@docusaurus/theme-common/internal'
import NavbarItem, { type Props as NavbarItemConfig } from '@theme/NavbarItem'
import useDocusaurusContext from '@docusaurus/useDocusaurusContext'

function useNavbarItems() {
  // TODO temporary casting until ThemeConfig type is improved
  const {
    i18n: { currentLocale }
  } = useDocusaurusContext()
  // TODO temporary casting until ThemeConfig type is improved
  const items = useThemeConfig().navbar.items.filter((item) =>
    (item.locale as string[]).includes(currentLocale)
  )
  return items as NavbarItemConfig[]
}

// The primary menu displays the navbar items
export default function NavbarMobilePrimaryMenu(): JSX.Element {
  const mobileSidebar = useNavbarMobileSidebar()

  // TODO how can the order be defined for mobile?
  // Should we allow providing a different list of items?
  const items = useNavbarItems()

  return (
    <ul className='menu__list'>
      {items.map((item, i) => (
        <NavbarItem
          mobile
          {...item}
          onClick={() => mobileSidebar.toggle()}
          key={i}
        />
      ))}
    </ul>
  )
}
