; scripts/installer.iss — SVIL Baduk Windows 설치본 (Inno Setup)
;
; Tauri 는 설정 한 블록으로 NSIS 설치본을 만들어줬지만 Flutter 에는 번들러가 없다.
; Inno Setup 을 고른 이유: 기존과 같은 단일 .exe 설치 UX 를 유지하고,
; scripts/sign-windows.ps1 의 서명 흐름을 그대로 재사용할 수 있다.
;
; 빌드:  npm run app:installer
;   (flutter build windows --release → iscc → 서명)

#define AppName "SVIL Baduk"
#define AppPublisher "SVIL"
#define AppExeName "svil_baduk.exe"
#define AppId "{{A7C3E1D2-9B4F-4E2A-8C15-5D6E7F8A9B0C}"

; 버전은 빌드 스크립트가 /DAppVersion=x.y.z 로 넘긴다
#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
UninstallDisplayIcon={app}\{#AppExeName}
OutputDir=..\dist-installer
OutputBaseFilename=SVIL-Baduk-{#AppVersion}-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; 관리자 권한을 요구하지 않는다 — 사용자 폴더에 설치
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible

[Languages]
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Flutter 릴리스 산출물 전체 (flutter_windows.dll, app.so, icudtl.dat, 플러그인 DLL)
Source: "..\app\build\windows\x64\runner\Release\*"; \
  DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; \
  Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

; 사용자 데이터(설정·기보·학습 진행)는 지우지 않는다.
; 위치는 README 에 적어 두고, 필요하면 사용자가 직접 지운다.
[UninstallDelete]
Type: filesandordirs; Name: "{app}\data"
