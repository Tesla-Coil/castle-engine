{$ifdef read_implementation_uses}
CastleMessages,
{$endif}

{$ifdef read_implementation}
function TCastleWindowCustom.BackendFileDialog(const Title: string; var FileName: string;
  OpenDialog: boolean; FileFilters: TFileFilterList): boolean;
begin
  Result := MessageInputQuery(Self, Title, FileName);
end;

function TCastleWindowCustom.ColorDialog(var Color: TVector3): boolean;
var
  NewColor: TVector3;
begin
  Result := false;
  if not MessageInputQuery(Self, 'Input Red value:'  , NewColor.Data[0]) then Exit;
  if not MessageInputQuery(Self, 'Input Green value:', NewColor.Data[1]) then Exit;
  if not MessageInputQuery(Self, 'Input Blue value:' , NewColor.Data[2]) then Exit;

  Result := true;
  Color := NewColor;
end;

procedure TCastleWindowCustom.MessageOK(const S: string; const MessageType: TWindowMessageType);
begin
  CastleMessages.MessageOK(Self, S);
end;

function TCastleWindowCustom.MessageYesNo(const S: string;
  const MessageType: TWindowMessageType): boolean;
begin
  Result := CastleMessages.MessageYesNo(Self, S);
end;
{$endif read_implementation}
