---
name: SVIL Baduk Vision
colors:
  surface: '#13131a'
  surface-dim: '#13131a'
  surface-bright: '#393840'
  surface-container-lowest: '#0d0e14'
  surface-container-low: '#1b1b22'
  surface-container: '#1f1f26'
  surface-container-high: '#292931'
  surface-container-highest: '#34343c'
  on-surface: '#e4e1eb'
  on-surface-variant: '#c0c7d0'
  inverse-surface: '#e4e1eb'
  inverse-on-surface: '#303037'
  outline: '#8a929a'
  outline-variant: '#40484f'
  surface-tint: '#8dcdff'
  primary: '#bee1ff'
  on-primary: '#00344f'
  primary-container: '#7ec8ff'
  on-primary-container: '#00537c'
  inverse-primary: '#006493'
  secondary: '#c6c6c8'
  on-secondary: '#2f3132'
  secondary-container: '#454749'
  on-secondary-container: '#b4b5b7'
  tertiary: '#e4e400'
  on-tertiary: '#323200'
  tertiary-container: '#c7c700'
  on-tertiary-container: '#515100'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#cae6ff'
  primary-fixed-dim: '#8dcdff'
  on-primary-fixed: '#001e30'
  on-primary-fixed-variant: '#004b70'
  secondary-fixed: '#e2e2e4'
  secondary-fixed-dim: '#c6c6c8'
  on-secondary-fixed: '#1a1c1d'
  on-secondary-fixed-variant: '#454749'
  tertiary-fixed: '#eaea00'
  tertiary-fixed-dim: '#cdcd00'
  on-tertiary-fixed: '#1d1d00'
  on-tertiary-fixed-variant: '#494900'
  background: '#13131a'
  on-background: '#e4e1eb'
  surface-variant: '#34343c'
typography:
  display-lg:
    fontFamily: KyoboHandwriting2019
    fontSize: 48px
    fontWeight: '400'
    lineHeight: '1.5'
  headline-md:
    fontFamily: KyoboHandwriting2019
    fontSize: 32px
    fontWeight: '400'
    lineHeight: '1.6'
  body-lg:
    fontFamily: KyoboHandwriting2019
    fontSize: 24px
    fontWeight: '400'
    lineHeight: '1.8'
  body-md:
    fontFamily: KyoboHandwriting2019
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.8'
  data-mono:
    fontFamily: Consolas
    fontSize: 20px
    fontWeight: '400'
    lineHeight: '1.2'
  label-sm:
    fontFamily: Consolas
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.2'
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  touch-target-min: 50px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 40px
  max-width: 1280px
---

## Brand & Style
The design system is engineered for **SVIL Baduk**, a specialized interface for low-vision users engaging with the game of Go (Baduk). The brand personality is functional, authoritative, and uncompromisingly clear. It prioritizes utility over decoration, ensuring that the strategic complexity of the game remains accessible through high-contrast visual cues.

The design style is **High-Contrast Digital Brutalism**. It rejects soft gradients, blurs, and subtle shadows in favor of hard edges, massive hit targets, and distinct tonal separation. The aesthetic is "dark-mode first," utilizing a deep charcoal palette to minimize eye strain and light scatter, while using a vivid yellow focus system to provide absolute certainty during navigation.

## Colors
This design system utilizes a specialized palette designed for maximum legibility. The background is nearly black to isolate white and light-blue elements effectively. 

- **Primary Interaction**: The #7EC8FF accent provides a "cool" focal point that contrasts against the warm yellow focus ring.
- **State Feedback**: Positive, Warning, and Negative colors are highly saturated to ensure they are perceivable even with reduced color sensitivity.
- **Focus States**: A mandatory 3px solid #FFFF00 ring is required for all keyboard and remote-controlled focus states. This is the most critical color in the system for navigation.

## Typography
Typography in this design system is driven by readability. The primary typeface, **KyoboHandwriting2019**, offers a distinct, high-character shape that aids in letter recognition. **Consolas** is reserved for coordinates (e.g., K10, D4) and numerical data to ensure zero ambiguity between characters like '0' and 'O' or '1' and 'I'.

**Key Constraints:**
- **No Fake Bold**: Avoid browser-generated bolding. Visual emphasis must be achieved through size or color contrast.
- **Scaling**: Minimum body size is 18px. For mobile, headline sizes should be maintained as much as possible to ensure clarity.
- **Line Height**: Fixed at 1.8 for body text to prevent "line crowding," which can be difficult for low-vision users to parse.

## Layout & Spacing
The layout follows a **Fixed-Fluid Hybrid** model. While optimized for a 1280x900 viewport, the system must remain functional down to mobile widths. 

- **Grid**: A 12-column grid is used for desktop layouts, while a single-column stack is preferred for mobile.
- **Touch Targets**: Every interactive element must have a minimum physical size of 50px x 50px. 
- **Safe Zones**: Large margins (40px on desktop) are used to prevent content from touching the screen edges, which helps users with peripheral vision loss focus on the central content.
- **Spacing Rhythm**: All gaps between elements should be multiples of 8px.

## Elevation & Depth
Elevation is expressed through **Tonal Layering** rather than shadows. 
- **Level 0 (Background)**: #0D0D12 - The base for the entire application.
- **Level 1 (Surface)**: #16161D - Used for the main game board and secondary containers.
- **Level 2 (Surface-2)**: #1F1F2A - Used for active overlays, modals, and card elements.

Visual depth is reinforced by **3px Border-Strong (#6B6B82)** for interactive components. Do not use blurs, shadows, or transparency; every layer must be opaque to maintain maximum contrast ratios.

## Shapes
The design system uses a **Rounded** shape language to provide a soft container for the inherently rigid square grid of the Baduk board. 

- **Base Radius**: 12px (0.5rem - 0.75rem range) for all buttons and input fields.
- **Stone Geometry**: Game stones must remain perfect circles.
- **Interactive States**: The yellow focus ring must follow the roundedness of the parent element, creating a 3px "halo" around the 12px corners.

## Components

### Buttons
- **Primary**: White (#F5F5F7) background with Black (#0D0D12) text. No border.
- **Secondary**: Black (#0D0D12) background, White (#F5F5F7) text, and a 3px border (#C9C9D4).
- **Danger**: Black (#0D0D12) background with Red (#FF9B9B) text and a 3px #FF9B9B border.
- **Requirement**: Buttons must always include a text label. Iconic buttons must have a clear text label underneath or beside the icon.

### Input Fields
- **Container**: Surface-2 (#1F1F2A) background with a 3px border-strong (#6B6B82).
- **Text**: White (#F5F5F7) body-lg size.
- **Active State**: 3px Yellow (#FFFF00) border when focused.

### The Baduk Board
- **Lines**: Border-strong (#6B6B82) at 2px thickness.
- **Stones**: High-contrast white and black. Black stones should have a thin white outline (#3A3A48) to distinguish them from the dark board background.
- **Coordinates**: Consolas font, positioned outside the board grid with high-contrast text-sub (#C9C9D4).

### List Items & Navigation
- Items should be separated by clear 8px gaps rather than just lines.
- Each list item must have a minimum height of 60px to ensure a comfortable touch target.