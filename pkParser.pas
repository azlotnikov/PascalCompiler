unit pkParser;

interface

uses
  System.SysUtils,
  pkScanner,
  pkTree;

type
  TParser = class
  private
    RScan: TPasScanner;
    function ParseTerm: TNode;
    function ParseFactor: TNode;
  public
    RRoot: TNode;
    function ParseExpression: TNode;
    procedure ParsFile(FileName: String);
    constructor Create;
  end;

implementation

{ TParser }

function TParser.ParseFactor: TNode;
var
  Lexem: TLexem;
begin
  Result := nil;
  Lexem := RScan.CurLexem;
  case Lexem.Code of
    lcIdentificator: Result := TIdentificatorNode.Create(Lexem.Value, Lexem.Value, Lexem.Row, Lexem.Col, nil, nil);
    lcInteger: Result := TIntegerNode.Create(Lexem.ValueInt, Lexem.Value, Lexem.Row, Lexem.Col, nil, nil);
    lcFloat: Result := TFloatNode.Create(Lexem.ValueFloat, Lexem.Value, Lexem.Row, Lexem.Col, nil, nil);
    lcSeparator: begin
        if (Lexem.ValueSeparator = '(') then begin
          if not RScan.EndOfScan then RScan.Next;
          Result := ParseExpression;
        end;
      end;
    lcError:;
  else

  end;
  if not RScan.EndOfScan then RScan.Next;
end;

function TParser.ParseTerm: TNode;
var
  Left: TNode;
  Lexem: TLexem;
begin
  Left := ParseFactor;
  Lexem := RScan.CurLexem;
  Result := Left;
  if (Lexem.ValueOperation in [ptMulti, ptDiv, ptIntDiv, ptMode]) then begin
    if not RScan.EndOfScan then RScan.Next;
    Result := TOperationNode.Create(Lexem.ValueOperation, Lexem.Value, Lexem.Row, Lexem.Col, Left, ParseTerm);
  end;
end;

constructor TParser.Create;
begin
  RScan := TPasScanner.Create;
end;

procedure TParser.ParsFile(FileName: String);
begin
  RScan.ScanFile(FileName);
  RScan.Next;
  RRoot := ParseExpression;
  RRoot.Print(0);
end;

function TParser.ParseExpression: TNode;
var
  Left: TNode;
  Lexem: TLexem;
begin
  Left := ParseTerm;
  Lexem := RScan.CurLexem;
  Result := Left;
  if (Lexem.ValueOperation in [ptAdd, ptSub]) then begin
    if not RScan.EndOfScan then RScan.Next;
    Result := TOperationNode.Create(Lexem.ValueOperation, Lexem.Value, Lexem.Row, Lexem.Col, Left, ParseExpression);
  end;
end;

end.
