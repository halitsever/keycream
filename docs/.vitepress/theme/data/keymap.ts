import fileForScanCode from '../../../public/keys/map.json'

/** Browser key codes to the PC scan codes that Mechvibes packs are keyed by. */
export const scanCodes: Record<string, string> = {
  Escape: '1', Backquote: '41', Minus: '12', Equal: '13', Backspace: '14', Tab: '15',
  BracketLeft: '26', BracketRight: '27', Backslash: '43', CapsLock: '58', Semicolon: '39', Quote: '40', Enter: '28',
  ShiftLeft: '42', Comma: '51', Period: '52', Slash: '53', ShiftRight: '54',
  ControlLeft: '29', AltLeft: '56', MetaLeft: '3675', Space: '57', MetaRight: '3676', AltRight: '3640', ControlRight: '3613',
  ArrowUp: '57416', ArrowLeft: '57419', ArrowRight: '57421', ArrowDown: '57424',
  F1: '59', F2: '60', F3: '61', F4: '62', F5: '63', F6: '64', F7: '65', F8: '66', F9: '67', F10: '68', F11: '87', F12: '88',
  // Browsers never see fn, so only the on-screen key sends it. The app plays it like left Control.
  Fn: '29',
}
;[...'1234567890'].forEach((d, i) => (scanCodes[`Digit${d}`] = String(i + 2)))
const letterRows: [string, number][] = [['QWERTYUIOP', 16], ['ASDFGHJKL', 30], ['ZXCVBNM', 44]]
for (const [row, first] of letterRows) [...row].forEach((c, i) => (scanCodes[`Key${c}`] = String(first + i)))

/** Mirrors Sources/KeyCream/KeyCodeMap.swift: macOS virtual key code to scan code. */
const macToScan: Record<number, string> = {
  0: '30', 1: '31', 2: '32', 3: '33', 4: '35', 5: '34', 6: '44', 7: '45', 8: '46', 9: '47', 11: '48', 12: '16',
  13: '17', 14: '18', 15: '19', 16: '21', 17: '20', 18: '2', 19: '3', 20: '4', 21: '5', 22: '7', 23: '6', 24: '13',
  25: '10', 26: '8', 27: '12', 28: '9', 29: '11', 30: '27', 31: '24', 32: '22', 33: '26', 34: '23', 35: '25', 36: '28',
  37: '38', 38: '36', 39: '40', 40: '37', 41: '39', 42: '43', 43: '51', 44: '53', 45: '49', 46: '50', 47: '52', 48: '15',
  49: '57', 50: '41', 51: '14', 53: '1', 54: '3676', 55: '3675', 56: '42', 57: '58', 58: '56', 59: '29', 60: '54',
  61: '3640', 62: '3613', 96: '63', 97: '64', 98: '65', 99: '61', 100: '66', 101: '67', 103: '87', 109: '68',
  111: '88', 118: '62', 120: '60', 122: '59', 123: '57419', 124: '57421', 125: '57424', 126: '57416', 63: '29',
}

const scanToMac = new Map<string, number>()
for (const [mac, scan] of Object.entries(macToScan)) {
  if (!scanToMac.has(scan)) scanToMac.set(scan, Number(mac))
}

export interface KeyTrace {
  label: string
  macKeyCode: number | null
  scanCode: string
  file: string | null
}

/** What the app would see and play for a browser key code, or null for keys it ignores. */
export function traceKey(code: string, label: string): KeyTrace | null {
  const scanCode = scanCodes[code]
  if (!scanCode) return null
  // Fn shares its scan code with left Control, so its own key code is looked up directly.
  const macKeyCode = code === 'Fn' ? 63 : (scanToMac.get(scanCode) ?? null)
  return { label, macKeyCode, scanCode, file: (fileForScanCode as Record<string, string>)[scanCode] ?? null }
}

export { fileForScanCode }
