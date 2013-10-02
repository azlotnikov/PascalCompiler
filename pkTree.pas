unit pkTree;

interface

uses
  System.SysUtils,
  pkScanner;

type
  TNode = class
  public
    StrValue: String;
    Left, Right: TNode;
    Row, Col: Integer;
    constructor Create(AStrValue: String; ARow, ACol: Integer; ALeft, ARight: TNode);
    procedure Print(Depth: Integer); virtual;
  end;

  TNode<NType> = class(TNode)
  public
    Value: NType;
    constructor Create(AValue: NType; AStrValue: String; ARow, ACol: Integer; ALeft, ARight: TNode);
  end;

  TIntegerNode = class(TNode<Integer>);
  TFloatNode = class(TNode<Extended>);
  TCharNode = class(TNode<Char>);
  TStringNode = class(TNode<String>);
  TOperationNode = class(TNode<TOperationType>);
  TSeparatorNode = class(TNode<Char>);
  TIdentificatorNode = class(TNode<String>);
  TReserwedWordNode = class(TNode<TReserwedWordType>);

implementation

{ TNode }

constructor TNode.Create(AStrValue: String; ARow, ACol: Integer; ALeft, ARight: TNode);
begin
  Left := ALeft;
  Right := ARight;
  Row := ARow;
  Col := ACol;
  StrValue := AStrValue;
end;

{ TNode<NType> }

constructor TNode<NType>.Create(AValue: NType; AStrValue: String; ARow, ACol: Integer; ALeft, ARight: TNode);
begin
  inherited Create(AStrValue, ARow, ACol, ALeft, ARight);
  Value := AValue;
end;

procedure TNode.Print(Depth: Integer);
var
  i: Integer;
begin
  if Left <> nil then Left.Print(Depth + 2);
  for i := 1 to Depth do write(' ');
  writeln(StrValue);
  if Right <> nil then Right.Print(Depth + 2);
end;

end.
