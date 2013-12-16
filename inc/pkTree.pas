unit pkTree;

interface

uses
  System.SysUtils,
  pkScanner;

type
  TExprNode = class
  public
    StrValue   : String;
    Left, Right: TExprNode;
    Row, Col   : Integer;
    constructor Create(AStrValue: String; ARow, ACol: Integer; ALeft, ARight: TExprNode);
    procedure Print(Depth: Integer); virtual;
  end;

  TExprNode<NType> = class(TExprNode)
  public
    Value: NType;
    constructor Create(AValue: NType; AStrValue: String; ARow, ACol: Integer; ALeft, ARight: TExprNode);
  end;

  TIntegerNode       = class(TExprNode<Integer>);
  TFloatNode         = class(TExprNode<Extended>);
  TCharNode          = class(TExprNode<Char>);
  TStringNode        = class(TExprNode<String>);
  TOperationNode     = class(TExprNode<TOperationType>);
  TSeparatorNode     = class(TExprNode<Char>);
  TIdentificatorNode = class(TExprNode<String>);
  TReserwedWordNode  = class(TExprNode<TReserwedWordType>);

implementation

{ TExprNode }

constructor TExprNode.Create(AStrValue: String; ARow, ACol: Integer; ALeft, ARight: TExprNode);
begin
  Left     := ALeft;
  Right    := ARight;
  Row      := ARow;
  Col      := ACol;
  StrValue := AStrValue;
end;

procedure TExprNode.Print(Depth: Integer);
var
  i: Integer;
begin
  if Left <> nil then
    Left.Print(Depth + 2);
  for i := 1 to Depth do
    write(' ');
  writeln(StrValue);
  if Right <> nil then
    Right.Print(Depth + 2);
end;

{ TExprNode<NType> }

constructor TExprNode<NType>.Create(AValue: NType; AStrValue: String; ARow, ACol: Integer; ALeft, ARight: TExprNode);
begin
  inherited Create(AStrValue, ARow, ACol, ALeft, ARight);
  Value := AValue;
end;

end.
