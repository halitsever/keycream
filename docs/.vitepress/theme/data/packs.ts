export type SwitchFeel = 'Linear' | 'Tactile' | 'Clicky'

export interface Pack {
  /** Folder name in Resources/SoundPacks, also the sample file name. */
  id: string
  name: string
  feel: SwitchFeel
  summary: string
}

/** Names match the app's Sound Pack menu. The default comes first, then linear to clicky. */
export const packs: Pack[] = [
  { id: 'NovelKeys-cream', name: 'NovelKeys Cream', feel: 'Linear', summary: 'Smooth and deep. The pack KeyCream starts with.' },
  { id: 'CherryMX-black-pbt', name: 'Cherry MX Black', feel: 'Linear', summary: 'A heavy linear with a firm bottom-out.' },
  { id: 'CherryMX-red-pbt', name: 'Cherry MX Red', feel: 'Linear', summary: 'A light linear, quick and even.' },
  { id: 'CherryMX-brown-pbt', name: 'Cherry MX Brown', feel: 'Tactile', summary: 'A gentle bump, quieter than a clicky switch.' },
  { id: 'CherryMX-blue-pbt', name: 'Cherry MX Blue', feel: 'Clicky', summary: 'The classic sharp click on every press.' },
  { id: 'Everglide-crystal-purple', name: 'Everglide Crystal Purple', feel: 'Tactile', summary: 'A pronounced bump with a crisp return.' },
  { id: 'Everglide-oreo', name: 'Everglide Oreo', feel: 'Tactile', summary: 'A rounded bump with a muted sound.' },
]
