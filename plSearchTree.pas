unit plSearchTree;

interface

type
  TLexemCode = (lcReservedWord, lcIdentifier, lcConstant, lcError, lcSeparator, lcLabel, lcOperation, lcUnknown,
    lcString);

  TLexem = record
    Name: String;
    Code: TLexemCode;
    Line: Word;
    CodeName: String;
  end;

  PItem = ^TItem;

  TItem = record
    Value: TLexem;
    Left, Right: PItem;
  end;

  TSearchTree = class
    FRoot: PItem;
    constructor Create;
    procedure Clear;
    procedure Free;
    function Search(Key: TLexem): PItem;
    function Locate(Key: TLexem): PItem;
    function NodesQuantity: Word;
    function Info(CName: String): String;
    function Line(CName: String): Integer;
    function Code(Name: String): TLexemCode;
    procedure ChangeCode(LName: String; LLine: Integer; NewCode: TLexemCode);
  end;

var
  LexemCodeChar: array [0 .. 8] of char = (
    'W',
    'I',
    'C',
    'E',
    'R',
    'L',
    'O',
    'U',
    'S'
  );

implementation

constructor TSearchTree.Create;
begin
  FRoot := nil;
end;

procedure TSearchTree.Free;
begin
  Clear;
  Destroy;
end;

procedure TSearchTree.Clear;

  procedure ClearTree(Item: PItem);
  begin
    if Item <> nil then begin
      ClearTree(Item.Left);
      ClearTree(Item.Right);
      Dispose(Item);
    end;
  end;

begin
  ClearTree(FRoot);
  FRoot := nil;
end;

function TSearchTree.Search(Key: TLexem): PItem;
var
  Addr: PItem;

  procedure IncKey(var Item: PItem);
  begin
    if Item = nil then begin
      Item := New(PItem);
      Item.Value := Key;
      Item.Left := nil;
      Item.Right := nil;
      Addr := Item;
    end
    else if Key.Name < Item.Value.Name then IncKey(Item.Left)
    else if Key.Name > Item.Value.Name then IncKey(Item.Right)
    else Addr := Item;
  end;

begin
  IncKey(FRoot);
  Search := Addr
end;

function TSearchTree.Locate(Key: TLexem): PItem;
var
  Item: PItem;
begin
  Item := FRoot;
  while (Item <> nil) and (Item.Value.Name <> Key.Name) do
    if Key.Name < Item.Value.Name then Item := Item.Left
    else Item := Item.Right;
  Locate := Item;
end;

function TSearchTree.NodesQuantity: Word;
var
  Count: Word;

  procedure Quant(Item: PItem);
  begin
    if Item <> nil then begin
      Inc(Count);
      Quant(Item.Left);
      Quant(Item.Right);
    end;
  end;

begin
  Count := 0;
  Quant(FRoot);
  NodesQuantity := Count
end;

function TSearchTree.Info(CName: String): String;
var
  Res: PItem;

  procedure UpDown(Item: PItem);
  begin
    if Item <> nil then begin
      if Item.Value.CodeName = CName then Res := Item
      else begin
        UpDown(Item.Left);
        UpDown(Item.Right);
      end
    end;
  end;

begin
  Res := nil;
  UpDown(FRoot);
  if Res <> nil then Info := Res.Value.Name
  else Info := ''
end;

function TSearchTree.Line(CName: String): Integer;
var
  Res: PItem;

  procedure UpDown(Item: PItem);
  begin
    if Item <> nil then begin
      if Item.Value.CodeName = CName then Res := Item
      else begin
        UpDown(Item.Left);
        UpDown(Item.Right);
      end
    end;
  end;

begin
  UpDown(FRoot);
  if Res <> nil then Line := Res.Value.Line
  else Line := -1;
end;

function TSearchTree.Code(Name: String): TLexemCode;
var
  Res: PItem;

  procedure UpDown(Item: PItem);
  begin
    if Item <> nil then begin
      if Item.Value.Name = Name then Res := Item
      else begin
        UpDown(Item.Left);
        UpDown(Item.Right);
      end
    end;
  end;

begin
  Res := nil;
  Code := lcUnknown;
  UpDown(FRoot);
  if Res <> nil then Code := Res.Value.Code
end;

procedure TSearchTree.ChangeCode(LName: String; LLine: Integer; NewCode: TLexemCode);
var
  Res: PItem;

  procedure UpDown(Item: PItem);
  begin
    if Item <> nil then begin
      if (Item.Value.Name = LName) and (Item.Value.Line = LLine) then Res := Item
      else begin
        UpDown(Item.Left);
        UpDown(Item.Right);
      end
    end;
  end;

begin
  Res := nil;
  UpDown(FRoot);
  if Res <> nil then begin
    Res.Value.CodeName[1] := 'L';
    Res.Value.Code := NewCode
  end;
end;

end.
