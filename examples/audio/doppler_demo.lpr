{
  Copyright 2009-2010 Michalis Kamburelis.

  This file is part of "Kambi VRML game engine".

  "Kambi VRML game engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Kambi VRML game engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Simple demo of Doppler effect using OpenAL.
  You move the sound source by dragging with mouse over the window,
  velocity is automatically calculated. Try to drag a horizontal line
  through the window to hear the Doppler effect, listener is positioned
  in the center of the window.

  Accepts command-line options from
  http://vrmlengine.sourceforge.net/openal_notes.php }
program doppler_demo;

uses VectorMath, GLWindow, GL, GLU, KambiGLUtils,
  KambiOpenAL, ALUtils;

const
  ALDistanceScaling = 0.02;

var
  Glw: TGLWindowDemo;
  PreviousSourcePosition, SourcePosition, ListenerPosition: TVector3Single;
  Source: TALuint;

procedure Draw(Glwin: TGLWindow);
begin
  glClear(GL_COLOR_BUFFER_BIT);

  glPointSize(20.0);

  glColor3f(1, 1, 0);
  glBegin(GL_POINTS);
    glVertexv(ListenerPosition);
  glEnd;

  glColor3f(1, 1, 1);
  glBegin(GL_POINTS);
    glVertexv(SourcePosition);
  glEnd;
end;

procedure Timer(Glwin: TGLWindow);
begin
  alSourceVector3f(Source, AL_VELOCITY,
    (SourcePosition - PreviousSourcePosition) * ALDistanceScaling);
  PreviousSourcePosition := SourcePosition;
end;

procedure MouseMove(Glwin: TGLWindow; NewX, NewY: Integer);
begin
  if mbLeft in Glw.MousePressed then
  begin
    SourcePosition := Vector3Single(NewX, Glwin.Height - NewY);
    alSourceVector3f(Source, AL_POSITION, SourcePosition * ALDistanceScaling);
    Glw.PostRedisplay;
  end;
end;

var
  Buffer: TALuint;
begin
  Glw := TGLWindowDemo.Create(Application);

  OpenALOptionsParse;
  BeginAL(false);
  try
    Buffer := TALSoundFile.alCreateBufferDataFromFile('tone.wav');

    //alDopplerFactor(3.0);

    alCreateSources(1, @Source);
    alSourcei(Source, AL_BUFFER, Buffer);
    alSourcei(Source, AL_LOOPING, AL_TRUE);
    SourcePosition := Vector3Single(200, 300, 0);
    PreviousSourcePosition := SourcePosition;
    alSourceVector3f(Source, AL_POSITION, SourcePosition * ALDistanceScaling);
    alSourcePlay(Source);

    ListenerPosition := Vector3Single(300, 300, 0);
    alListenerVector3f(AL_POSITION, ListenerPosition * ALDistanceScaling);
    alListenerOrientation(Vector3Single(0, 1, 0), Vector3Single(0, 0, 1));

    Application.TimerMilisec := 1000;
    Glw.OnTimer := @Timer;
    Glw.OnDraw := @Draw;
    Glw.OnResize := @Resize2D;
    Glw.OnMouseMove := @MouseMove;
    Glw.OpenAndRun;

    alSourceStop(Source);
    alDeleteSources(1, @Source);
    alDeleteBuffers(1, @Buffer);
  finally EndAL end;
end.
