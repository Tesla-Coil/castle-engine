{
  Copyright 2003-2012 Michalis Kamburelis.

  This file is part of "lets_take_a_walk".

  "lets_take_a_walk" is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  "lets_take_a_walk" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with "lets_take_a_walk"; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

  ----------------------------------------------------------------------------
}

{ Walk around the 3D world with 3D sound attached to objects.

  History: This demo was a first test of using OpenAL with our game engine,
  done on 2003-11, attaching sounds to various moving 3D objects.
  It was also the first (and the last, for now) program where I used lightmaps
  generated by our own genLightMap --- the point was to bake shadows
  on the ground texture base_shadowed.png.
  It was modified many times since then, to simplify and take advantage of T3D
  and scene manager and CastleLevels and many other features.

  If you'd like to improve it, here are some ideas (TODOs):
  - add collisions between rat and tnts and level main scene
  - more interesting rat movement track. Maybe use AI from CastleCreatures.
  - more elaborate level (initially, some house and more lamps were planned)
  - better rat sound
}

program lets_take_a_walk;

uses GL, CastleWindow, CastleScene, X3DNodes, SysUtils,
  CastleUtils, CastleGLUtils, Boxes3D, VectorMath,
  ProgressUnit, CastleProgress, CastleStringUtils,
  CastleParameters, Images, CastleMessages, CastleFilesUtils, GLImages,
  Base3D, CastleSoundEngine,
  RenderingCameraUnit, Classes, CastleControls, CastleLevels, CastleConfig,
  CastleInputs, KeysMouse, CastlePlayer;

{ global variables ----------------------------------------------------------- }

var
  Window: TCastleWindow;
  SceneManager: TGameSceneManager; //< same thing as Window.SceneManager
  Player: TPlayer; //< same thing as Window.SceneManager.Player

  TntScene: TCastleScene;
  Rat: T3DTransform;
  RatAngle: Single;

  stRatSound, stRatSqueak, stKaboom, stCricket: TSoundType;
  RatSound: TSound;

  MuteImage: TCastleImageControl;

{ TNT ------------------------------------------------------------------------ }

type
  TTnt = class(T3DTransform)
  private
    ToRemove: boolean;
  protected
    function GetChild: T3D; override;
  public
    function PointingDeviceActivate(const Active: boolean;
      const Distance: Single): boolean; override;
    procedure Idle(const CompSpeed: Single; var RemoveMe: TRemoveType); override;
  end;

const
  { Max number of TNT items. Be careful with increasing this,
    too large values may cause FPS to suffer. }
  MaxTntsCount = 40;
var
  TntsCount: Integer = 0;

function TTnt.GetChild: T3D;
begin
  Result := TntScene;
end;

function TTnt.PointingDeviceActivate(const Active: boolean;
  const Distance: Single): boolean;
begin
  Result := Active and not ToRemove;
  if not Result then Exit;

  SoundEngine.Sound3D(stKaboom, Translation);
  if PointsDistanceSqr(Translation, Rat.Translation) < 1.0 then
    SoundEngine.Sound3D(stRatSqueak, Rat.Translation);

  ToRemove := true;
  Dec(TntsCount);
end;

procedure TTnt.Idle(const CompSpeed: Single; var RemoveMe: TRemoveType);
var
  T: TVector3Single;
begin
  inherited;

  { make gravity }
  T := Translation;
  if T[2] > 0 then
  begin
    T[2] -= 5 * CompSpeed;
    MaxTo1st(T[2], 0);
    Translation := T;
  end;

  if ToRemove then
    RemoveMe := rtRemoveAndFree;
end;

procedure NewTnt(Z: Single);
var
  TntSize: Single;
  Tnt: TTnt;
  Box: TBox3D;
begin
  TntSize := TntScene.BoundingBox.MaxSize;
  Tnt := TTnt.Create(SceneManager);
  Box := SceneManager.MainScene.BoundingBox;
  Tnt.Translation := Vector3Single(
    RandomFloatRange(Box.Data[0, 0], Box.Data[1, 0]-TntSize),
    RandomFloatRange(Box.Data[0, 1], Box.Data[1, 1]-TntSize),
    Z);
  SceneManager.Items.Add(Tnt);
  Inc(TntsCount);
end;

{ some functions ------------------------------------------------------------- }

{ update Rat.Translation based on RatAngle }
procedure UpdateRatPosition;
const
  RatCircleMiddle: TVector3Single = (0, 0, 0);
  RatCircleRadius = 3;
var
  T: TVector3Single;
begin
  T := RatCircleMiddle;
  T[0] += Cos(RatAngle) * RatCircleRadius;
  T[1] += Sin(RatAngle) * RatCircleRadius;
  Rat.Translation := T;
end;

function LoadScene(const Name: string; AOwner: TComponent): TCastleScene;
begin
  Result := TCastleScene.Create(AOwner);
  Result.Load(ProgramDataPath + 'data' + PathDelim + '3d' + PathDelim + Name);
end;

type
  TDummy = class
    class procedure CameraChanged(Camera: TObject);
  end;

class procedure TDummy.CameraChanged(Camera: TObject);
{ Update stuff based on whether camera position is inside mute area. }

  function PointInsideCylinder(const P: TVector3Single;
    const MiddleX, MiddleY, Radius, MinZ, MaxZ: Single): boolean;
  begin
    Result :=
      (Sqr(P[0]-MiddleX) + Sqr(P[1]-MiddleY) <= Sqr(Radius)) and
      (MinZ <= P[2]) and (P[2] <= MaxZ);
  end;

var
  InMuteArea: boolean;
begin
  InMuteArea := PointInsideCylinder(SceneManager.Camera.GetPosition, 2, 0, 0.38, 0, 1.045640);

  MuteImage.Exists := InMuteArea;

  if InMuteArea then
    SoundEngine.Volume := 0 else
    SoundEngine.Volume := 1;
end;

{ help message --------------------------------------------------------------- }

const
  Version = '1.2.4';
  DisplayProgramName = 'lets_take_a_walk';

procedure ShowHelpMessage;
const
  HelpMessage = {$I help_message.inc};
begin
  MessageOK(Window, HelpMessage + nl +
    SCastleEngineProgramHelpSuffix(DisplayProgramName, Version, false), taLeft);
end;

{ window callbacks ----------------------------------------------------------- }

procedure Resize(Window: TCastleWindowBase);
const
  Margin = 20;
begin
  MuteImage.Left := Window.Width - MuteImage.Width - Margin;
  MuteImage.Bottom := Window.Height - MuteImage.Height - Margin;
end;

procedure Close(Window: TCastleWindowBase);
begin
  { in case no TNT actually exists in scene at closing time (you managed
    to explode them all), be sure to clean the OpenGL resources inside TntScene. }
  TntScene.GLContextClose;
end;

procedure Idle(Window: TCastleWindowBase);
begin
  { update rat }
  RatAngle += 0.5 * Window.Fps.IdleSpeed;
  UpdateRatPosition;
  if RatSound <> nil then
    RatSound.Position := Rat.Translation;
end;

procedure Timer(Window: TCastleWindowBase);
begin
  while TntsCount < MaxTntsCount do NewTnt(3.0);
end;

procedure KeyDown(Window: TCastleWindowBase; Key: TKey; c: char);
begin
  case key of
    K_T: SceneManager.MainScene.Event('MyScript', 'forceThunderNow').Send(true);
    K_F1: ShowHelpMessage;
    K_F5: Window.SaveScreen(FileNameAutoInc('lets_take_a_walk_screen_%d.png'));
  end;
end;

{ parsing parameters --------------------------------------------------------- }

const
  Options: array[0..1]of TOption =
  ((Short:'h'; Long: 'help'; Argument: oaNone),
   (Short:'v'; Long: 'version'; Argument: oaNone)
  );

procedure OptionProc(OptionNum: Integer; HasArgument: boolean;
  const Argument: string; const SeparateArgs: TSeparateArgs; Data: Pointer);
begin
  case OptionNum of
    0:begin
        InfoWrite(
          'lets_take_a_walk: a toy, demonstrating the use of VRML/X3D and OpenGL rendering' +nl+
          '  and OpenAL environmental audio combined in one simple program.' +nl+
          '  You can walk in a 3D world (with collision-checking) using DOOM-like' +nl+
          '  keys (Up/Down, Right/Left, PageUp/PageDown, Insert/Delete, Home, +/-),' +nl+
          '  you can fire up some TNTs etc. Nothing special - but I hope that' +nl+
          '  such combination of 3d graphic and sound will make a nice effect.' +nl+
          nl+
          'Options:' +nl+
          HelpOptionHelp +nl+
          VersionOptionHelp +nl+
          SoundEngine.ParseParametersHelp +nl+
          nl+
          TCastleWindowBase.ParseParametersHelp(StandardParseOptions, true) +nl+
          nl+
          SCastleEngineProgramHelpSuffix(DisplayProgramName, Version, true));
        ProgramBreak;
      end;
    1:begin
        Writeln(Version);
        ProgramBreak;
      end;
  end;
end;

{ main -------------------------------------------------------------------- }

begin
  { load config, before SoundEngine.ParseParameters
    (that may change Enable by --no-sound). }
  Config.Load;

  { change some CastlePlayer shortcuts }
  UseMouseLook := false;

  { init messages }
  MessagesTheme.RectColor[3] := 0.8;

  { init window }
  Window := TCastleWindow.Create(Application);
  Window.OnClose := @close;
  Window.OnResize := @resize;
  Window.OnIdle := @Idle;
  Window.OnTimer := @Timer;
  Window.OnKeyDown := @KeyDown;
  Window.AutoRedisplay := true;
  Window.Caption := 'Let''s take a walk';
  Window.SetDemoOptions(K_F11, CharEscape, true);

  { parse parameters }
  Window.FullScreen := true; { by default we open in fullscreen }
  Window.ParseParameters(StandardParseOptions);
  SoundEngine.ParseParameters;
  Parameters.Parse(Options, @OptionProc, nil);

  { init MuteImage. Before loading level, as loading level initializes camera
    which already causes MuteImage update. Before opening window,
    as opening window calls Resize which uses MuteImage. }
  MuteImage := TCastleImageControl.Create(Application);
  MuteImage.Blending := true;
  MuteImage.FileName := ProgramDataPath + 'data' + PathDelim + 'textures' + PathDelim +'mute_sign.png';
  MuteImage.Exists := false; // don't show it on initial progress
  Window.Controls.Insert(0, MuteImage);

  { open window, to have OpenGL context }
  Window.Open;

  { init progress }
  Progress.UserInterface := WindowProgressInterface;
  WindowProgressInterface.Window := Window;

  { init SceneManager }
  SceneManager := Window.SceneManager;
  SceneManager.OnCameraChanged := @TDummy(nil).CameraChanged;
  { If you want to make shooting (which is here realized by picking) easier,
    you can use
      SceneManager.ApproximateActivation := true;
    This could be nice for an "easy" difficulty level of the game.
    Note that many games use picking for interacting with 3D objects,
    not for shooting, and then "ApproximateActivation := true" may
    be applicable always (for any difficulty level). }

  { init player. It's not strictly necessary to use Player, but it makes
    some stuff working better/simpler: Player automatically configures
    camera (to use game-like AWSD shortcuts from CastleInputs,
    to use gravity), it adds footsteps etc. }
  Player := TPlayer.Create(SceneManager);
  SceneManager.Items.Add(Player);
  SceneManager.Player := Player;

  { init level. LoadLevel requires OpenGL context to be available. }
  LevelsAvailable.LoadFromFiles;
  SceneManager.LoadLevel('base');

  { init Rat }
  Rat := T3DTransform.Create(SceneManager);
  Rat.Add(LoadScene('rat.x3d', SceneManager));
  SceneManager.Items.Add(Rat);
  UpdateRatPosition;

  { init Tnt }
  TntScene := LoadScene('tnt.wrl', SceneManager);
  while TntsCount < MaxTntsCount do NewTnt(0.0);

  { init 3D sounds }
  SoundEngine.SoundsXmlFileName := ProgramDataPath + 'data' +
    PathDelim + 'sounds' + PathDelim + 'index.xml';
  SoundEngine.DistanceModel := dmInverseDistanceClamped; //< OpenAL default
  stRatSound  := SoundEngine.SoundFromName('rat_sound');
  stRatSqueak := SoundEngine.SoundFromName('rat_squeak');
  stKaboom    := SoundEngine.SoundFromName('kaboom');
  stCricket   := SoundEngine.SoundFromName('cricket');
  RatSound := SoundEngine.Sound3D(stRatSound, Rat.Translation, true);
  SoundEngine.Sound3D(stCricket, Vector3Single(2.61, -1.96, 1), true);

  Application.Run;
end.
