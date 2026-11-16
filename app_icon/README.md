# Lick it app icons (Waffle Buddy)

`setup.sh` / `setup.bat` copy everything in `platform/` into the `android/` and `ios/` folders, so you
normally never touch this folder. Re-run the script after `flutter create` or if the icons ever go missing.

| Folder | What it is |
| --- | --- |
| `platform/android/.../res/mipmap-*` | Launcher icon: adaptive (foreground + background), round, and monochrome for Android 13 themed icons |
| `platform/android/.../res/drawable*`, `values-v31`, `values-night-v31` | Launch screen: brand pink with the Waffle Buddy (Android 12+ uses the system splash) |
| `platform/ios/Runner/Assets.xcassets/AppIcon.appiconset` | Every iPhone / iPad size plus the 1024 App Store icon (no transparency, as Apple requires) |
| `platform/ios/Runner/Assets.xcassets/LaunchImage.imageset`, `Base.lproj/LaunchScreen.storyboard` | iOS launch screen: brand pink with the Waffle Buddy |
| `store/` | Upload these by hand: `Play-Store-Icon-512.png` and `Play-Store-Feature-Graphic-1024x500.png` (Google Play Console), `App-Store-Icon-1024.png` (App Store Connect). `Splash-1290x2796.png` is for marketing / store screenshots. |
| `icon_1024.png` | Master icon, if you ever switch to the `flutter_launcher_icons` package |

Inside the app: `assets/images/logo.png` (round Waffle Buddy badge, used by the `Logo` widget) and
`assets/images/logo_stacked_white.png` (full logo for pink screens, used by `LogoStacked`).
