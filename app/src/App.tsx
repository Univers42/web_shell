import { CloudTerminal } from './lib/libcss/components/cloud-terminal';
import { ANIM_PRESET_SMOOTH } from './lib/libcss/components/cloud-terminal/animations';

/**
 * App — A single full-screen CloudTerminal built entirely from libcss.
 *
 * This replaces the original cloud-terminal/src/App.tsx
 * with a single composable component invocation.
 * All UI (nav rail, header, chrome, viewport, editor, docs, status bar,
 * split panes, theme switcher, animations) is handled internally.
 */
export default function App() {
  return (
    <CloudTerminal
      title="INFERNO"
      colorScheme="dark"
      themeId="inferno"
      showNavRail
      sidebarCollapsible
      showHeader
      showStatusBar
      showEffects
      showThemeSwitcher
      enableEditor
      enableDocs
      enableSplit
      enableTabDragDrop
      showTabs
      cursorBlink
      fontSize={13}
      animationPreset={ANIM_PRESET_SMOOTH}
    />
  );
}
