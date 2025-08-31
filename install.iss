[Setup]
AppName=Wallpaper Installer
AppVersion=1.0
DefaultDirName={commonpf32}\Wallpapers
AppPublisher=Shawn S
DefaultGroupName=Wallpaper
OutputBaseFilename=WallpaperInstaller
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin

[Files]
Source: "Wallpaper.ps1"; DestDir: "{app}"; Flags: replacesameversion
Source: "Fallback\*"; DestDir: "{app}\Fallback"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "readme.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "LaunchWallpaperUpdater.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "config.ini"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist


[Dirs]
Name: "{app}\Archive"

[Run]
Filename: "notepad.exe"; Parameters: """{app}\readme.txt"""; Description: "View the readme file"; Flags: postinstall shellexec skipifsilent
Filename: "{app}\LaunchWallpaperUpdater.bat"; Description: "Run Wallpaper updater now"; Flags: shellexec skipifsilent runascurrentuser postinstall

[Icons]
Name: "{group}\Run Wallpaper Updater"; Filename: "{app}\LaunchWallpaperUpdater.bat"; WorkingDir: "{app}"

[Tasks]
Name: "schedule"; Description: "Schedule daily wallpaper update"; GroupDescription: "Additional tasks:"
Name: "quality4k"; Description: "Download 4K UHD images (default)"; GroupDescription: "Image Quality:"; Flags: exclusive
Name: "qualityhd"; Description: "Download HD images (1920x1080)"; GroupDescription: "Image Quality:"; Flags: exclusive unchecked

[Code]
var
  RetentionPage: TInputQueryWizardPage;
  RegionPage: TWizardPage;
  RegionCombo: TNewComboBox;

procedure InitializeWizard;
begin
  // Archive size input
  RetentionPage := CreateInputQueryPage(wpSelectTasks,
    'Archive Retention Size',
    'Set the maximum size for archived wallpapers.',
    'Please enter the maximum archive size in megabytes (MB). Default is 500.');
  RetentionPage.Add('Max archive size (MB):', False);
  RetentionPage.Values[0] := '500';

  // Region dropdown
  RegionPage := CreateCustomPage(RetentionPage.ID, 'Select Bing Region', 'Choose your preferred Bing image region.');
  RegionCombo := TNewComboBox.Create(RegionPage.Surface);
  RegionCombo.Parent := RegionPage.Surface;
  RegionCombo.Style := csDropDownList;
  RegionCombo.Items.Add('United States (en-US)');
  RegionCombo.Items.Add('Japan (ja-JP)');
  RegionCombo.Items.Add('United Kingdom (en-GB)');
  RegionCombo.Items.Add('Germany (de-DE)');
  RegionCombo.Items.Add('France (fr-FR)');
  RegionCombo.ItemIndex := 0;
end;

function IsInteger(Value: string): Boolean;
begin
  Result := StrToIntDef(Value, -1) <> -1;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = RetentionPage.ID then
  begin
    if not IsInteger(RetentionPage.Values[0]) then
    begin
      MsgBox('Please enter a valid number for archive size.', mbError, MB_OK);
      Result := False;
    end;
  end;
end;

procedure WriteQualityConfig;
var
  Quality, ConfigPath, Retention, Region, ConfigContent, Schedule: String;
begin
  if WizardIsTaskSelected('qualityhd') then
    Quality := 'HD'
  else
    Quality := '4K';

  ConfigPath := ExpandConstant('{app}\config.ini');
  Retention := RetentionPage.Values[0];
  if Retention = '' then Retention := '500';

  case RegionCombo.ItemIndex of
    0: Region := 'en-US';
    1: Region := 'ja-JP';
    2: Region := 'en-GB';
    3: Region := 'de-DE';
    4: Region := 'fr-FR';
  else
    Region := 'en-US';
  end;

  if WizardIsTaskSelected('schedule') then
    Schedule := '1'
  else
    Schedule := '0';

  ConfigContent :=
    'ImageQuality=' + Quality + #13#10 +
    'MaxArchiveSizeMB=' + Retention + #13#10 +
    'RegionCode=' + Region + #13#10 +
    'ScheduleTask=' + Schedule + #13#10;

  SaveStringToFile(ConfigPath, ConfigContent, False);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    WriteQualityConfig;
  end;
end;