#ifndef AppVersion
#define AppVersion "9.0.0"
#endif
[Setup]
AppId={{F87E10C2-1963-4D85-80E1-96046DDA9293}
AppName=Poké Tactics
AppVersion={#AppVersion}
AppPublisher=Poké Tactics Privatprojekt
DefaultDirName={localappdata}\Programs\PokeTactics
DefaultGroupName=Poké Tactics
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\dist
OutputBaseFilename=PokeTactics-Setup-{#AppVersion}
SetupIconFile=icon.ico
UninstallDisplayIcon={app}\PokeTacticsStart.exe
Compression=lzma2/fast
SolidCompression=yes
WizardStyle=modern
WizardBackColor=$00C8F0E8
CloseApplications=yes
RestartApplications=no
DisableProgramGroupPage=yes
[Languages]
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
[Tasks]
Name: desktopicon; Description: "Desktop-Verknüpfung erstellen"; Flags: unchecked
[Files]
Source: "..\dist\Bootstrap\PokeTacticsStart.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "service.json"; DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "updates.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "active.txt"; DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "..\dist\PlayerBuild\*"; DestDir: "{app}\versions\{#AppVersion}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{group}\Poké Tactics"; Filename: "{app}\PokeTacticsStart.exe"
Name: "{autodesktop}\Poké Tactics"; Filename: "{app}\PokeTacticsStart.exe"; Tasks: desktopicon
[Run]
Filename: "{app}\PokeTacticsStart.exe"; Description: "Poké Tactics starten"; Flags: nowait postinstall skipifsilent
[UninstallDelete]
Type: filesandordirs; Name: "{app}\versions"
Type: filesandordirs; Name: "{app}\staging"
Type: files; Name: "{app}\active.txt"
Type: files; Name: "{app}\previous.txt"
Type: files; Name: "{app}\service.json"
Type: files; Name: "{app}\updates.json"
Type: files; Name: "{app}\github-update-cache.json"

[Code]
function TakeVersionPart(var Value: String): Integer;
var P: Integer; Part: String;
begin
  P := Pos('.', Value);
  if P = 0 then begin Part := Value; Value := ''; end
  else begin Part := Copy(Value, 1, P - 1); Delete(Value, 1, P); end;
  Result := StrToIntDef(Part, -1);
end;

function OlderThanSetup(Value: String): Boolean;
var Wanted: String; I, A, B: Integer;
begin
  Wanted := '{#AppVersion}';
  Result := False;
  for I := 1 to 3 do begin
    A := TakeVersionPart(Value); B := TakeVersionPart(Wanted);
    if A < B then begin Result := True; Exit; end;
    if A > B then Exit;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var Current: AnsiString; Active: String;
begin
  if CurStep = ssPostInstall then begin
    Active := ExpandConstant('{app}\active.txt');
    if LoadStringFromFile(Active, Current) and OlderThanSetup(Trim(String(Current))) then begin
      SaveStringToFile(ExpandConstant('{app}\previous.txt'), Current, False);
      if not SaveStringToFile(Active, '{#AppVersion}', False) then
        RaiseException('Die neue Launcher-Version konnte nicht aktiviert werden. Bitte Setup erneut starten.');
    end;
  end;
end;
