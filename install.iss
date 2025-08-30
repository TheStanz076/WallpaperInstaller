; Inno Setup Script for Bing Wallpaper Installer
; Save this as install.iss and compile with Inno Setup Compiler

[Setup]
AppName=Bing Wallpaper Installer
AppVersion=1.0
; Use {userappdata} or {userdocs} for a user-writable location, or let user choose
DefaultDirName={pf32}\Wallpapers
AppPublisher=Shawn S
DefaultGroupName=Bing Wallpaper
OutputBaseFilename=BingWallpaperInstaller
Compression=lzma
SolidCompression=yes

[Files]
Source: "Set-BingWallpaper.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Fallback\*"; DestDir: "{app}\Fallback"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "readme.txt"; DestDir: "{app}"; Flags: ignoreversion

[Dirs]
Name: "{app}\Archive"



[Run]
Filename: "notepad.exe"; Parameters: "{app}\readme.txt"; Description: "View the readme file"; Flags: postinstall shellexec skipifsilent
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File {app}\Set-BingWallpaper.ps1"; Description: "Run Wallpaper updater now"; Flags: postinstall shellexec skipifsilent

[Icons]
Name: "{group}\Run Bing Wallpaper Updater"; Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File {app}\Set-BingWallpaper.ps1"
[Tasks]
Name: "schedule"; Description: "Schedule daily wallpaper update"; GroupDescription: "Additional tasks:"
Name: "quality4k"; Description: "Download 4K UHD images (default)"; GroupDescription: "Image Quality:"; Flags: exclusive
Name: "qualityhd"; Description: "Download HD images (1920x1080)"; GroupDescription: "Image Quality:"; Flags: exclusive unchecked

[Code]
var
  ResultCode: Integer;
  RetentionPage: TInputQueryWizardPage;
procedure InitializeWizard;
begin
  RetentionPage := CreateInputQueryPage(wpSelectTasks,
    'Archive Retention Size',
    'Set the maximum size for archived wallpapers.',
    'Please enter the maximum archive size in megabytes (MB). Default is 500.');
  RetentionPage.Add('Max archive size (MB):', False);
  RetentionPage.Values[0] := '500';
end;
procedure WriteQualityConfig;
var
  Quality, ConfigPath, Retention, ConfigContent: String;
begin
  if WizardIsTaskSelected('qualityhd') then
    Quality := 'HD'
  else
    Quality := '4K';
  ConfigPath := ExpandConstant('{app}\config.ini');
  Retention := RetentionPage.Values[0];
  if Retention = '' then Retention := '500';
  ConfigContent := 'ImageQuality=' + Quality + #13#10 + 'MaxArchiveSizeMB=' + Retention + #13#10;
  SaveStringToFile(ConfigPath, ConfigContent, False);
end;
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if WizardIsTaskSelected('schedule') then
    begin
      ShellExec('open', 'schtasks', '/create /tn "BingWallpaperUpdater" /tr "powershell.exe -ExecutionPolicy Bypass -File ""{app}\Set-BingWallpaper.ps1""" /sc daily /st 07:00 /Z', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    end;
    WriteQualityConfig;
  end;
end;
