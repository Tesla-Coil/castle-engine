{
  Copyright 2008-2010 Michalis Kamburelis.

  This file is part of "Kambi VRML game engine".

  "Kambi VRML game engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Kambi VRML game engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Simple test of MenuRecreateForbidden mechanism in GTK backend of TGLWindow.

  This is quite internal mechanism, which you don't need to be aware of...
  Just press Alt+F to activate the menu bar, this should activate main menu,
  doing progress run. And note that nothing crashes :)

  Some notes:
  This is a tricky case of modifying menu when user activates it:
  activating menu causes ReleaseAllKeysAndMouse, and this causes KeyUp,
  which may change a menu, which is dangerous at this time.
  See MenuRecreateForbidden comments in GLWindow implementation for more
  (internal) details.
}
program test_menu_change_from_keyup;

uses VectorMath, GL, GLU, GLWindow, KambiGLUtils,
  ProgressUnit, GLProgress, KambiTimeUtils;

procedure Draw(glwin: TGLWindow);
begin
  glClear(GL_COLOR_BUFFER_BIT);
end;

procedure KeyUp(Glwin: TGLWindow; Key: TKey; C: char);
var
  I: Integer;
begin
  { Progress temporarily disables menu bar, modifying menu. }
  Progress.Init(100, 'Dummy progress bar');
  for I := 1 to 100 do
  begin
    Delay(10);
    Progress.Step;
  end;
  Progress.Fini;

  { Simpler version of this test: just directly modify the menu. }
  Glwin.MainMenu.Enabled := false;
  Glwin.MainMenu.Enabled := true;
end;

var
  Glw: TGLWindowDemo;
  M: TMenu;
begin
  Glw := TGLWindowDemo.Create(Application);

  { Create menu }
  Glw.MainMenu := TMenu.Create('Main menu');
  M := TMenu.Create('_File');
    M.Append(TMenuItem.Create('Dummy 1', 20));
    M.Append(TMenuItem.Create('Dummy 2', 30));
    Glw.MainMenu.Append(M);

  Glw.OnDraw := @Draw;
  Glw.OnKeyUp := @KeyUp;
  Glw.Open;

  GLProgressInterface.Window := Glw;
  Progress.UserInterface := GLProgressInterface;

  Application.Run;
end.
