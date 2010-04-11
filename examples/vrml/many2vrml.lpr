{
  Copyright 2003-2010 Michalis Kamburelis.

  This file is part of "Kambi VRML game engine".

  "Kambi VRML game engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Kambi VRML game engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ This is an example how to use units VRMLNodes and Object3DAsVRML
  to write a simple converter from 3DS, OBJ and GEO to VRML 1.0.
  This program reads a model from filename given as parameter
  ('-' means stdin), and outputs model as VRML 1.0 to stdout.

  Note that it can also "convert" VRML 1.0 to VRML 1.0,
  this will remove all comments from input VRML and it will
  nicely format (pretty-print) output VRML.

  One real use of this program is to use it instead of view3dscene
  with --write-to-vrml parameter. This way you don't need
  e.g. OpenGL libraries (that are required to run view3dscene)
  installed on your system to perform convertion from 3DS to VRML.

  Second real use would be to modify this program to perform some
  processing of Node before it's saved to file.
  This way you write programs that process VRML files in many ways,
  e.g. change the names/order of nodes, convert some nodes
  to others, delete/add some nodes etc.
}

program many2vrml;

uses SysUtils, KambiUtils, KambiClassUtils, VRMLNodes, Object3DAsVRML;

var Node: TVRMLNode;
begin
 Parameters.CheckHigh(1);
 Node := LoadVRML(Parameters[1], true);
 try
  SaveVRMLClassic(Node, StdOutStream,
    'VRML generated by many2vrml by Kambi from '
    +Parameters[1] +' on ' +DateToStr(Date) +' at ' +TimetoStr(now));
 finally Node.Free end;
end.