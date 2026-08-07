# UniFed Nigeria — UI/UX Design System

**Goal:** one unified, premium, mobile-first experience across 5 tabs (Home, Connect, Create, Discover,
Profile). Inspired by the usability of WhatsApp, Discord, Notion, LinkedIn, Instagram — with a distinct
UniFed identity.

## 1. Principles
- **Mobile-first**, responsive, fast (<2s interactive on 4G).
- **One platform feel**: shared shell, nav, tokens, motion.
- **Accessible** (WCAG 2.1 AA), **dark + light** mode.
- **Consistent** tokens; no one-off styles.
- **Smooth** micro-interactions; restrained, purposeful animation.

## 2. Design Tokens
```
Color (brand)
  --uf-primary:    #1B3A6B   (deep academic blue)
  --uf-accent:     #F5A623   (optimistic amber — energy/creator)
  --uf-trust:      #0FA37F   (verified green — identity/credentials)
  --uf-surface:    #FFFFFF / #0E1116 (light/dark)
  --uf-muted:      #6B7280
  --uf-danger:     #E5484D   (SOS/emergency)
Typography
  --uf-font:       "Inter", system-ui        (UI)
  --uf-mono:       "JetBrains Mono"          (code/IDs)
  Scale: 12 / 14 / 16 / 20 / 24 / 32 / 40 (4px baseline grid)
Spacing: 4 / 8 / 12 / 16 / 24 / 32 / 48
Radius: sm 8 · md 12 · lg 20 · pill 999
Shadow: --uf-elev-1..3 (soft, low-opacity)
Motion: 150ms ease-out transitions; 250ms sheet/modal; respect prefers-reduced-motion
```

## 3. Layout
- **App shell:** bottom tab bar (5 tabs) on mobile; left rail + content on desktop.
- **Top bar:** instance badge (ADUN), search affordance, profile/avatar, SOS.
- **Content:** card-based feeds; full-bleed media for stories/live.
- **Sheets:** bottom sheets for Create/Detail on mobile; modal/side-panel on desktop.

## 4. Components (core kit)
- **UniFedTabBar** — 5 tabs, active pill indicator.
- **UniFedCard** — feed/post/result card.
- **UniFedAvatar** — initials + ring (verified = green ring).
- **UniFedIDCard** — digital student ID visual (QR, verified badge, chain anchor).
- **UniFedFeed** — infinite scroll, skeleton loaders.
- **UniFedComposer** — Create (+) sheet with AI assist.
- **UniFedChat** — message bubbles, typing, read receipts.
- **UniFedLive** — video surface + live chat/poll/Q&A.
- **UniFedBadge** — status (In Lecture / Studying / …), verified, emergency.
- **UniFedMap** — campus map with navigation + QR wayfinding.

## 5. Navigation model (5 tabs)
| Tab | Primary | Key screens |
|---|---|---|
| Home | Personalised feed + academic widgets | announcements, today's classes, deadlines, recommendations |
| Connect | Comms + collab hub | chat, calls, whiteboard, calendar, UniFed Live, emergency |
| Create | Authoring | post, story, livestream, event, community, marketplace, poll (+ AI) |
| Discover | Universal search | universities→buildings, semantic AI search |
| Profile | Identity + records + tools | digital ID, academic records, assignments, creator, marketplace, settings |

## 6. State & Feedback
- Skeletons + optimistic updates for posts/messages.
- Inline validation; non-blocking toasts.
- Clear empty/error/permission states per screen.

## 7. Accessibility
- Semantic roles, focus rings, 44px targets, contrast AA.
- Dark/light auto + manual; scalable type.
- Status not conveyed by color alone (icons + text).

## 8. Motion & Identity
- Subtle entrance for sheets; snap for tabs.
- Brand: calm authority (blue) + human warmth (amber) + trust (green).
- Avoid gimmicks; motion communicates state, not decoration.

## 9. Implementation notes
- Next.js + Tailwind with CSS variables for tokens; `design/tokens.ts` already seeds the palette.
- Component library co-located under `frontend/src/components`; follow the existing `UniFedLayout`/
  `BottomNav` pattern extended to all 5 tabs.
- Figma library mirrors these tokens (to be produced by design).
