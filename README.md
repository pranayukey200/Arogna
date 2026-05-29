<div align="center">

<br/>

```
█████╗ ██████╗  ██████╗  ██████╗ ███╗   ██╗ █████╗
██╔══██╗██╔══██╗██╔═══██╗██╔════╝ ████╗  ██║██╔══██╗
███████║██████╔╝██║   ██║██║  ███╗██╔██╗ ██║███████║
██╔══██║██╔══██╗██║   ██║██║   ██║██║╚██╗██║██╔══██║
██║  ██║██║  ██║╚██████╔╝╚██████╔╝██║ ╚████║██║  ██║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝
```

### **Rapid Crisis Response Platform**
<p align="center">
  <a href="http://arognareadmepage.vercel.app/">
    <img src="https://img.shields.io/badge/Arogna_Readme_Page-Click_Here_To_View-B71C1C?style=for-the-badge&logo=google-chrome&logoColor=white" alt="Arogna Readme Page" />
  </a>
 
</p>
<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20RTDB%20%7C%20Auth%20%7C%20Storage-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini AI](https://img.shields.io/badge/Gemini%201.5%20Flash-AI%20Triage%20Engine-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev)
[![Google Maps](https://img.shields.io/badge/Google%20Maps-Live%20GIS%20Layer-34A853?style=for-the-badge&logo=google-maps&logoColor=white)](https://developers.google.com/maps)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://android.com)
[![License](https://img.shields.io/badge/License-MIT-B71C1C?style=for-the-badge)](LICENSE)

<br/>

> *"When every second counts, Arogna connects citizens, dispatchers, paramedics, and hospitals in one real-time reactive loop — replacing phone tag with intelligent automation."*

<br/>

---

</div>

## 📋 Table of Contents

- [The Problem We're Solving](#-the-problem-were-solving)
- [What is Arogna?](#-what-is-arogna)
- [How It Works — Core Flow](#-how-it-works--core-flow)
- [Feature Overview by Dashboard](#-feature-overview-by-dashboard)
  - [Citizen Dashboard](#-dashboard-1--citizen-app)
  - [Admin Command Center](#-dashboard-2--admin-command-center)
  - [Responder Navigator](#-dashboard-3--paramedic-responder)
  - [Hospital Resource Manager](#-dashboard-4--hospital-resource-manager)
- [System Architecture](#-system-architecture)
- [Database Schema](#-database-schema)
- [AI & Gemini Integration](#-ai--gemini-integration)
- [Real-Time Sync Pipeline](#-real-time-sync-pipeline)
- [Algorithms & Technical Depth](#-algorithms--technical-depth)
- [Technology Stack](#-technology-stack)
- [Screens & UI Catalogue](#-screens--ui-catalogue)
- [Why Arogna Wins — USPs](#-why-arogna-wins--usps)
- [Competitive Analysis](#-competitive-analysis)
- [UN SDG Alignment](#-un-sdg-alignment)
- [Installation & Setup](#-installation--setup)
- [Team](#-team)

---

## 🚨 The Problem We're Solving

Every year in India, **1.5 million people die** from road accidents, cardiac events, and preventable emergencies. The majority of those deaths occur not from the emergency itself — but from **the gap between incident and intervention**.

The traditional emergency response pipeline looks like this:

```
[Incident Occurs]
      │
      ▼
[Manual Phone Call to 108/112]          ← 2–4 minutes lost
      │
      ▼
[Dispatcher asks: "Where are you? What happened?"]  ← No data, no context
      │
      ▼
[Dispatcher guesses nearest ambulance by memory]    ← No live tracking
      │
      ▼
[Ambulance drives without traffic routing data]     ← No dynamic routing
      │
      ▼
[Arrives at hospital — ICU is full]                 ← No bed visibility
      │
      ▼
[Secondary transfer. Patient deteriorates.]         ← The Golden Hour is gone.
```

**Every step in this chain has a failure mode.** Arogna eliminates them all.

### Root Causes of Emergency System Failure

| Failure Point | Root Cause | Impact |
|---|---|---|
| Delayed dispatch | No automated victim detection | +3–5 min response time |
| Wrong ambulance sent | No live location tracking | Suboptimal routing |
| No victim medical data | Siloed health records | Drug conflicts, wrong treatment |
| Hospital rerouting | No real-time bed inventory | Secondary transfers under load |
| Unverified crowd reports | No spatial validation engine | Noise overwhelms signal |
| No community accountability | No incentive for civic reporting | Underreported hazards |

---

## 💡 What is Arogna?

**Arogna** is a cross-role emergency response Android application that binds **citizens, administrators, paramedic responders, and hospitals** inside a single synchronised real-time data loop.

It replaces fragmented, phone-based emergency coordination with:

- **AI-powered triage** (Gemini 1.5 Flash classifies RED / YELLOW / GREEN in under 5 seconds)
- **Live GIS tracking** (ambulances, hospitals, SOS events on a single shared map)
- **Automated SOS capture** (camera, audio, GPS triggered in one 4-second hold)
- **Community-validated danger zones** (spatial clustering of crowdsourced reports)
- **Gamified civic reporting** (points, badges, leaderboard to incentivise participation)
- **Real-time hospital bed inventory** visible to dispatchers and responders

The app name **Arogna** is derived from *Aarogya* (Sanskrit: आरोग्य), meaning **health, freedom from disease, well-being** — the core promise of the platform.

---

## 🔄 How It Works — Core Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AROGNA EMERGENCY LIFECYCLE                          │
└─────────────────────────────────────────────────────────────────────────────┘

  CITIZEN                  ADMIN                   RESPONDER              HOSPITAL
     │                        │                        │                      │
     │ [Hold SOS 4s]           │                        │                      │
     │ ─────────────────────► │                        │                      │
     │                        │                        │                      │
     │ Gemini classifies       │                        │                      │
     │ RED / YELLOW / GREEN    │                        │                      │
     │                        │                        │                      │
     │ Photos + Audio + GPS    │                        │                      │
     │ uploaded to Storage     │                        │                      │
     │                        │                        │                      │
     │ Firestore SOS Event     │                        │                      │
     │ written → "active"      │ ◄── StreamBuilder      │                      │
     │                        │     wakes instantly     │                      │
     │                        │                        │                      │
     │                        │ Admin reviews triage    │                      │
     │                        │ Dispatches nearest      │                      │
     │                        │ online responder        │                      │
     │                        │ ──────────────────────► │                      │
     │                        │                        │ FCM push arrives      │
     │                        │                        │ Dispatch shown        │
     │                        │                        │                      │
     │ ◄─────────────────────────────────────────────── │                      │
     │ "Help is on the way"    │                        │ Navigate to victim   │
     │ Responder marker on map │                        │ via Google Maps      │
     │                        │                        │                      │
     │                        │                        │ Books bed at nearest │
     │                        │                        │ hospital in-app      │
     │                        │                        │ ───────────────────► │
     │                        │                        │                      │ Confirm
     │                        │                        │ Status: Transporting │ incoming
     │                        │                        │ ───────────────────► │ patient
     │                        │                        │                      │
     │ Status updates live     │ Mission board clears   │ Mission resolved     │ Bed updated
     └────────────────────────┴────────────────────────┴──────────────────────┴─────────────
```

---

## 📱 Feature Overview by Dashboard

### 🟥 Dashboard 1 — Citizen App

The citizen experience is designed for **zero-friction emergency access** — the most critical action (SOS) takes 4 seconds and works even for guest users.

#### Authentication & Onboarding

```
┌─────────────────────────────────────────────────────────┐
│  AROGNA LOGIN SCREEN                                     │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │  ✚  AROGNA                                      │    │  ← Red header, white logo
│  │     Emergency Response Platform                  │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  Welcome Back                                           │
│  ────────────────────────────────────────────────────   │
│  [ Email Address                               ]        │
│  [ Password                                  👁 ]       │
│                                                         │
│  [           LOGIN           ]  ← Deep Red #B71C1C      │
│  ─────────────── or ────────────────                    │
│  [         CREATE ACCOUNT    ]  ← Outlined              │
│  [       Continue as Guest   ]  ← Grey text button      │
└─────────────────────────────────────────────────────────┘
```

**Registration Form — What We Collect (And Why)**

| Section | Fields | Purpose |
|---|---|---|
| Account | Email, Password, Confirm | Firebase Auth identity |
| Personal | Full name, Father's name, Phone, Address, DOB | Identity verification |
| Emergency Contacts | 2× Name + Phone | Auto-SMS during SOS |
| Identity | ID Type + Photo upload | Civic accountability |
| Medical History | Blood group, Conditions (chips), Medications, Allergies, Medical photo | Pre-arrival patient data for responders |

> The medical profile is the single most critical data asset in Arogna. When a responder is dispatched, they receive the victim's full medical history **before arriving at the scene** — enabling them to prepare the right equipment and avoid drug interactions.

---

#### 🗺️ Tab 1 — Live Emergency Map

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  CITIZEN LIVE MAP                                                            │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │                    [Google Maps Base Layer]                           │  │
│  │                                                                       │  │
│  │   ⭕ ← Danger Zone (3+ reports clustered within 300m)                 │  │
│  │       Red semi-transparent circle overlay                             │  │
│  │                                                                       │  │
│  │        🔴 ← Live Ambulance Marker (Realtime DB stream)                │  │
│  │                                                                       │  │
│  │                 🔵 ← You (myLocationEnabled)                          │  │
│  │                                                                       │  │
│  │   🔵 H ← Hospital Marker (Firestore read)                            │  │
│  │                                                                       │  │
│  │              🟠 ← Active SOS event (Firestore stream)                │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│          ┌─────────────────────────────────┐                               │
│          │  ⬤ SOS  ← Floating, always      │                               │
│          │     visible above bottom nav     │                               │
│          └─────────────────────────────────┘                               │
│                                                                             │
│  [🗺 Map]  [⚠ Report]  [👥 Community]  [🏆 Rewards]  [🤖 Chatbot]          │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Map Layer Architecture:**

```
Google Maps Widget
    │
    ├── Realtime DB Listener → /responders/{uid}/location
    │       └── Renders: Red ambulance markers (live, every 30s update)
    │
    ├── Firestore StreamBuilder → /sos_events where status="active"
    │       └── Renders: Orange SOS markers
    │
    ├── Firestore Read → /hospitals collection
    │       └── Renders: Blue hospital markers with bed count InfoWindow
    │
    └── Client-side Spatial Clustering Engine
            └── community_reports → Haversine grouping → If count≥3 in 300m
                    └── Renders: Red semi-transparent danger circle (α=0.25)
```

---

#### 🆘 The SOS System — 4-Second Hold to Save a Life

The SOS button is the heart of Arogna. It is intentionally designed to prevent accidental triggers while remaining instantly accessible in a genuine emergency.

```
┌────────────────────────────────────────────────────────────────────────┐
│  SOS ACTIVATION SEQUENCE                                               │
└────────────────────────────────────────────────────────────────────────┘

User presses and holds SOS button (4000ms minimum)
             │
             ▼
     ┌───────────────────┐
     │  4 ... 3 ... 2 ...│  ← Countdown animation
     │   1 ... LOCKED    │
     └────────┬──────────┘
              │
              ▼
     ┌────────────────────────────────┐
     │  "Describe your emergency"     │  ← Dialog with text input
     │  [ chest pain, car accident.. ]│
     │  [ CONFIRM EMERGENCY ]         │
     └────────────────┬───────────────┘
                      │
     ┌────────────────▼────────────────────────────────┐
     │  PARALLEL EXECUTION THREADS                     │
     ├─────────────────────────────────────────────────┤
     │  Thread 1: Gemini AI → Triage: RED/YELLOW/GREEN │
     │  Thread 2: Camera → 4-5 photos (front + back)   │
     │  Thread 3: Audio → 10 sec ambient recording     │
     │  Thread 4: Geolocator → High-precision GPS      │
     │  Thread 5: URL Launcher → Auto-dial 112         │
     │  Thread 6: SMS → Emergency contacts w/ location │
     └────────────────┬────────────────────────────────┘
                      │
                      ▼
     ┌────────────────────────────────────────────────┐
     │  Firebase Write:                               │
     │  /sos_events/{id}                              │
     │  {                                             │
     │    triageLevel: "RED",                         │
     │    lat: 21.1458, lng: 79.0882,                 │
     │    mediaUrls: [...Storage URLs],               │
     │    audioUrl: "...",                            │
     │    status: "active",                           │
     │    userProfile: {bloodGroup, conditions...}    │
     │  }                                             │
     └────────────────┬───────────────────────────────┘
                      │
                      ▼
     ┌────────────────────────────────────────────────┐
     │  FCM Push Notification → All Admin Devices     │
     │  SOS Activation Screen shown to citizen        │
     │  Triage badge rendered (RED = pulsing red UI)  │
     └────────────────────────────────────────────────┘
```

---

#### ⚠️ Tab 2 — Community Incident Reporting

Citizens can report non-emergency issues that accumulate into **danger zones** on the shared map.

```
REPORT SUBMISSION FORM
──────────────────────
Category:  [Accident ▾]   [Broken Streetlight ▾]   [Fire ▾]   [Flood ▾]   [Other ▾]
Severity:  [🔴 RED]  [🟡 YELLOW]  [🟢 GREEN]
Description: [ What happened here?...                                               ]
Location:  📍 Auto-filled from GPS → 21.1458° N, 79.0882° E
Photo:     [ 📷 Tap to add (optional) ]
           [ SUBMIT REPORT ]

─────────────────────────────────────────────
RECENT COMMUNITY REPORTS (StreamBuilder)
─────────────────────────────────────────────
⚠️ ACCIDENT       [ PENDING ]   Truck overturned on NH-44  •  2 mins ago    👍 12
🔥 FIRE           [ APPROVED ]  Factory smoke near market  •  1 hour ago   👍 8
💡 STREETLIGHT    [ PENDING ]   Dark stretch near school   •  3 hours ago  👍 3
```

**Approval Flow:**
```
Citizen submits → status: "pending"
       │
       ▼
Admin reviews in Reports tab
       │
       ├── Approve → status: "approved" + FieldValue.increment(100) on user.points
       └── Reject  → status: "rejected"
```

---

#### 👥 Tab 3 — Community Hub (Reddit-Style)

```
┌─────────────────────────────────────────────────────────┐
│  COMMUNITY FEED                [+ New Post]             │
│  [Health] [Safety] [Emergency] [General]                │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ 👤 RaviKumar          🏥 HEALTH   • 2h ago       │    │
│  │ What to do during a cardiac arrest at home?     │    │
│  │ My father has a history of heart disease and... │    │
│  │ ▲ 47  💬 12  🔗 Share                           │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ 👤 PriyaS             ⚠️ SAFETY  • 5h ago       │    │
│  │ Street lights out on MG Road — 3rd night now    │    │
│  │ [Image: Dark road photo]                        │    │
│  │ ▲ 23  💬 5  🔗 Share                            │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

**Firestore Structure:**
```
/posts/{id}
  ├── userId, username, title, body
  ├── category: Health | Safety | Emergency | General
  ├── imageUrl (optional)
  ├── upvotes: 0  ← FieldValue.increment(1) on tap
  └── createdAt: serverTimestamp

/posts/{id}/comments/{id}
  ├── userId, username, text
  └── createdAt: serverTimestamp
```

---

#### 🏆 Tab 4 — Rewards & Leaderboard

A gamification layer that turns civic responsibility into a rewarding experience.

```
┌───────────────────────────────────────────────────────────────┐
│  MY STATS                                                     │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │  🛡️ GUARDIAN              Points: 672                   │  │
│  │  ████████████░░░░░░░░  67.2% to Saviour (1000 pts)      │  │
│  │  Reports Submitted: 8   │   Approved: 7                 │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                               │
│  LEADERBOARD — TOP 20                                        │
│  ────────────────────────────────────────────────────────── │
│  🥇  1.  ArjunMehta         1,240 pts    👑 SAVIOUR          │
│  🥈  2.  NitaSharma           980 pts    🛡️ GUARDIAN          │
│  🥉  3.  RaviKumar             895 pts    🛡️ GUARDIAN          │
│       4.  PriyaS               672 pts    🛡️ GUARDIAN  ← YOU  │  ← Highlighted row
│       5.  AnilTripathi         580 pts    🛡️ GUARDIAN          │
│                                                               │
│  MONTHLY CHALLENGE                                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  🎁 Top 3 this month win special community rewards   │   │
│  │  Time remaining: 3 days, 14 hours                    │   │
│  └──────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────┘
```

**Badge System:**

| Range | Badge | Description |
|---|---|---|
| 0 – 99 pts | 🌱 Newcomer | Just joined the community |
| 100 – 499 pts | 🤝 Helper | Active contributor |
| 500 – 999 pts | 🛡️ Guardian | Trusted community pillar |
| 1000+ pts | 👑 Saviour | Elite civic champion |

---

#### 🤖 Tab 5 — First-Aid AI Chatbot

Powered by Gemini 1.5 Flash with a health-constrained system prompt.

```
┌─────────────────────────────────────────────────────────┐
│  AROGNA FIRST AID ASSISTANT          [📞 CALL 112]      │
│                                                         │
│ ╔═════════════════════════════════════════════════════╗  │
│ ║ ⚕ Arogna Bot                                        ║  │
│ ║ Hi! I'm Arogna's emergency assistant. I can help    ║  │
│ ║ with first aid and medical guidance. For life-      ║  │
│ ║ threatening emergencies, press SOS or call 112.     ║  │
│ ╚═════════════════════════════════════════════════════╝  │
│                                                         │
│           ╔═══════════════════════════════════════╗      │
│           ║ My dad is having chest pain and...    ║  ←  │  User bubble (right)
│           ╚═══════════════════════════════════════╝      │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │ ⚠️ This sounds serious — press SOS immediately   │   │  ← Emergency banner
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│ ╔═══════════════════════════════════════════════════╗   │
│ ║ CALL 112 IMMEDIATELY. While waiting:             ║    │
│ ║ 1. Have him sit or lie down comfortably          ║    │
│ ║ 2. Loosen any tight clothing                     ║    │
│ ║ 3. If available, give aspirin 325mg (chew it)    ║    │
│ ║ 4. Stay with him and monitor breathing           ║    │
│ ╚═══════════════════════════════════════════════════╝   │
│                                                         │
│  [ Describe your emergency...            ] [➤ Send]    │
└─────────────────────────────────────────────────────────┘
```

**Emergency keyword detection:** `heart`, `stroke`, `bleeding`, `unconscious`, `collapse`, `chest`, `faint`, `breathing`, `attack` → triggers red warning banner + SOS prompt.

---

### 🎛️ Dashboard 2 — Admin Command Center

The admin interface is a **real-time operational console** — not a passive dashboard. Every widget is a live stream.

#### SOS Alerts Tab — Live Triage Feed

```
┌────────────────────────────────────────────────────────────────────────────┐
│  COMMAND CENTER                                          Admin User ↩       │
│  [SOS Alerts] [Live Map] [Reports] [Users] [Hospitals]                     │
├────────────────────────────────────────────────────────────────────────────┤
│  Filters: [All ●] [🔴 Critical] [🟡 Pending] [🟢 Dispatched]              │
│                                                                            │
│  Stats: Active SOS: 3   Online Responders: 7   Available Beds: 142        │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ ▌ 🔴 RED ALERT                              2 mins ago               │  │
│  │   Sarah Jenkins, 58 — Cardiac Event                                  │  │
│  │   Blood: A+  │ Conditions: Hypertension, On Digoxin                  │  │
│  │   📍 21.1458° N, 79.0882° E                                          │  │
│  │   [📷 Photo 1] [📷 Photo 2] [🎙️ Audio]                              │  │
│  │   Status: [ACTIVE ▾]       [ DISPATCH TO NEAREST ] ────────────────► │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ ▌ 🟡 YELLOW                                 8 mins ago               │  │
│  │   Marcus Cole, 24 — Motor Vehicle Accident                          │  │
│  │   Blood: B+  │ Conditions: None                                      │  │
│  │   [DISPATCHED ▾]                [ ALREADY ASSIGNED ]                 │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────┘
```

**Dispatch Logic:**
```
Admin clicks "DISPATCH"
        │
        ▼
Query Realtime DB /responders/ where status="online"
        │
        ▼
For each online responder: calculate distance to SOS victim (Haversine)
        │
        ▼
Select nearest responder
        │
        ├── Write Firestore /dispatches/{id}
        │       { sosEventId, responderId, status: "dispatched", assignedAt }
        │
        ├── Update /sos_events/{id}.status → "dispatched"
        │
        └── FCM push notification → responder's device token
```

#### Admin Live Map

```
┌────────────────────────────────────────────────────────────────────────────┐
│  GLOBAL LIVE MAP                                                            │
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                                                                      │  │
│  │   🔴 Medic 12 (online)          🔴 Medic 07 (online)                │  │
│  │                                                                      │  │
│  │              🟠 SOS Event #902                                       │  │
│  │                                                                      │  │
│  │   🔵 City Hospital (ICU: 4 free)    🔵 Apollo (ICU: 0 — FULL)       │  │
│  │                                                                      │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                            │
│  ┌──────────────┬──────────────┬──────────────┬────────────────────────┐   │
│  │ Active SOS   │ Online Units │ Free Beds    │ Avg Response Time      │   │
│  │     3        │     7        │    142       │    6.4 min             │   │
│  └──────────────┴──────────────┴──────────────┴────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────────┘
```

#### Admin Reports Management

```
COMMUNITY REPORTS CONSOLE
──────────────────────────────────────────────────────────────
Filter: [Pending (12) ●] [Approved (48)] [Rejected (3)]

┌──────────────────────────────────────────────────────────┐
│  ⚠️ ACCIDENT   •  PriyaS   •  5 mins ago   📍 2.3km away  │
│  [Photo thumbnail]  "Truck overturned on NH-44 exit"     │
│  [ ✅ APPROVE (+100 pts to user) ]  [ ❌ REJECT ]         │
└──────────────────────────────────────────────────────────┘
```

---

### 🚑 Dashboard 3 — Paramedic Responder

Designed for **field use under stress**: large touch targets, high contrast, minimal navigation.

```
┌────────────────────────────────────────────────────────────────────────────┐
│ ● ONLINE — Broadcasting Location Every 30s          [GO OFFLINE ●]        │
├────────────────────────────────────────────────────────────────────────────┤
│  ACTIVE DISPATCH                                                           │
├────────────────────────────────────────────────────────────────────────────┤
│  🔴 RED ALERT — RESPOND IMMEDIATELY                                        │
│                                                                            │
│  VICTIM: Sarah Jenkins, Female, Age 58                                     │
│  Blood Group: A+    │    Triage: 🔴 RED                                    │
│  Conditions: Hypertension, Heart Disease                                   │
│  Medications: Digoxin 0.125mg, Amlodipine 5mg                             │
│  Allergies: ⚠️ Morphine — CONTRAINDICATED                                 │
│  Emergency: "Crushing chest pain, difficulty breathing"                   │
│                                                                            │
│  📸 [Photo 1] [Photo 2] [Photo 3]    🎙️ [Play Audio]                      │
│                                                                            │
│  📍 Location: 21.1458° N, 79.0882° E    Distance: 3.2 km                  │
│                                                                            │
│  [    🗺️ NAVIGATE TO VICTIM (Google Maps)    ]  ← url_launcher deep link  │
│                                                                            │
│  STATUS:  [ ON SCENE ]  [ TRANSPORTING ]  [ RESOLVED ]                    │
├────────────────────────────────────────────────────────────────────────────┤
│  NEARBY HOSPITALS                                  Distance                │
│  ──────────────────────────────────────────────── ──────                  │
│  City Hospital    ICU: 4  General: 12  Emergency: 3    2.1 km             │
│  [🗺️ Navigate]  [📋 Book Emergency Bed]                                    │
│                                                                            │
│  Apollo Hospitals  ICU: 0  General: 8  Emergency: 1   3.5 km              │
│  [🗺️ Navigate]  [📋 Book General Bed]                                      │
├────────────────────────────────────────────────────────────────────────────┤
│  QUICK HELPLINES                                                           │
│  [🚔 Police 100] [🚑 Ambulance 108] [🔥 Fire 101]                          │
│  [👩 Women 1091] [👶 Child 1098]   [🆘 Disaster 1070]                     │
└────────────────────────────────────────────────────────────────────────────┘
```

**Location Broadcasting Logic:**
```dart
void _toggleOnline(bool value) async {
  setState(() => _isOnline = value);
  if (value) {
    await _sendLocation();  // Immediate first write
    _locationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _sendLocation(),  // Every 30 seconds
    );
  } else {
    _locationTimer?.cancel();
    await _dbRef.child('responders/$uid/location')
        .update({'status': 'offline'});
  }
}
```

---

### 🏥 Dashboard 4 — Hospital Resource Manager

Designed for reception desks and charge nurses — fast, precise, real-time.

```
┌────────────────────────────────────────────────────────────────────────────┐
│  AROGNA HOSPITAL          City General Hospital  ↩ Logout                  │
│  [Resource Status] [Incoming Patients]                                     │
├────────────────────────────────────────────────────────────────────────────┤
│  Last updated: 5 mins ago                                                  │
│                                                                            │
│  BED AVAILABILITY                                                          │
│  ┌───────────────────┐  ┌───────────────────┐                             │
│  │  ❤️ ICU Beds       │  │  🛏️ General Beds    │                            │
│  │   [ - ]  4  [ + ] │  │   [ - ]  28  [ + ] │                            │
│  └───────────────────┘  └───────────────────┘                             │
│  ┌───────────────────┐  ┌───────────────────┐                             │
│  │  🚨 Emergency Beds │  │  💨 Ventilators    │                            │
│  │   [ - ]  6  [ + ] │  │   [ - ]  3  [ + ] │                            │
│  └───────────────────┘  └───────────────────┘                             │
│                                                                            │
│  DOCTORS ON DUTY                                                           │
│  Dr. Mehta — Cardiologist    [Available ● ]                                │
│  Dr. Sharma — Emergency      [Available ● ]                                │
│  Dr. Patel — Orthopaedic     [Unavailable ○]  ← Toggle                    │
│  [+ Add Doctor]                                                            │
│                                                                            │
│  [       UPDATE GLOBAL STATUS        ] ← Saves to Firestore               │
│                                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│  INCOMING PATIENTS (Realtime Stream)                                       │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │  Sarah Jenkins   Emergency Bed   ETA: 8 mins   Medic 12  [PENDING]  │  │
│  │  [ ✅ Confirm Bed ]                                                   │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏛️ System Architecture

```
                    ┌─────────────────────────────────────────────────────┐
                    │             AROGNA MOBILE CLIENT LAYER              │
                    │      Flutter 3.x  │  Dart  │  Material 3 Design      │
                    │                                                     │
                    │   ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────┐  │
                    │   │ Citizen  │ │  Admin   │ │Responder │ │Hosp. │  │
                    │   │  App     │ │  Console │ │Navigator │ │ Mgr  │  │
                    │   └────┬─────┘ └────┬─────┘ └────┬─────┘ └──┬───┘  │
                    └────────┼────────────┼─────────────┼──────────┼──────┘
                             │            │             │          │
                    ┌────────▼────────────▼─────────────▼──────────▼──────┐
                    │              SERVICE LAYER (Dart)                   │
                    │   AuthService │ FirestoreService │ GeminiService     │
                    │   SOSService  │ LocationService  │ ChatbotService    │
                    └────────┬────────────┬─────────────────────┬─────────┘
                             │            │                     │
              ┌──────────────▼──┐  ┌──────▼───────────┐  ┌─────▼──────────────┐
              │  CLOUD FIRESTORE │  │ FIREBASE RTDB    │  │  EXTERNAL APIs     │
              │                 │  │                  │  │                    │
              │ /users          │  │ /responders      │  │ Gemini 1.5 Flash   │
              │ /sos_events     │  │   /{uid}/location│  │ (Triage + Chat)    │
              │ /community_rpts │  │ /sos_live_sync   │  │                    │
              │ /dispatches     │  │                  │  │ Google Maps API    │
              │ /hospitals      │  │ Sub-second sync  │  │ (Maps + Distance)  │
              │ /bed_bookings   │  │ for live tracking│  │                    │
              │ /posts          │  └──────────────────┘  │ FCM Push Service   │
              └─────────────────┘                        └────────────────────┘
              
              ┌──────────────────────────────────────────────────────────────┐
              │                  FIREBASE CLOUD STORAGE                      │
              │   /ids/{uid}/id.jpg           ← Identity verification         │
              │   /medical/{uid}/medical.jpg  ← Medical records               │
              │   /sos/{eventId}/photo_*.jpg  ← SOS capture frames            │
              │   /sos/{eventId}/audio.aac    ← Ambient audio recording       │
              │   /reports/{uid}/{ts}.jpg     ← Community report photos       │
              └──────────────────────────────────────────────────────────────┘
```

---

## 🗄️ Database Schema

### Cloud Firestore Collections

```javascript
// ═══════════════════════════════════════════
// /users/{uid}  — Full citizen profile
// ═══════════════════════════════════════════
{
  "uid": "STRING",
  "fullName": "STRING",
  "fatherName": "STRING",
  "phone": "STRING",
  "address": "STRING",
  "dob": "TIMESTAMP",
  "role": "citizen | admin | responder | hospital",
  
  "governmentId": {
    "type": "Aadhar | PAN | Voter ID | Passport",
    "photoUrl": "STRING (Storage URI)"
  },
  
  "medicalProfile": {
    "bloodGroup": "A+ | A- | B+ | B- | AB+ | AB- | O+ | O-",
    "preExistingConditions": ["Diabetes", "Hypertension", ...],
    "currentMedications": ["Metformin 500mg", ...],
    "allergies": ["Morphine", "Penicillin", ...],
    "medicalPhotoUrl": "STRING | null"
  },
  
  "emergencyContacts": [
    { "name": "STRING", "phone": "STRING", "relation": "STRING" },
    { "name": "STRING", "phone": "STRING", "relation": "STRING" }
  ],
  
  "rewards": {
    "points": 0,
    "badgeLevel": "Newcomer | Helper | Guardian | Saviour",
    "approvedReportsCount": 0
  },
  
  "createdAt": "SERVER_TIMESTAMP"
}

// ═══════════════════════════════════════════
// /sos_events/{id}  — Emergency incidents
// ═══════════════════════════════════════════
{
  "eventId": "STRING (UUID auto-generated)",
  "citizenUid": "STRING → /users ref",
  "citizenName": "STRING (denormalized for speed)",
  "description": "STRING (user-typed at trigger)",
  
  "triageSeverity": "RED | YELLOW | GREEN",
  "triageRationale": "STRING (Gemini explanation)",
  
  "geoCoordinates": {
    "latitude": 21.1458,
    "longitude": 79.0882
  },
  
  "userProfile": { /* Full snapshot of /users/{uid} at trigger time */ },
  
  "media": {
    "photoUrls": ["STRING", "STRING", ...],
    "audioUrl": "STRING | null"
  },
  
  "dispatchStatus": "pending | dispatched | on_scene | transporting | resolved | cancelled",
  "assignedResponderId": "STRING | null",
  "assignedHospitalId": "STRING | null",
  
  "triggeredAt": "SERVER_TIMESTAMP"
}

// ═══════════════════════════════════════════
// /community_reports/{id}
// ═══════════════════════════════════════════
{
  "reportId": "STRING",
  "reporterUid": "STRING → /users ref",
  "category": "Accident | Broken Streetlight | Bullying | Unsafe Area | Medical Emergency | Fire | Flood | Other",
  "severityRating": "Red | Yellow | Green",
  "description": "STRING",
  "attachmentUrl": "STRING | null",
  "location": { "latitude": 0.0, "longitude": 0.0 },
  "geohash": "STRING (for spatial queries)",
  "approvalState": "pending | approved | rejected",
  "upvotes": 0,
  "timestamp": "SERVER_TIMESTAMP"
}

// ═══════════════════════════════════════════
// /dispatches/{id}
// ═══════════════════════════════════════════
{
  "dispatchId": "STRING",
  "sosEventId": "STRING → /sos_events ref",
  "responderId": "STRING → /users ref",
  "hospitalId": "STRING | null",
  "status": "dispatched | on_scene | transporting | resolved",
  "routing": {
    "estimatedDistanceMeters": 3200,
    "estimatedDurationSeconds": 480
  },
  "createdAt": "SERVER_TIMESTAMP"
}

// ═══════════════════════════════════════════
// /hospitals/{uid}
// ═══════════════════════════════════════════
{
  "hospitalName": "STRING",
  "hospitalType": "General | Cardiac | Trauma | Orthopedic | Pediatric | Maternity",
  "icuBeds": 4,
  "generalBeds": 28,
  "emergencyBeds": 6,
  "ventilators": 3,
  "doctorsOnDuty": [
    { "name": "STRING", "specialty": "STRING", "available": true }
  ],
  "updatedAt": "SERVER_TIMESTAMP"
}

// ═══════════════════════════════════════════
// /bed_bookings/{id}
// ═══════════════════════════════════════════
{
  "hospitalId": "STRING → /hospitals ref",
  "responderId": "STRING → /users ref",
  "patientName": "STRING",
  "bedType": "ICU | General | Emergency | Ventilator",
  "eta": "15 mins",
  "status": "pending | confirmed | arrived",
  "createdAt": "SERVER_TIMESTAMP"
}
```

### Firebase Realtime Database — Live Telemetry

```json
{
  "responders": {
    "RESPONDER_UID_001": {
      "location": {
        "lat": 21.1458,
        "lng": 79.0882,
        "timestamp": 1774893021000,
        "status": "online"
      }
    },
    "RESPONDER_UID_002": {
      "location": {
        "lat": 21.1512,
        "lng": 79.0751,
        "timestamp": 1774892991000,
        "status": "offline"
      }
    }
  }
}
```

> **Why two databases?** Firestore is used for persistent, structured data with complex queries. Realtime Database is used *exclusively* for the live location stream — it achieves sub-second latency that Firestore cannot match, which is critical for tracking a moving ambulance.

---

## 🤖 AI & Gemini Integration

Arogna uses Gemini 1.5 Flash for two distinct workflows:

### 1. Emergency Triage Classifier

Triggered at SOS activation. Classifies the incident as RED, YELLOW, or GREEN within 5 seconds.

```
POST https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key={KEY}

SYSTEM PROMPT:
────────────────────────────────────────────────────────
You are the automated triage gateway for Arogna Emergency Network.

Classify the incident as RED, YELLOW, or GREEN:
- RED:    Imminent death risk — cardiac arrest, stroke, unconscious,
          severe haemorrhage, respiratory failure
- YELLOW: Serious but stable — fractures, severe pain, high fever,
          difficulty breathing (non-critical)
- GREEN:  Minor — small cuts, mild pain, stable vitals, non-urgent

Patient profile:
  Blood Group: {bloodGroup}
  Pre-existing Conditions: {conditions}
  Current Medications: {medications}
  Allergies: {allergies}

Incident description: {userDescription}

OUTPUT: Return a valid JSON object with exactly two keys:
{
  "triage": "RED" | "YELLOW" | "GREEN",
  "rationale": "One sentence physiological justification"
}
Do not include markdown, backticks, or any other text.
────────────────────────────────────────────────────────
```

**Why this matters:** A 58-year-old with known heart disease reporting "crushing chest pain" is *immediately* classified RED. An admin does not need to read the description — they see the RED badge and dispatch in one tap. The triage rationale is also stored for medical audit trails.

### 2. First-Aid Chatbot

A conversational assistant constrained to health and emergency topics only.

```
SYSTEM PROMPT:
────────────────────────────────────────────────────────
You are Arogna's Emergency Medical Support Core.

CRITICAL CONSTRAINT: Only respond to first-aid procedures,
medical emergencies, and healthcare guidance. If a query
is outside this scope, respond with:
"I am programmed exclusively for emergency medical support."

Response format: Clear, numbered steps under 80 words.
If life-threatening keywords detected (heart attack, stroke,
major bleeding, unconscious), prepend: [CRITICAL_URGENCY_WARNING]
────────────────────────────────────────────────────────
```

**Conversation history management:** Full history maintained as `List<Map<String, String>>` in local state, sent with each API call for contextual continuity. History capped at last 10 messages to control token costs.

---

## 🔁 Real-Time Sync Pipeline

```
┌──────────────────────────────────────────────────────────────────────────┐
│  REAL-TIME DATA FLOW — CROSS DASHBOARD SYNCHRONISATION                   │
└──────────────────────────────────────────────────────────────────────────┘

  DATA SOURCE                  TRANSPORT              CONSUMERS
  ──────────                   ─────────              ─────────

  Responder GPS location  ──►  Realtime DB  ──────►  Citizen map (red marker)
  (every 30 seconds)                         ──────►  Admin map (red marker)

  SOS event created       ──►  Firestore    ──────►  Admin SOS feed (instant)
                          ──►  FCM Push    ───────►  Admin device notification

  Admin dispatches        ──►  Firestore    ──────►  Responder active dispatch
                          ──►  FCM Push    ───────►  Responder device notification
                                            ──────►  Citizen "help on the way" UI

  Responder status update ──►  Firestore    ──────►  Admin mission board
  (on_scene / transport)                    ──────►  Citizen status banner

  Hospital updates beds   ──►  Firestore    ──────►  Responder hospital list
                                            ──────►  Admin hospitals tab

  Bed booking created     ──►  Firestore    ──────►  Hospital incoming tab
                                            ──────►  Admin hospital analytics
```

**Why this architecture is correct:**

- All list views use `StreamBuilder` (not `FutureBuilder`), meaning they react to data changes without manual refresh
- RTDB is used only for the velocity-critical path (ambulance location) — everything else goes through Firestore for reliability and query support
- FCM is used for push notifications because UI stream listeners don't activate when the app is backgrounded

---

## 🧮 Algorithms & Technical Depth

### Spatial Danger-Zone Clustering (Haversine)

Arogna computes danger zones entirely on-device using the Haversine formula — no server-side clustering required.

```dart
// Haversine distance calculation
double calculateHaversineDistance(
    double lat1, double lon1, double lat2, double lon2) {
  const double R = 6371000.0; // Earth radius in metres
  
  double dLat = _toRadians(lat2 - lat1);
  double dLon = _toRadians(lon2 - lon1);
  
  double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// Danger zone generation
List<DangerZone> computeDangerZones(List<CommunityReport> reports) {
  const double threshold = 300.0;  // 300 metres
  const int minCluster   = 3;      // minimum reports to form a zone
  
  final zones = <DangerZone>[];
  
  for (var i = 0; i < reports.length; i++) {
    final cluster = reports.where((r) =>
      calculateHaversineDistance(
        reports[i].lat, reports[i].lng, r.lat, r.lng
      ) <= threshold
    ).toList();
    
    if (cluster.length >= minCluster) {
      final avgLat = cluster.map((r) => r.lat).reduce((a, b) => a + b) / cluster.length;
      final avgLng = cluster.map((r) => r.lng).reduce((a, b) => a + b) / cluster.length;
      
      zones.add(DangerZone(
        center: LatLng(avgLat, avgLng),
        radiusMeters: threshold,
        reportCount: cluster.length,
      ));
    }
  }
  return zones;
}
```

This runs every 60 seconds and on every new community report submission. The resulting `Circle` overlays are rendered directly in the Google Maps widget.

### Parallel SOS Capture Pipeline

The SOS trigger executes multiple I/O operations concurrently using Dart's async architecture:

```dart
Future<void> triggerSOS({required String description}) async {
  // Execute all capture operations in parallel
  final results = await Future.wait([
    _capturePhotos(),      // Camera frames (front + back)
    _recordAudio(),        // 10-second ambient audio
    _getCurrentLocation(), // High-accuracy GPS
  ]);
  
  final photoUrls = results[0] as List<String>;
  final audioUrl  = results[1] as String;
  final position  = results[2] as Position;
  
  // Triage and Firestore write can now happen
  final triage = await GeminiService.triageSOS(userProfile, description);
  
  await FirebaseFirestore.instance.collection('sos_events').add({
    'triageLevel': triage,
    'lat': position.latitude,
    'lng': position.longitude,
    'mediaUrls': photoUrls,
    'audioUrl': audioUrl,
    'userProfile': userProfile,
    'status': 'active',
    'triggeredAt': FieldValue.serverTimestamp(),
  });
  
  // Non-blocking: SMS and dial happen independently
  unawaited(launchUrl(Uri.parse('tel:112')));
  unawaited(_sendSMSToContacts(position));
}
```

---

## 🛠️ Technology Stack

### Application Layer

| Component | Technology | Version |
|---|---|---|
| Framework | Flutter | 3.x |
| Language | Dart (null-safe) | 3.x |
| UI System | Material Design 3 | — |
| Font | Plus Jakarta Sans + Inter | — |
| State Management | setState + StreamBuilder | — |

### Firebase Backend

| Service | Usage |
|---|---|
| Firebase Auth | User identity, role-based access |
| Cloud Firestore | Persistent documents, complex queries |
| Realtime Database | Sub-second live location telemetry |
| Cloud Storage | SOS media, ID photos, report attachments |
| FCM | Push notifications to admin/responder |

### External APIs

| API | Purpose |
|---|---|
| Gemini 1.5 Flash | Emergency triage + first-aid chatbot |
| Google Maps Flutter | Live GIS map rendering |
| Google Distance Matrix | ETA and hospital distance calculation |
| url_launcher | Native phone dialer + SMS + Google Maps deep links |

### Key Flutter Packages

```yaml
dependencies:
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  firebase_database: ^11.0.0
  firebase_storage: ^12.0.0
  google_maps_flutter: ^2.5.0
  geolocator: ^11.0.0
  permission_handler: ^11.0.0
  image_picker: ^1.0.0
  camera: ^0.10.0
  record: ^5.0.0
  http: ^1.2.0
  url_launcher: ^6.2.0
  shared_preferences: ^2.2.0
  intl: ^0.19.0
```

---

## 📐 Screens & UI Catalogue

The app comprises **20+ screens** across 4 dashboards:

```
CITIZEN (5 tabs + overlays)          ADMIN (5 tabs)
──────────────────────────           ────────────────────────────
├── Login Screen                     ├── SOS Alerts Feed
├── Register Screen                  ├── Live Global Map
├── Citizen Home (Map Tab)           ├── Reports Management
├── SOS Activation Dialog            ├── User Management
├── SOS Confirmation Screen          └── Hospital Network View
├── Report Tab
├── Community Feed
├── Post Detail Screen               RESPONDER (single screen)
├── Rewards & Leaderboard            ────────────────────────────
└── First-Aid Chatbot                ├── Active Dispatch View
                                     ├── Hospital Navigator
                                     └── Emergency Helplines

                                     HOSPITAL (2 tabs)
                                     ────────────────────────────
                                     ├── Resource Status
                                     └── Incoming Patients
```

---

## 🏆 Why Arogna Wins — USPs

### 1. Pre-Arrival Medical Intelligence
No other emergency app transmits the victim's full medical profile to the responder **before they arrive**. Arogna does. The responder sees blood group, medications, allergies, and conditions en route — potentially preventing fatal drug interactions at the scene.

### 2. AI Triage in Under 5 Seconds
Manual dispatcher interviews take 3–5 minutes. Arogna's Gemini-powered triage completes in under 5 seconds — before the admin even reviews the alert. The triage badge is waiting when they open the dashboard.

### 3. Crowdsourced Danger Zones
Instead of just showing individual pins, Arogna's Haversine clustering algorithm aggregates reports into spatial heatmaps. Three reports within 300 metres automatically generates a danger zone circle visible to all citizens on the map — without any manual admin curation.

### 4. Gamified Civic Responsibility
A gamification layer (points, badges, leaderboard) that creates a continuous incentive for citizens to report hazards. Approved reports earn points. This solves the cold-start problem of crowdsourced safety data.

### 5. Four-Role Unified Ecosystem
Most emergency apps serve only one user type. Arogna serves four simultaneously, in a synchronised data loop. An action by any role immediately reflects on all others — no polling, no manual refresh, no phone calls between dashboards.

### 6. Zero-Registration Emergency Access
Guest mode allows anyone — even unregistered users — to trigger a one-time SOS. No account creation required in a genuine emergency. They're prompted to register afterwards.

### 7. Automated Multi-Channel SOS
A single 4-second hold triggers: AI triage, photo capture, audio recording, GPS lock, Firestore write, FCM push notification, auto-dial 112, and SMS to emergency contacts — all in parallel, all in under 10 seconds.

---

## 📊 Competitive Analysis

| Feature | Arogna | 108 Ambulance App | Jeevan Raksha | RapidSOS | iCall |
|---|---|---|---|---|---|
| AI Triage Classification | ✅ Gemini-powered | ❌ | ❌ | Partial | ❌ |
| Pre-arrival Medical Data | ✅ Full profile to responder | ❌ | ❌ | ❌ | ❌ |
| Live Ambulance Tracking | ✅ Real-time, all citizens | Limited | ❌ | ✅ | ❌ |
| Hospital Bed Visibility | ✅ Real-time inventory | ❌ | ❌ | ❌ | ❌ |
| Community Danger Zones | ✅ Spatial clustering | ❌ | ❌ | ❌ | ❌ |
| Gamified Reporting | ✅ Points + leaderboard | ❌ | ❌ | ❌ | ❌ |
| Multi-Role Ecosystem | ✅ 4 dashboards | 2 roles | 2 roles | 3 roles | 1 role |
| Guest SOS (no login) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Offline-first design | 🔄 In progress | ❌ | ❌ | ❌ | ❌ |
| First-Aid AI Chatbot | ✅ | ❌ | ❌ | ❌ | ❌ |

---

## 🌍 UN SDG Alignment

Arogna directly supports four United Nations Sustainable Development Goals:

```
┌──────────────────────────┬──────────────────────────┬──────────────────────────┬──────────────────────────┐
│      SDG 3               │       SDG 9              │      SDG 11              │       SDG 17             │
│  Good Health             │  Industry, Innovation    │  Sustainable Cities      │  Partnerships            │
│  & Well-Being            │  & Infrastructure        │  & Communities           │  for the Goals           │
├──────────────────────────┼──────────────────────────┼──────────────────────────┼──────────────────────────┤
│ Reduces emergency        │ Builds resilient digital  │ Community-validated       │ Connects citizens,       │
│ response time.           │ infrastructure via        │ danger zones make         │ government dispatch,     │
│ Pre-arrival medical      │ cloud-native architecture.│ urban spaces safer.       │ medical responders       │
│ data saves lives.        │ AI triage is innovative   │ Gamified reporting        │ and hospitals in one     │
│ First-aid chatbot        │ emergency infrastructure. │ builds civic culture.     │ unified platform.        │
│ extends healthcare       │                           │                           │                          │
│ access.                  │                           │                           │                          │
└──────────────────────────┴──────────────────────────┴──────────────────────────┴──────────────────────────┘
```

---

## 🔧 Installation & Setup

### Prerequisites

- Flutter SDK 3.x (`flutter doctor` should be all green)
- Android Studio / VS Code with Flutter extension
- Firebase CLI (`npm install -g firebase-tools`)
- FlutterFire CLI (`dart pub global activate flutterfire_cli`)
- Google account with access to Google Cloud Console

### Step 1 — Clone & Install

```bash
git clone https://github.com/your-team/arogna.git
cd arogna
flutter pub get
```

### Step 2 — Firebase Configuration

```bash
# Login to Firebase
firebase login

# Link to your Firebase project (auto-generates firebase_options.dart)
flutterfire configure --project=your-firebase-project-id
```

### Step 3 — API Keys

Open `android/app/src/main/AndroidManifest.xml` and add inside `<application>`:

```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="YOUR_GOOGLE_MAPS_ANDROID_KEY" />
```

Open `lib/constants.dart` and add:

```dart
class ArognaConfig {
  static const String geminiApiKey = "YOUR_GEMINI_API_KEY";
  static const String appName      = "Arogna";
  static const int    primaryColor  = 0xFFB71C1C;
}
```

Get your keys:
- **Gemini API Key** → [aistudio.google.com](https://aistudio.google.com) → Get API Key
- **Google Maps Key** → [console.cloud.google.com](https://console.cloud.google.com) → Enable *Maps SDK for Android* → Credentials → Create API Key

### Step 4 — Firestore & RTDB Security Rules

**Firestore Rules** (Firebase Console → Firestore → Rules):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read:  if request.auth != null;
      allow write: if request.auth.uid == uid;
    }
    match /{collection}/{id} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Realtime Database Rules**:

```json
{
  "rules": {
    ".read":  "auth != null",
    ".write": "auth != null"
  }
}
```

### Step 5 — Run

```bash
# Verify everything
flutter doctor

# Run on connected device or emulator
flutter run
```

### Step 6 — Create Test Accounts

In Firebase Console → Authentication → Add Users:

| Email | Password | Role (Firestore) |
|---|---|---|
| `citizen@arogna.com` | `arogna123` | `citizen` |
| `admin@arogna.com` | `arogna123` | `admin` |
| `responder@arogna.com` | `arogna123` | `responder` |
| `hospital@arogna.com` | `arogna123` | `hospital` |

Then in Firestore → `users` collection → create a document per user (doc ID = Firebase UID) with field `role`.

### Build APK for Submission

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📁 Project Structure

```
arogna/
├── android/
│   └── app/
│       ├── build.gradle          ← minSdkVersion 21
│       └── src/main/
│           └── AndroidManifest.xml ← Permissions + Maps key
├── lib/
│   ├── main.dart                 ← Firebase init + app entry
│   ├── firebase_options.dart     ← Auto-generated by FlutterFire CLI
│   ├── constants.dart            ← API keys + config
│   ├── theme/
│   │   └── app_theme.dart        ← Material 3 red theme
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── gemini_service.dart   ← Triage + chatbot REST calls
│   │   ├── sos_service.dart      ← Parallel capture pipeline
│   │   └── location_service.dart
│   └── screens/
│       ├── splash_screen.dart
│       ├── login_screen.dart
│       ├── register_screen.dart
│       ├── citizen/
│       │   ├── citizen_screen.dart       ← 5-tab scaffold
│       │   └── tabs/
│       │       ├── map_tab.dart          ← Live GIS + danger zones
│       │       ├── report_tab.dart
│       │       ├── community_tab.dart
│       │       ├── rewards_tab.dart
│       │       └── chatbot_tab.dart
│       ├── admin/
│       │   ├── admin_screen.dart
│       │   └── tabs/
│       │       ├── admin_sos_tab.dart
│       │       ├── admin_map_tab.dart
│       │       ├── admin_reports_tab.dart
│       │       ├── admin_users_tab.dart
│       │       └── admin_hospitals_tab.dart
│       ├── responder/
│       │   └── responder_screen.dart
│       └── hospital/
│           └── hospital_screen.dart
└── pubspec.yaml
```

---

## 👥 Team

Built for **Google Solution Challenge 2026** — Rapid Crisis Response.

| Role | Contribution |
|---|---|
| Lead Developer | Flutter architecture, Firebase integration, SOS pipeline |
| UI/UX Developer | FlutterFlow design, screen flows, Material 3 theming |
| AI Integration | Gemini API, triage system, chatbot prompting |
| Backend & DevOps | Firebase rules, database schema, FCM configuration |

**Team Name:** [Your Team Name]  
**Institution:** [Your Institution Name]  
**Track:** Open Innovation — Rapid Crisis Response

---

## 📄 License

```
MIT License

Copyright (c) 2026 Team Arogna

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction.
```

---

<div align="center">

**Built with 🔴 and a belief that emergency response can be smarter.**

*Arogna — आरोग्य — Freedom from disease, freedom from fear.*

[![Google Solution Challenge](https://img.shields.io/badge/Google%20Solution%20Challenge-2026-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://developers.google.com/community/gdsc-solution-challenge)

</div>
