{
  Copyright 2017-2017 Michalis Kamburelis.

  This file is part of "Castle Game Engine".

  "Castle Game Engine" is free software; see the file COPYING.txt,
  included in this distribution, for details about the copyright.

  "Castle Game Engine" is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

  ----------------------------------------------------------------------------
}

{ Physics integration code between Castle3D and Kraft physics engine. }

{$ifdef read_interface}

  { Shape used for collision detection of a rigid body,
    placed in @link(TRigidBody.Collider) property. }
  TCollider = class(TComponent)
  private
    FKraft: TKraftShape;
    FParent: TRigidBody;
    procedure SetParent(const Value: TRigidBody);
    procedure InitializeKraft(const APhysics: TKraft;
      const ARigidBody: TKraftRigidBody);
  strict protected
    function CreateKraftShape(const APhysics: TKraft;
      const ARigidBody: TKraftRigidBody): TKraftShape; virtual; abstract;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    destructor Destroy; override;

    { Parent rigid body, which in turn refers to this collider
      by @link(TRigidBody.Collider).
      You can always assign this property instead of assigning
      the @link(TRigidBody.Collider). }
    property Parent: TRigidBody read FParent write SetParent;
  end;

  { Collide as an infinite plane.
    Place this inside @link(TRigidBody.Collider) property. }
  TPlaneCollider = class(TCollider)
  strict protected
    function CreateKraftShape(const APhysics: TKraft;
      const ARigidBody: TKraftRigidBody): TKraftShape; override;
  public
    Normal: TVector3;
    Distance: Single;
  end;

  { Collide as a box.
    Place this inside @link(TRigidBody.Collider) property. }
  TBoxCollider = class(TCollider)
  strict protected
    function CreateKraftShape(const APhysics: TKraft;
      const ARigidBody: TKraftRigidBody): TKraftShape; override;
  public
    Size: TVector3;
  end;

  { Collide as a sphere.
    Place this inside @link(TRigidBody.Collider) property. }
  TSphereCollider = class(TCollider)
  strict protected
    function CreateKraftShape(const APhysics: TKraft;
      const ARigidBody: TKraftRigidBody): TKraftShape; override;
  public
    Radius: Single;
  end;

  { Is the object moved/rotated by the physics engine, or is it only
    a static collider. See @link(TRigidBody.RigidBodyType). }
  TRigidBodyType = (
    { Physics simulation moves and rotates this object
      (because of gravity, or because it collides with others).

      Do not change the @link(T3DTransform.Translation) and other
      transformation properties of the related T3DTransform
      after assigning @link(T3DTransform.RigidBody) that is dynamic.
      They are under the control of the physics
      engine. You can still reliably read them.
    }
    rbDynamic,

    { This object is not transformed by the physics simulation,
      but it still collides with other physical objects.

      You can change the @link(T3DTransform.Translation) and other
      transformation properties of the related T3DTransform.
      But it is like destroying it and creating a new one for the physics engine,
      @italic(so do change them often, e.g. every frame).
      Use rbKinematic if you animate some object, and it should still be a collider
      for the physics engine. }
    rbStatic,

    { This object is not transformed by the physics simulation,
      but it still collides with other physical objects.

      You can change the @link(T3DTransform.Translation) and other
      transformation properties of the related T3DTransform.
      The physics engine is prepared that this object can move often,
      e.g. every frame, so you can animate the related @link(T3DTransform)
      using any technique. }
    rbKinematic
  );

  T3DCoord = 0..2;
  T3DCoords = set of T3DCoord;

  { Rigid body properties for the physics engine,
    see @link(T3DTransform.RigidBody).

    TODO: For now all the properties of this class,
    including the Collider and all properties of Collider,
    must be assigned before setting T3DTransform.RigidBody . }
  TRigidBody = class(TComponent)
  private
    FKraft: TKraftRigidBody;
    FRigidBodyType: TRigidBodyType;
    FCollider: TCollider;
    FGravity: boolean;
    //FMass: Single;
    FLockPosition: T3DCoords;
    FLockRotation: T3DCoords;
    FInitialAngularVelocity: TVector3;
    FInitialLinearVelocity: TVector3;
    FRecreateKraftInstance: boolean;
    procedure InitializeKraft(const APhysics: TKraft);
    procedure SetCollider(const Value: TCollider);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Utility function to set common values for physics in 2D games.
      Locks moving along the Z axis,
      locks rotating along the X and Y axes. }
    procedure Setup2D;

    procedure InitializeTransform(const Transform: T3DTransform);
    procedure Update(const Transform: T3DTransform; const SecondsPassed: Single);

    property InitialAngularVelocity: TVector3 read FInitialAngularVelocity write FInitialAngularVelocity;
    property InitialLinearVelocity: TVector3 read FInitialLinearVelocity write FInitialLinearVelocity;
  published
    { Is the object moved/rotated by the physics engine, or is it only
      a static collider. }
    property RigidBodyType: TRigidBodyType
      read FRigidBodyType write FRigidBodyType default rbDynamic;

    { Shape used for collisions with this object. }
    property Collider: TCollider read FCollider write SetCollider;

    { Is this object affected by gravity. }
    property Gravity: boolean read FGravity write FGravity default true;

    { Mass in kg.
      TODO: should have non-zero default?
      TODO: better to use Density, Kraft does this?
      TODO: not applied yet to Kraft. }
    // property Mass: Single read FMass write FMass;

    { Disable motion (@link(T3DTransform.Translation) change) along
      the particular (world) axis.

      For 2D games, you will usually want to disable motion along the Z axis.
      You can do this comfortably by calling @link(Setup2D). }
    property LockPosition: T3DCoords read FLockPosition write FLockPosition;

    { Disable rotation (@link(T3DTransform.Rotation) change) along
      the particular (world) axis.
      You can do this comfortably by calling @link(Setup2D). }
    property LockRotation: T3DCoords read FLockRotation write FLockRotation;
  end;

{$endif read_interface}

{$ifdef read_implementation}

{ utilities ------------------------------------------------------------------ }

function VectorToKraft(const V: TVector3): TKraftVector3;
begin
  // simple implementation
  // Result.X := V.X;
  // Result.Y := V.Y;
  // Result.Z := V.Z;

  // optimized implementation
  Assert(SizeOf(TKraftScalar) = SizeOf(Single));
  Move(V, Result, SizeOf(V));
end;

function VectorFromKraft(const V: TKraftVector3): TVector3;
begin
  // optimized implementation
  Assert(SizeOf(TKraftScalar) = SizeOf(Single));
  Move(V, Result, SizeOf(V));
end;

function MatrixToKraft(const M: TMatrix4): TKraftMatrix4x4;
begin
  Assert(SizeOf(M) = SizeOf(Result));
  // simply copy the contents,
  // memory layout is the same (column-major, Single precision)
  Move(M, Result, SizeOf(M));
end;

{ TCollider ------------------------------------------------------------------ }

procedure TCollider.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FParent) then
    { set to nil by SetParent to clean nicely }
    Parent := nil;
end;

procedure TCollider.SetParent(const Value: TRigidBody);
var
  OldParent: TRigidBody;
begin
  if FParent <> Value then
  begin
    OldParent := FParent;
    FParent := Value;
    { update OldParent.Collider after actually changing FParent,
      this way we avoid infinite loop when both TCollider and TRigidBody
      try to set each other to nil. }
    if OldParent <> nil then
    begin
      if OldParent.Collider = Self then
        OldParent.Collider := nil;
      OldParent.RemoveFreeNotification(Self);
    end;
    if FParent <> nil then
    begin
      FParent.FreeNotification(Self);
      FParent.Collider := Self;
    end;
  end;
end;

procedure TCollider.InitializeKraft(const APhysics: TKraft;
  const ARigidBody: TKraftRigidBody);
begin
  // FreeAndNil(FKraft); // do not free here, TKraftShape is owned by TKraftRigidBody
  FKraft := CreateKraftShape(APhysics, ARigidBody);
end;

destructor TCollider.Destroy;
begin
  { set to nil by SetParent, to detach free notification }
  Parent := nil;

  // FreeAndNil(FKraft); // do not free here, TKraftShape is owned by TKraftRigidBody
  inherited;
end;

{ TPlaneCollider ------------------------------------------------------------- }

function TPlaneCollider.CreateKraftShape(const APhysics: TKraft;
  const ARigidBody: TKraftRigidBody): TKraftShape;
begin
  Result := TKraftShapePlane.Create(APhysics, ARigidBody,
    Plane(Vector3Norm(VectorToKraft(Normal)), Distance));
  // TODO: make configurable
  Result.Restitution := 0.3;
end;

{ TBoxCollider --------------------------------------------------------------- }

function TBoxCollider.CreateKraftShape(const APhysics: TKraft;
  const ARigidBody: TKraftRigidBody): TKraftShape;
begin
  Result := TKraftShapeBox.Create(APhysics, ARigidBody, VectorToKraft(Size / 2));
  // TODO: make configurable
  Result.Restitution := 0.3;
  Result.Density := 100.0;
end;

{ TSphereCollider ------------------------------------------------------------ }

function TSphereCollider.CreateKraftShape(const APhysics: TKraft;
  const ARigidBody: TKraftRigidBody): TKraftShape;
begin
  Result := TKraftShapeSphere.Create(APhysics, ARigidBody, Radius);
  // TODO: make configurable
  Result.Friction := 0.4;
  Result.Restitution := 0.2;
  Result.Density := 20.0;
end;

{ TRigidBody ----------------------------------------------------------------- }

constructor TRigidBody.Create(AOwner: TComponent);
begin
  inherited;
  FGravity := true;
  FRecreateKraftInstance := true;
end;

destructor TRigidBody.Destroy;
begin
  FreeAndNil(FKraft);

  { set to nil by SetCollider, to detach free notification }
  Collider := nil;

  inherited;
end;

procedure TRigidBody.InitializeKraft(const APhysics: TKraft);
begin
  FreeAndNil(FKraft);
  FKraft := TKraftRigidBody.Create(APhysics);
  case RigidBodyType of
    rbDynamic  : FKraft.SetRigidBodyType(krbtDynamic);
    rbStatic   : FKraft.SetRigidBodyType(krbtStatic);
    rbKinematic: FKraft.SetRigidBodyType(krbtKinematic);
    else raise EInternalError.Create('TRigidBody.InitializeKraft:RigidBodyType?');
  end;
  Collider.InitializeKraft(APhysics, FKraft);
  FKraft.GravityScale := Iff(Gravity, 1.0, 0.0);
  if 0 in FLockRotation then FKraft.Flags := FKraft.Flags + [krbfLockAxisX];
  if 1 in FLockRotation then FKraft.Flags := FKraft.Flags + [krbfLockAxisY];
  if 2 in FLockRotation then FKraft.Flags := FKraft.Flags + [krbfLockAxisZ];
  FKraft.Finish;

  FKraft.CollisionGroups := [0]; // TODO: make this configurable
  if (not InitialAngularVelocity.IsPerfectlyZero) or
     (not InitialLinearVelocity.IsPerfectlyZero) then
  begin
    FKraft.AngularVelocity := VectorToKraft(InitialAngularVelocity);
    FKraft.LinearVelocity := VectorToKraft(InitialLinearVelocity);
    FKraft.SetToAwake;
  end;
end;

procedure TRigidBody.Setup2D;
begin
  LockPosition := [2];
  LockRotation := [0, 1];
end;

procedure TRigidBody.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FCollider) then
    { set to nil by SetCollider to clean nicely }
    Collider := nil;
end;

procedure TRigidBody.SetCollider(const Value: TCollider);
var
  OldCollider: TCollider;
begin
  if FCollider <> Value then
  begin
    OldCollider := FCollider;
    FCollider := Value;
    { update OldCollider.Parent after actually changing FCollider,
      this way we avoid infinite loop when both TCollider and TRigidBody
      try to set each other to nil. }
    if OldCollider <> nil then
    begin
      if OldCollider.Parent = Self then
        OldCollider.Parent := nil;
      OldCollider.RemoveFreeNotification(Self);
    end;
    if FCollider <> nil then
    begin
      FCollider.FreeNotification(Self);
      FCollider.Parent := Self;
    end;
  end;
end;

procedure TRigidBody.InitializeTransform(const Transform: T3DTransform);

  procedure RecreateKraftInstance;
  begin
    T3DWorld.InitializePhysics;
    InitializeKraft(T3DWorld.FKraftPhysics);
    // TODO: this assumes that this object is not further transformed by parents
    FKraft.SetWorldTransformation(MatrixToKraft(Transform.Transform));
  end;

begin
  if FRecreateKraftInstance then
  begin
    FRecreateKraftInstance := false;
    RecreateKraftInstance;
  end;
end;

procedure TRigidBody.Update(const Transform: T3DTransform; const SecondsPassed: Single);

  { Update current transformation from Kraft rigid body parameters. }
  procedure TransformationFromKraft;
  var
    Q: TKraftQuaternion;
    Axis: TKraftVector3;
    Angle: TKraftScalar;
    NewPos: TKraftVector3;
    Body: TKraftRigidBody;
    Shape: TKraftShape;
  begin
    Body := FKraft;
    Shape := FCollider.FKraft;

    Q := QuaternionFromMatrix4x4(Shape.InterpolatedWorldTransform);
    QuaternionToAxisAngle(Q, Axis, Angle);
    Transform.Rotation := Vector4(Axis.X, Axis.Y, Axis.Z, Angle);

    NewPos := Shape.GetCenter(Shape.InterpolatedWorldTransform);
    if LockPosition <> [] then
    begin
      { TODO: Kraft feature request for [LockPositionX / Y / Z]? }
      // apply LockPosition to fix some NewPos coords
      if 0 in LockPosition then NewPos.X := Transform.Translation[0];
      if 1 in LockPosition then NewPos.Y := Transform.Translation[1];
      if 2 in LockPosition then NewPos.Z := Transform.Translation[2];
    end;
    Transform.Translation := VectorFromKraft(NewPos);
    if LockPosition <> [] then
      // fix also position at Kraft side after fixing by LockPosition
      Body.SetWorldTransformation(MatrixToKraft(Transform.Transform));
  end;

begin
  InitializeTransform(Transform);
  case RigidBodyType of
    rbDynamic: TransformationFromKraft;
    rbKinematic:
      begin
        // TODO: check "if TransformChanged then" or such, don't do this every frame
        // TODO: this assumes that this object is not further transformed by parents
        FKraft.SetWorldTransformation(MatrixToKraft(Transform.Transform));
      end;
    // TODO: do above also for rbStatic, once "if TransformChanged then" implemented
  end;
end;

{ T3DTransform ---------------------------------------------------------- }

procedure T3DTransform.SetRigidBody(const Value: TRigidBody);
begin
  if FRigidBody <> Value then
  begin
    if FRigidBody <> nil then
      FRigidBody.RemoveFreeNotification(Self);
    FRigidBody := Value;
    if FRigidBody <> nil then
    begin
      FRigidBody.FreeNotification(Self);
      { Doing this makes sure that T3DWorld.Update
        will know the initial position of this object during 1st simulation tick.

        TODO: it's not really nice.
        - If you change a transformation from now to T3DWorld.Update,
          then 1st simulation tick will have invalid transformation anyway.
        - If you change some other rigid body parameter between now and
          next FRigidBody.Update, then next FRigidBody will recreate Kraft
          resources for this object, which is needless (we create Kraft resources
          for this transform 2 times in this case, instead of once). }
      FRigidBody.InitializeTransform(Self);
    end;
  end;
end;

{ T3DTransform --------------------------------------------------------------- }

destructor T3DTransform.Destroy;
begin
  { set to nil by SetRigidBody, to detach free notification }
  RigidBody := nil;

  inherited;
end;

procedure T3DTransform.Update(const SecondsPassed: Single;
  var RemoveMe: TRemoveType);
begin
  inherited;
  if FRigidBody <> nil then
    FRigidBody.Update(Self, SecondsPassed);
end;

procedure T3DTransform.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FRigidBody) then
    { set to nil by SetRigidBody to clean nicely }
    RigidBody := nil;
end;

{ T3DWorld ------------------------------------------------------------------- }

class procedure T3DWorld.InitializePhysics;
begin
  if FKraftPhysics = nil then
  begin
    FKraftPhysics := TKraft.Create(-1);
    //KraftPhysics.SetFrequency(120.0); // default is 60
  end;
end;

destructor T3DWorld.Destroy;
begin
  FreeAndNil(FKraftPhysics);
  inherited;
end;

procedure T3DWorld.Update(const SecondsPassed: Single; var RemoveMe: TRemoveType);
var
  PhysicsTimeStep: TFloatTime;
  KraftGravity: TVector3;
begin
  if FKraftPhysics <> nil then
  begin
    // update FKraftPhysics.Gravity
    // TODO: do we really need to be prepared that it changes each frame?
    KraftGravity := -GravityUp * 9.81;
    FKraftPhysics.Gravity.Vector := VectorToKraft(KraftGravity);

    if not WasPhysicsStep then
    begin
      FKraftPhysics.StoreWorldTransforms;
      FKraftPhysics.InterpolateWorldTransforms(0.0);
      WasPhysicsStep := true;
    end else
    begin
      PhysicsTimeStep := 1.0 / FKraftPhysics.WorldFrequency;
      TimeAccumulator := TimeAccumulator + SecondsPassed;
      while TimeAccumulator >= PhysicsTimeStep do
      begin
        TimeAccumulator := TimeAccumulator - PhysicsTimeStep;
        FKraftPhysics.StoreWorldTransforms;
        FKraftPhysics.Step(PhysicsTimeStep);
      end;

      { Kraft demo (sandbox) doesn't do this, but I think it's sensible:
        the later line InterpolateWorldTransforms assumes that we calculated
        "one time too many".
        TODO: ask Kraft author about this. }
      FKraftPhysics.StoreWorldTransforms;
      FKraftPhysics.Step(PhysicsTimeStep);

      FKraftPhysics.InterpolateWorldTransforms(TimeAccumulator / PhysicsTimeStep);
    end;
  end;

  { call inherited at the end,
    to update transformation of all items in their TRigidBody.Update
    called from T3DTransform.Update }
  inherited;
end;

{$endif read_implementation}