{ -*- buffer-read-only: t -*-

  Copyright 2015-2018 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Automatically generated node properties.

  Do not edit this file manually!
  To add new properties:
  - add them to the text files in nodes_specification/components/ ,
  - and regenerate include files by running
    nodes_specification/x3d-nodes-to-pascal/x3d-nodes-to-pascal.lpr .

  The documentation for properties should go to x3dnodes_documentation.txt . }

{$ifdef read_interface}

  strict private
    function GetControlPoint: TAbstractCoordinateNode;
    procedure SetControlPoint(const Value: TAbstractCoordinateNode);
    function GetOrder: Integer;
    procedure SetOrder(const Value: Integer);
  public
    { X3D field "controlPoint". } { }
    property ControlPoint: TAbstractCoordinateNode read GetControlPoint write SetControlPoint;
    { Set X3D field "knot". } { }
    procedure SetKnot(const Value: array of Double);
    { Set X3D field "knot". } { }
    procedure SetKnot(const Value: TDoubleList);
    { X3D field "order". } { }
    property Order: Integer read GetOrder write SetOrder;
    { Set X3D field "weight". } { }
    procedure SetWeight(const Value: array of Double);
    { Set X3D field "weight". } { }
    procedure SetWeight(const Value: TDoubleList);

{$endif read_interface}

{$ifdef read_implementation}

{ TNurbsOrientationInterpolatorNode ----------------------------------------------- }

function TNurbsOrientationInterpolatorNode.GetControlPoint: TAbstractCoordinateNode;
begin
  if FdControlPoint.Value is TAbstractCoordinateNode then
    Result := TAbstractCoordinateNode(FdControlPoint.Value)
  else
    Result := nil;
end;

procedure TNurbsOrientationInterpolatorNode.SetControlPoint(const Value: TAbstractCoordinateNode);
begin
  FdControlPoint.Send(Value);
end;

procedure TNurbsOrientationInterpolatorNode.SetKnot(const Value: array of Double);
begin
  FdKnot.Send(Value);
end;

procedure TNurbsOrientationInterpolatorNode.SetKnot(const Value: TDoubleList);
begin
  FdKnot.Send(Value);
end;

function TNurbsOrientationInterpolatorNode.GetOrder: Integer;
begin
  Result := FdOrder.Value;
end;

procedure TNurbsOrientationInterpolatorNode.SetOrder(const Value: Integer);
begin
  FdOrder.Send(Value);
end;

procedure TNurbsOrientationInterpolatorNode.SetWeight(const Value: array of Double);
begin
  FdWeight.Send(Value);
end;

procedure TNurbsOrientationInterpolatorNode.SetWeight(const Value: TDoubleList);
begin
  FdWeight.Send(Value);
end;

{$endif read_implementation}
