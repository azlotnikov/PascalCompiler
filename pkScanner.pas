unit pkScanner;

interface

uses
  System.SysUtils,
  Generics.Collections;

type
  TLexemCode = (lcUnknown, lcReservedWord, lcIdentificator, lcConstant, lcInteger, lcFloat, lcError, lcSeparator,
    lcOperation, lcChar, lcString);

  TScannerState = (ssNone, ssInComment, ssInString, ssInStringQuote, ssInOperation);

  TOperationType = (ptAdd, ptSub, ptMult, ptDiv, ptIntDiv, ptMod, ptLess, ptGreater, ptLessEq, ptGreaterEq, ptAssign,
    ptEq, ptNotEq, { } ptNone);
  TReserwedWordType = (rwArray, { } rwNone);

  TLexem = record
    Code: TLexemCode;
    ValueStr: String;
    ValueInt: Integer;
    ValueFloat: Extended;
    ValueChar: Char;
    ValueOperation: TOperationType;
    ValueSeparator: Char;
    ValueReserwedWord: TReserwedWordType;
    Row: Integer;
    Col: Integer;
  end;

  TScanner = class
  private
    RCurRow: LongInt;
    RCurCol: LongInt;
    RCurLexem: TLexem;
    REndOfScan: Boolean;
    RFile: TextFile;
    RReservedWords: TList<String>;
    ROperations: TList<String>;
    ROperators: set of Char;
    RLangSymbols: set of Char;
    RSeparators: set of Char;
    RSkipSymbols: set of Char;
    RPointersSymbols: set of Char;
    RReadNextChar: Boolean;
    RExceptions: Boolean;
    RCurChar: Char;
    procedure Init;
    procedure ClearCurLexem;
    function IsIdentificator(S: String): Boolean;
    function IsReservedWord(S: String): Boolean;
    function IsOperation(S: String): Boolean;
    function IsConstant(S: String): Boolean;
    function IsChar(S: String): Boolean;
  public
    property EndOfScan: Boolean read REndOfScan;
    property CurLexem: TLexem read RCurLexem;
    constructor Create(AExceprtions: Boolean = true);
    procedure StartFileScan(FileName: String);
    destructor Free;
    function Next: Boolean;
    function NextAndGet: TLexem;
  end;

type
  TSyntaxException = class(Exception)
  public
    constructor Create(AClassName, Msg: string; Lexem: TLexem);
  end;

implementation

const
  EXCEPTION_FORMAT = 'Exception in %s: %s (Row: %d; Col: %d; Value: %s)';
  EXCEPTION_ERROR_LEXEM = 'Error Lexem';

  { TSyntaxException }

constructor TSyntaxException.Create(AClassName, Msg: string; Lexem: TLexem);
begin
  inherited Create(Format(EXCEPTION_FORMAT, [AClassName, Msg, Lexem.Row, Lexem.Col, Lexem.ValueStr]));
end;

{ TPasScaner }

function TScanner.IsChar(S: String): Boolean;
var
  i: Integer;
begin
  Result := true;
  if Length(S) < 2 then Exit(false);
  if S[1] <> '#' then Exit(false);
  for i := 2 to Length(S) do
    if not(S[i] in ['0' .. '9']) then Exit(false);
end;

function TScanner.IsConstant(S: String): Boolean;
var
  i, t: Integer;
  F: Boolean;
begin
  if S = '' then Exit(false);
  S := AnsiUpperCase(S);
  Result := true;
  t := 0;
  if (S[1] = '$') and (Length(S) > 1) then t := 1;
  for i := 1 + t to Length(S) do
    if (S[i] in ['.', '0' .. '9']) or ((t = 1) and (S[i] in ['A' .. 'F'])) then begin
      if (t = 1) and (S[i] = '.') then Exit(false);
      if (S[i] = '.') and ((i = Length(S)) or (i = 1)) then Exit(false);
    end
    else Exit(false);
end;

function TScanner.IsIdentificator(S: String): Boolean;
var
  i: Integer;
begin
  if Length(S) = 0 then Exit(false);
  S := AnsiUpperCase(S);
  Result := true;
  if not(S[1] in ['A' .. 'Z', '_']) or (IsOperation(S)) then Exit(false);
  for i := 2 to Length(S) do
    if not(S[i] in ['0' .. '9', 'A' .. 'Z', '_']) then Exit(false);
end;

function TScanner.IsOperation(S: String): Boolean;
begin
  Exit(ROperations.Contains(AnsiUpperCase(S)));
end;

function TScanner.IsReservedWord(S: String): Boolean;
begin
  Exit(RReservedWords.Contains(AnsiUpperCase(S)));
end;

procedure TScanner.StartFileScan(FileName: String);
begin
  RCurRow := 1;
  RCurCol := 1;
  ClearCurLexem;
  RReadNextChar := true;
  REndOfScan := false;
  assign(RFile, FileName);
  reset(RFile);
end;

procedure TScanner.ClearCurLexem;
begin
  with RCurLexem do begin
    Code := lcUnknown;
    ValueStr := '';
    Row := -1;
    Col := -1;
  end;
end;

constructor TScanner.Create(AExceprtions: Boolean = true);
begin
  RExceptions := AExceprtions;
  Init;
end;

destructor TScanner.Free;
begin
  RReservedWords.Free;
  ROperations.Free;
end;

procedure TScanner.Init;
begin
  RReservedWords := TList<String>.Create;
  with RReservedWords do begin
    Add('ARRAY');
    Add('BEGIN');
    Add('CASE');
    Add('CONST');
    Add('DO');
    Add('DOWNTO');
    Add('ELSE');
    Add('END');
    Add('FILE');
    Add('FOR');
    Add('FUNCTION');
    Add('IF');
    Add('IN');
    Add('LABEL');
    Add('NIL');
    Add('OF');
    Add('PROCEDURE');
    Add('PROGRAM');
    Add('RECORD');
    Add('REPEAT');
    Add('SET');
    Add('THEN');
    Add('TO');
    Add('TYPE');
    Add('UNTIL');
    Add('VAR');
    Add('WHILE');
    Add('WITH');
  end;
  // ----
  ROperations := TList<String>.Create;
  with ROperations do begin
    Add('+');
    Add('-');
    Add('*');
    Add('/');
    Add('DIV');
    Add('MOD');
    Add('<');
    Add('>');
    Add('<=');
    Add('>=');
    Add(':=');
    Add('=');
    Add('<>');
    Add('@');
    Add('^');
    Add('XOR');
    Add('NOT');
    Add('AND');
    Add('OR');
    Add('NOT');
    Add('SHL');
    Add('SHR');
  end;
  // ----
  RSeparators := [',', '(', ')', ';', '[', ']', ':'];
  ROperators := ['+', '-', '*', '/', '<', '>', '=', ':'];
  RPointersSymbols := ['@', '^'];
  RLangSymbols := ['A' .. 'Z', '0' .. '9', '_'];
  RSkipSymbols := [' ', #9];
end;

function TScanner.Next: Boolean;
var
  i, j: Integer;
  State, PreviousState: TScannerState;

  procedure AssignLex(LexCode: TLexemCode; newCurRow, newCurCol: Integer);
  begin
    with RCurLexem do begin
      if LexCode = lcConstant then begin
        if (trystrtoint(ValueStr, ValueInt)) then LexCode := lcInteger
        else if (not trystrtofloat(ValueStr, ValueFloat)) then LexCode := lcFloat
        else LexCode := lcError;
      end;
      if (LexCode = lcChar) then
        try
          ValueChar := chr(StrToInt(Copy(ValueStr, 2, Length(ValueStr) - 1)));
        except
          LexCode := lcError;
        end;
      if (LexCode = lcString) and (Length(ValueStr) = 1) then begin
        ValueChar := ValueStr[1];
        LexCode := lcChar;
      end;
      if (LexCode = lcOperation) then ValueOperation := TOperationType(ROperations.IndexOf(ValueStr))
      else ValueOperation := ptNone;
      if (LexCode = lcReservedWord) then ValueReserwedWord := TReserwedWordType(RReservedWords.IndexOf(ValueStr))
      else ValueReserwedWord := rwNone;
      if (LexCode = lcSeparator) then ValueSeparator := ValueStr[1]
      else ValueSeparator := #0;
      Code := LexCode;
      Col := RCurCol;
      Row := RCurRow;
      RCurRow := newCurRow;
      RCurCol := newCurCol;
      if (LexCode = lcError) and (RExceptions) then
          Raise TSyntaxException.Create(ClassName, EXCEPTION_ERROR_LEXEM, RCurLexem);
    end;
  end;

  procedure DoChecks(i, j: Integer);
  begin
    if (IsOperation(RCurLexem.ValueStr)) then AssignLex(lcOperation, i, j)
    else if (IsReservedWord(RCurLexem.ValueStr)) then AssignLex(lcReservedWord, i, j)
    else if (IsIdentificator(RCurLexem.ValueStr)) then AssignLex(lcIdentificator, i, j)
    else if (IsConstant(RCurLexem.ValueStr)) then AssignLex(lcConstant, i, j)
    else if (IsChar(RCurLexem.ValueStr)) then AssignLex(lcChar, i, j)
    else if (Length(RCurLexem.ValueStr) = 1) and (RCurLexem.ValueStr[1] in RSeparators) then
        AssignLex(lcSeparator, i, j)
    else AssignLex(lcError, i, j);
  end;

begin
  if REndOfScan then Exit(false);
  Result := true;
  ClearCurLexem;
  j := RCurCol;
  i := RCurRow;
  State := ssNone;
  PreviousState := ssNone;
  if EOF(RFile) and (RReadNextChar = false) then begin
    RCurLexem.ValueStr := RCurChar;
    DoChecks(i, j);
  end;
  while not EOF(RFile) do begin
    if i <> RCurRow then j := 1;
    if State = ssInString then begin
      AssignLex(lcError, i, j);
      Exit;
    end;
    if (RCurLexem.ValueStr <> '') and (State <> ssInComment) then begin
      DoChecks(i, j);
      RReadNextChar := true;
      Exit;
    end;
    while not EOln(RFile) do begin
      if RReadNextChar then read(RFile, RCurChar);
      RReadNextChar := true;
      if (RCurChar = '''') and not(State in [ssInString, ssInStringQuote, ssInComment]) and (RCurLexem.ValueStr <> '') then begin
        DoChecks(i, j);
        RReadNextChar := false;
        Exit;
      end;

      if (RCurChar = '{') and not(State in [ssInComment, ssInString]) then begin
        PreviousState := State;
        State := ssInComment;
        Inc(j);
        continue;
      end;

      if (RCurChar = '}') and (State = ssInComment) then begin
        State := PreviousState;
        Inc(j);
        continue;
      end;

      if (State = ssInComment) then begin
        Inc(j);
        continue;
      end;

      if (RCurChar = '''') and not(State in [ssInString, ssInStringQuote]) then begin
        State := ssInString;
        Inc(j);
        continue;
      end;

      if (State = ssInStringQuote) and (RCurChar <> '''') then begin
        AssignLex(lcString, i, j);
        RReadNextChar := false;
        Exit;
      end;

      if (State = ssInString) and (RCurChar = '''') then begin
        State := ssInStringQuote;
        RReadNextChar := true;
        Inc(j);
        continue;
      end;

      if (State = ssInStringQuote) and (RCurChar = '''') then State := ssInString;

      if (AnsiUpperCase(CurLexem.ValueStr) = 'END') and (RCurChar = '.') then begin
        AssignLex(lcReservedWord, i, Succ(j));
        RReadNextChar := false;
        REndOfScan := true;
        Exit;
      end;

      if (RCurChar in RPointersSymbols) and (RCurLexem.ValueStr = '') then begin
        RCurLexem.ValueStr := RCurChar;
        AssignLex(lcOperation, i, Succ(j));
        Exit;
      end;

      if (RCurLexem.ValueStr = '/') and (RCurChar = '/') then begin
        RCurLexem.ValueStr := '';
        State := ssNone;
        break;
      end;

      if (State = ssInOperation) and (not(RCurChar in ROperators - ['/'])) then begin
        DoChecks(i, j);
        RReadNextChar := false;
        Exit;
      end;

      if (RCurChar in RSeparators) and (RCurLexem.ValueStr = '') and (RCurChar <> ':') then begin
        RCurLexem.ValueStr := RCurChar;
        AssignLex(lcSeparator, i, j);
        Exit;
      end;

      if not(State in [ssInOperation, ssInString]) and (RCurLexem.ValueStr <> '') and
        (RCurChar in RSeparators + ROperators + RSkipSymbols + RPointersSymbols + ['#']) then begin
        DoChecks(i, j);
        RReadNextChar := false;
        Exit;
      end;

      if not(State in [ssInString, ssInStringQuote]) then begin
        if (RCurChar in ROperators) then State := ssInOperation
        else State := ssNone;
      end;

      if not(RCurChar in RSkipSymbols) or (State in [ssInString, ssInStringQuote]) then
        RCurLexem.ValueStr := RCurLexem.ValueStr + RCurChar;

      Inc(j);
    end;
    readln(RFile);
    Inc(i);
  end;
  if State = ssInStringQuote then AssignLex(lcString, i, j)
  else if RCurLexem.ValueStr <> '' then DoChecks(i, j)
  else Result := false;
  REndOfScan := true;
  closefile(RFile);
end;

function TScanner.NextAndGet: TLexem;
begin
  Next;
  Exit(RCurLexem);
end;

end.
