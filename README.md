# Lick It — Flutter app (connected to the Laravel backend)

## Server address

Everything the app sends goes through **`lib/config/api_config.dart`**. It points at the live server,
**`https://luckit.vads.ca/api/v1`**, so the app shows the same menu, flavours, toppings, stores and rewards
as the website (all managed in the website admin).

If the server can't be reached, the app falls back to a small built-in sample menu and the Menu tab shows
a "Couldn't load the full menu · Retry" notice.

To test against a backend on your own computer instead, build with
`flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1` (Android emulator → your computer).
iOS simulator: `http://127.0.0.1:8000/api/v1`. Real phone: `http://<your-computer-LAN-IP>:8000/api/v1`
(start the server with `php artisan serve --host=0.0.0.0`).

## Run it

```bash
./setup.sh        # (or setup.bat on Windows) creates android/ios folders, icons + launch screens, INTERNET permission
flutter run
```
Sign in with a mobile number; the code is in the backend's `storage/logs/laravel.log` (or `1234` while `OTP_DEBUG_CODE=1234` on a non-production server).

## What is now live (server-driven)
Menu, categories, flavours, toppings, prices, tax / delivery / points rules · sign-in with one-time code and saved login · profile & notification toggles · delivery address · favourites · placing orders (server re-prices the cart) · order tracking (polls the kitchen status every 5 s) · collect / rate order · order history · rewards redeem (gives a code to show at the counter) · wallet top-up · photo-booth share bonus · sign out & delete account.

New files: `lib/config/api_config.dart`, `lib/services/api_client.dart` (HTTP + token), `lib/services/repo.dart` (all backend calls). Existing screens were changed only where they used mock data.

## Latest update: admin changes, camera, payments, help pages
* **Admin changes show up in the app without reinstalling.** The menu, categories, flavours, prices and settings reload when the app comes back to the foreground, when you switch tabs (at most every 30 s), and when you pull down on Home or Menu.
* **Ice cream** works like the website menu: every product in the admin's *Ice Cream* category (slug `ice-cream`) appears as a size (Single scoop, Double scoop…). Tap flavours grouped by flavour group, then add. "Single/Double/Triple" in the product name sets how many flavours are included; up to 4 extra scoops.
* **Photo Booth uses the real camera** (front or back, flash, 3 s timer, PHOTO or STRIP ×4) and puts the frame over the photo. *Share photo* opens the phone's share sheet. Points are added only after the photo is actually shared to an app. Closing the sheet or choosing Save/Copy earns nothing. The server gives the points on the customer's first share only.
* **Payments match the website checkout:** Pay at pickup / on delivery, Lick It Wallet, Pay online by card, and Wallet + pay the rest online. The fake saved Visa card, Apple/Google Pay and gift card options are gone. Wallet top-up charges the pack the same way the website does.
* **Help & legal:** one section in Profile. Allergen information, Privacy policy and Terms open as pages inside the app. The text comes from Admin > Settings > Website pages (needs the `/api/v1/pages/{page}` server file from `lickit-backend-update.zip`).
* New packages: `camera`, `share_plus`. Run `./setup.sh` again (or add the camera permission and the iOS `NSCameraUsageDescription` / `NSPhotoLibraryAddUsageDescription` keys yourself).

## Still prototype content (not connected yet)
* Apple / Google / Email sign-in buttons (show a "use your mobile number" message)
* Stores screen (static single store), "Priya's Pink Stack" saved-creation banner
* Card payment: the server uses its built-in payment driver, the same as the website. Taking real card numbers needs a payment gateway (e.g. Stripe) on the server and its card form in the app; the app never collects card numbers itself.
* Live driver location (the map animates from the order status), push notifications, menu photos in the tiles

> Not compiled in the build environment (no Flutter SDK): run `flutter pub get && flutter analyze` first and fix anything it reports.

---

# Lick It — clickable app prototype (Flutter · Android + iOS)

A working prototype of the Lick It Ice Cream & Waffle app, built from the 22 design screens. Everything is tappable: you can browse, build a waffle, check out, track the order, earn points and use the photo booth. All data is mock data that lives in memory, so restarting the app resets it.

No third-party packages are used, so there is nothing that can fail to download or conflict.

## 1. Set up (once)

You need Flutter **3.27 or newer**. The code has been checked against 3.38 and 3.47. To see your version, run `flutter --version`. For iPhone builds you also need a Mac with Xcode.

Unzip the folder, open a terminal in it and run:

| Your computer | Command |
| --- | --- |
| macOS / Linux | `./setup.sh` |
| Windows | `setup.bat` |

The script creates the `android/` and `ios/` folders, installs the Waffle Buddy app icons (Android adaptive, round and themed icons; full iOS icon set) and pink launch screens, and names the app "Lick It". It never touches the code in `lib/`. Store artwork to upload by hand is in `app_icon/store/` (see `app_icon/README.md`).

## 2. Run it

Plug in a phone with developer mode / USB debugging on, or start an emulator or simulator, then run:

```
flutter run --release
```

`--release` makes animations smooth, which matters for a client demo. Leave it off while making changes, so you get hot-reload.

## 3. Share it with the client

**Android:** run `flutter build apk --release`. Send the client `build/app/outputs/flutter-apk/app-release.apk` (WhatsApp, Drive, email). They tap it to install, allowing "install unknown apps" if asked.

**iPhone:** Apple doesn't allow sideloading. Pick one of these:

- Open `ios/Runner.xcworkspace` in Xcode, choose your team under *Signing & Capabilities* and run it on a connected iPhone.
- Upload it to TestFlight (needs a paid Apple Developer account) and invite the client.

## 4. Suggested demo walkthrough (about 5 minutes)

1. **Splash → Get started → onboarding.** On page 2, "Allow location & alerts" shows a permission prompt. Then go to **Sign in**, tap *Send me a code* and enter any 4 digits.
2. **Home.**
   - Switch **Pickup ↔ Delivery** and watch the address line change.
   - Tap the dark **"You're nearby!"** banner. This turns on 10% off shakes and jumps to the Shakes menu, where prices are struck through.
3. **Menu → Waffles → Lick It Signature.**
   - Pick Strawberry and add Oreo crumble. The total becomes $20.70.
   - Tap **Add**, then *View cart*.
4. **Cart.**
   - Try Pickup / Delivery / Dine-in. The $4.99 delivery fee appears with Delivery.
   - Tap the Vanilla Velvet upsell and "Schedule for later".
5. **Checkout.**
   - Change the points tiles and watch the GST and total recalculate.
   - Choose how to pay: at pickup, wallet, card online, or wallet + the rest online.
   - **Place order.**
6. **Tracking.**
   - The order moves from *received* to *making it* to *ready* over about 18 seconds.
   - Flip the top toggle to **Delivery** to show the live map with the moving driver.
   - Tap "I'm here, bring it out" to earn the points.
7. **Camera button** (centre of the tab bar) **→ Photo Booth.**
   - Allow the camera, swap frames, turn on the 3s timer and tap the shutter.
   - Tap *Share photo* and pick an app. The first completed share earns the points.
8. **Rewards.** Redeem a reward and watch the points drop. Tap *Wallet* to top up and see the bonus points.
9. **Home → "AI" chip → Flavour Finder.** Tap *Fruity* or type "something fruity, no nuts".

## 5. What's real and what's mocked

Fully interactive:
- navigation, cart maths, points
- GST (5%) and the delivery fee
- wallet top-ups and redeeming rewards
- ratings and favourites
- all toggles

Mocked or simulated:
- sign-in and payments
- the store map (an illustration, not Google Maps)
- the driver's position
- push notifications (shown as a demo screen)
- the AI recommendations (scripted)

The photo booth uses the phone's camera (see "Latest update" at the top).

## Project layout

```
lib/
  main.dart            app entry, portrait lock, theme
  theme.dart           brand colours & fonts (Fredoka, DM Sans, Pacifico)
  data.dart            mock menu, cart/points/wallet maths, app state
  widgets.dart         buttons, chips, cards, map & barcode painters
  plate_preview.dart   live drawing of the treat as options are picked
  screens/
    splash.dart        A01 Splash, A02 Welcome, A03 Sign in
    shell.dart         tab bar with the raised camera button
    home.dart          A04 / A04b Home (pickup & delivery)
    menu.dart          A05 Menu
    product.dart       A06 Product
    build_your_own.dart Build your own waffle (same as the website builder)
    cart.dart          A07 / A07b Cart, A08 Checkout, A09 Split pay
    tracking.dart      A10 / A10b Pickup & delivery tracking
    rewards.dart       A11 Rewards, A12 Wallet
    stores.dart        A13 Stores, A14 Geo promo notification
    photo_booth.dart   A15 Photo booth, A16 Photo share
    flavour_finder.dart A17 Flavour Finder
    orders.dart        A18 Your orders
    profile.dart       A19 Profile
assets/                logo, store photo, bundled fonts
app_icon/              Android & iOS launcher icons + launch screens
```

To change prices, menu items or the demo user, edit `lib/data.dart`. To change brand colours, edit `lib/theme.dart`.
