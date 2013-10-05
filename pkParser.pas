unit pkParser;

interface

uses
  System.SysUtils,
  pkScanner,
  pkTree;

type
  TParser = class
  private
    RExceptions: Boolean;
    RScan: TScanner;
    function ParseTerm: TNode;
    function ParseFactor: TNode;
  public
    RRoot: TNode;
    function ParseExpression: TNode;
    procedure ParsFile(FileName: String);
    constructor Create(AExceptions: Boolean = False);
  end;

implementation

const
  EXCEPTION_NO_LEXEM_AFTER = 'No lexem after';
  EXCEPTION_NO_CLOSING_BRACKET = 'No closing bracket after';
  EXCEPTION_UNSUPPORTED_LEXEM = 'This Lexem is unsupported';

  { TParser }

function TParser.ParseFactor: TNode;
var
  Lexem: TLexem;
begin
  Result := nil;
  Lexem := RScan.CurLexem;
  case Lexem.Code of
    lcIdentificator:
      Result := TIdentificatorNode.Create(Lexem.ValueStr, Lexem.ValueStr, Lexem.Row, Lexem.Col, nil, nil);
    lcInteger: Result := TIntegerNode.Create(Lexem.ValueInt, Lexem.ValueStr, Lexem.Row, Lexem.Col, nil, nil);
    lcFloat: Result := TFloatNode.Create(Lexem.ValueFloat, Lexem.ValueStr, Lexem.Row, Lexem.Col, nil, nil);
    lcSeparator: begin
        if (Lexem.ValueSeparator = '(') then begin
          if RScan.Next then Result := ParseExpression
          else if (RExceptions) then Raise TSyntaxException.Create(EXCEPTION_NO_LEXEM_AFTER, RScan.CurLexem);
          if (RScan.CurLexem.ValueSeparator <> ')') and RExceptions then
              Raise TSyntaxException.Create(EXCEPTION_NO_CLOSING_BRACKET, RScan.CurLexem);
        end
        else Raise TSyntaxException.Create(EXCEPTION_UNSUPPORTED_LEXEM, RScan.CurLexem);
      end;
    lcError: exit(ParseFactor);
  else if (RExceptions) then Raise TSyntaxException.Create(EXCEPTION_UNSUPPORTED_LEXEM, RScan.CurLexem);
  end;
  RScan.Next;
end;

function TParser.ParseTerm: TNode;
var
  Left: TNode;
  Lexem: TLexem;
begin
  Left := ParseFactor;
  Lexem := RScan.CurLexem;
  Result := Left;
  if (Lexem.ValueOperation in [ptMult, ptDiv, ptIntDiv, ptMod]) then begin
    if RScan.Next then
        Result := TOperationNode.Create(Lexem.ValueOperation, Lexem.ValueStr, Lexem.Row, Lexem.Col, Left, ParseTerm);
  end;
end;

constructor TParser.Create(AExceptions: Boolean = False);
begin
  RExceptions := AExceptions;
  RScan := TScanner.Create(RExceptions);
end;

procedure TParser.ParsFile(FileName: String);
begin
  RScan.StartFileScan(FileName);
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
    if RScan.Next then
        Result := TOperationNode.Create(Lexem.ValueOperation, Lexem.ValueStr, Lexem.Row, Lexem.Col, Left,
        ParseExpression);
  end;
end;

end.
