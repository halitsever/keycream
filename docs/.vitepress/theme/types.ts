export interface NavLink {
  text: string
  link: string
}

export interface SidebarGroup {
  text: string
  items: NavLink[]
}

export interface ThemeConfig {
  /** GitHub `owner/name`, used for release downloads and edit links. */
  repo: string
  nav: NavLink[]
  sidebar: SidebarGroup[]
  /** Shown instead of `sidebar` on /blog/ pages. */
  blogSidebar: SidebarGroup[]
}
