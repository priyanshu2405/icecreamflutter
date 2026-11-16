@echo off
rem One-time setup for Windows: creates the android/ and ios/ platform folders,
rem installs the Lick It app icons + launch screens and sets the app name. Safe to run more than once.
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter is not installed or not on your PATH.
  echo Install it from https://docs.flutter.dev/get-started/install and run this again.
  exit /b 1
)

echo ==^> Creating Android and iOS project files (your lib\ code is not touched)
call flutter create --platforms=android,ios --org com.lickit --project-name lick_it .
if errorlevel 1 exit /b 1

echo ==^> Installing Waffle Buddy app icons and launch screens
xcopy /E /I /Y /Q "app_icon\platform\android" "android" >nul
del /Q "ios\Runner\Assets.xcassets\AppIcon.appiconset\*" >nul 2>nul
xcopy /E /I /Y /Q "app_icon\platform\ios" "ios" >nul
powershell -NoProfile -Command "$f='android\app\src\main\AndroidManifest.xml'; $t=Get-Content $f -Raw; if ($t -notmatch 'android:roundIcon') { $t=$t -replace 'android:icon=.@mipmap/ic_launcher.', ('android:icon=' + [char]34 + '@mipmap/ic_launcher' + [char]34 + [char]10 + '        android:roundIcon=' + [char]34 + '@mipmap/ic_launcher_round' + [char]34); Set-Content $f $t }"

echo ==^> Setting app name to Lick It
powershell -NoProfile -Command "$f='android\app\src\main\AndroidManifest.xml'; (Get-Content $f) -replace 'android:label=.lick_it.', ('android:label=' + [char]34 + 'Lick It' + [char]34) | Set-Content $f"

echo ==^> Allowing network access (INTERNET permission; plain http only in debug builds)
powershell -NoProfile -Command "$f='android\app\src\main\AndroidManifest.xml'; $t=Get-Content $f -Raw; if ($t -notmatch 'android.permission.INTERNET') { $t=$t -replace '<application', ('<uses-permission android:name=' + [char]34 + 'android.permission.INTERNET' + [char]34 + '/>' + [char]10 + '    <application'); Set-Content $f $t }"
powershell -NoProfile -Command "$q=[char]34; $x='<manifest xmlns:android='+$q+'http://schemas.android.com/apk/res/android'+$q+'>'+[char]10+'    <uses-permission android:name='+$q+'android.permission.INTERNET'+$q+'/>'+[char]10+'    <application android:usesCleartextTraffic='+$q+'true'+$q+'/>'+[char]10+'</manifest>'; Set-Content 'android\app\src\debug\AndroidManifest.xml' $x"

echo ==^> Location permission (Use my current location on the delivery address map)
powershell -NoProfile -Command "$f='android\app\src\main\AndroidManifest.xml'; $t=Get-Content $f -Raw; if ($t -notmatch 'ACCESS_FINE_LOCATION') { $q=[char]34; $t=$t -replace '<application', ('<uses-permission android:name='+$q+'android.permission.ACCESS_COARSE_LOCATION'+$q+'/>'+[char]10+'    <uses-permission android:name='+$q+'android.permission.ACCESS_FINE_LOCATION'+$q+'/>'+[char]10+'    <application'); Set-Content $f $t }"
rem iOS builds need a Mac: setup.sh adds the iOS location message there.

echo ==^> Camera permission (Photo Booth)
powershell -NoProfile -Command "$f='android\app\src\main\AndroidManifest.xml'; $t=Get-Content $f -Raw; if ($t -notmatch 'android.permission.CAMERA') { $q=[char]34; $t=$t -replace '<application', ('<uses-permission android:name='+$q+'android.permission.CAMERA'+$q+'/>'+[char]10+'    <application'); Set-Content $f $t }"
rem iOS builds need a Mac: setup.sh adds the iOS camera and photo messages there.

echo ==^> Getting packages
call flutter pub get

echo.
echo Backend address: edit lib\config\api_config.dart (or use --dart-define=API_BASE_URL=...)
echo Done! Plug in an Android phone (or start an emulator) and run:  flutter run
