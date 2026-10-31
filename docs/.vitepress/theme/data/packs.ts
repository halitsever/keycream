export type SwitchFeel = 'Linear' | 'Tactile' | 'Clicky'

export interface Pack {
  /** Folder name in Resources/SoundPacks, also the sample file name. */
  id: string
  name: string
  feel: SwitchFeel
  summary: string
  /** Colors for the top-down switch drawing. */
  housing: string
  stem: string
  /** Crystal housings let the plate show through. */
  clear?: boolean
}

/** Names match the app's Sound Pack menu. The default comes first, then linear to clicky. */
export const packs: Pack[] = [
  { id: 'NovelKeys-cream', name: 'NovelKeys Cream', feel: 'Linear', summary: 'Smooth and deep. The pack KeyCream starts with.', housing: '#e6d8ba', stem: '#f6ecd6' },
  { id: 'CherryMX-black-pbt', name: 'Cherry MX Black', feel: 'Linear', summary: 'A heavy linear with a firm bottom-out.', housing: '#2b2a2c', stem: '#141315' },
  { id: 'CherryMX-red-pbt', name: 'Cherry MX Red', feel: 'Linear', summary: 'A light linear, quick and even.', housing: '#2b2a2c', stem: '#d8352d' },
  { id: 'CherryMX-brown-pbt', name: 'Cherry MX Brown', feel: 'Tactile', summary: 'A gentle bump, quieter than a clicky switch.', housing: '#2b2a2c', stem: '#8b5632' },
  { id: 'CherryMX-blue-pbt', name: 'Cherry MX Blue', feel: 'Clicky', summary: 'The classic sharp click on every press.', housing: '#2b2a2c', stem: '#2f6fe0' },
  { id: 'Everglide-crystal-purple', name: 'Everglide Crystal Purple', feel: 'Tactile', summary: 'A pronounced bump with a crisp return.', housing: '#b7a2ea', stem: '#7a4bd8', clear: true },
  { id: 'Everglide-oreo', name: 'Everglide Oreo', feel: 'Tactile', summary: 'A rounded bump with a muted sound.', housing: '#1b1a1c', stem: '#f1efea' },
]

export const languages = [
  'English', 'Türkçe', 'Deutsch', 'Français', 'Español', 'Português',
  'Русский', '日本語', '한국어', '简体中文', 'العربية', 'हिन्दी',
]
