{
  Copyright 2004-2010 Michalis Kamburelis.

  This file is part of "Kambi VRML game engine".

  "Kambi VRML game engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Kambi VRML game engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Demo of Font.BreakLines method.
  Resize the window and watch how the text lines are automatically broken.
}

{$apptype GUI}

program test_font_break;

uses GLWindow, GL, GLU, KambiGLUtils, OpenGLFonts, SysUtils, Classes,
  KambiUtils, OpenGLBmpFonts, BFNT_BitstreamVeraSans_Unit, VectorMath;

var
  Glw: TGLWindowDemo;
  Font: TGLBitmapFont_Abstract;
  BoxWidth: Integer;

procedure Draw(glwin: TGLWindow);
var x1, x2: Integer;
begin
 glClear(GL_COLOR_BUFFER_BIT);
 glLoadIdentity;
 x1 := (glwin.Width - BoxWidth) div 2;
 x2 := x1 + BoxWidth;
 glColorv(Yellow3Single);
 VerticalGLLine(x1, 0, glwin.Height);
 VerticalGLLine(x2, 0, glwin.Height);
 glColorv(White3Single);
 Font.PrintBrokenString(
   'blah blah blah, I''m a long long long text and'
   +' I''m very curious how I will be broken to fit nicely between those'
   +' two yellow lines on the screen.' +nl+
   'BTW: Note that line breaks will be correctly preserved in the broken'
   +' text.' +nl+
   nl+
   'You can resize this window and watch how this text breaks at'
   +' various line widths.', BoxWidth, x1,
   { Using Font.Descend instead of 0, so that lower parts of the lowest line
     are visible } Font.Descend,
   false, 0);
end;

procedure Resize(glwin: TGLWindow);
begin
 glViewport(0, 0, glwin.Width, glwin.Height);
 ProjectionGLOrtho(0, glwin.Width, 0, glwin.Height);
 BoxWidth := glwin.Width * 2 div 3;
end;

procedure Open(glwin: TGLWindow);
begin
 Font := TGLBitmapFont.Create(@BFNT_BitstreamVeraSans);
end;

procedure Close(glwin: TGLWindow);
begin
 FreeAndNil(Font);
end;

begin
 Glw := TGLWindowDemo.Create(Application);

 glw.OnOpen := @Open;
 glw.OnClose := @Close;
 glw.OnResize := @Resize;
 glw.DepthBufferBits := 0;
 glw.OpenAndRun('Font.BreakLines demo', @Draw);
end.