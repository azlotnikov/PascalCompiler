unit pkScaner;

interface

uses
  System.SysUtils,
  System.Classes,
  Generics.Collections;

type
  TLexemCode = (lcUnknown, lcReservedWord, lcIdentificator, lcConstant, lcError, lcSeparator, lcLabel, lcOperation,
    lcChar, lcString, lcComment);

  TScannerState = (ssNone, ssInComment, ssInString, ssInOperation);

  TLexem = record
    Code: TLexemCode;
    Value: String;
    ValueInt: Integer;
    ValueFloat: Extended;
    Row: Integer;
    Col: Integer;
  end;

  TPasScanner = class
  private
    CurRow: LongInt;
    CurCol: LongInt;
    RCurLexem: TLexem;
    REndOfScan: Boolean;
    RFile: TextFile;
    RReservedWords: TList<String>;
    ROperations: TList<String>;
    ROperators: set of Char;
    RLangSymbols: set of Char;
    RSeparators: set of Char;
    RSkipSymbols: set of Char;
    RReadNextChar: Boolean;
    RCurChar: Char;
    procedure Init;
    procedure ClearCurLexem;
    function IsIdentificator(S: String): Boolean;
    function IsReservedWord(S: String): Boolean;
    function IsOperation(S: String): Boolean;
    function IsConstant(S: String): Boolean;
  public
    property EndOfScan: Boolean read REndOfScan;
    property CurLexem: TLexem read RCurLexem;
    constructor Create; overload;
    constructor Create(FileName: String); overload;
    procedure LoadFromFile(FileName: String);
    destructor Free;
    procedure Next;
    function NextAndGet: TLexem;
  end;

implementation

{ TPasScaner }

function TPasScanner.IsConstant(S: String): Boolean;
var
  i, t: Integer;
  F: Boolean;
begin
  if Length(S) = 0 then exit(false);
  Result := True;
  t := 0;
  if (S[1] = '$') and (Length(S) > 1) then t := 1;
  for i := 1 + t to Length(S) do
    if (S[i] in ['.', '0' .. '9']) then begin
      if (t = 1) and (S[i] = '.') then exit(false);
      if (S[i] = '.') and ((i = Length(S)) or (i = 1)) then exit(false);
    end
    else exit(false);
end;

function TPasScanner.IsIdentificator(S: String): Boolean;
var
  i: Integer;
begin
  if Length(S) = 0 then exit(false);
  Result := True;
  if not(S[1] in ['A' .. 'Z', 'a' .. 'z']) or (IsOperation(S)) then exit(false);
  for i := 2 to Length(S) do
    if not(S[i] in ['0' .. '9', 'A' .. 'Z', 'a' .. 'z']) then exit(false);
end;

function TPasScanner.IsOperation(S: String): Boolean;
begin
  exit(ROperations.Contains(AnsiUpperCase(S)));
end;

function TPasScanner.IsReservedWord(S: String): Boolean;
begin
  exit(RReservedWords.Contains(AnsiUpperCase(S)));
end;

procedure TPasScanner.LoadFromFile(FileName: String);
begin
  CurRow := 1;
  CurCol := 1;
  ClearCurLexem;
  RReadNextChar := True;
  REndOfScan := false;
  assign(RFile, FileName);
  reset(RFile);
end;

procedure TPasScanner.ClearCurLexem;
begin
  with RCurLexem do begin
    Code := lcUnknown;
    Value := '';
    Row := -1;
    Col := -1;
  end;
end;

constructor TPasScanner.Create(FileName: String);
begin
  Create;
  LoadFromFile(FileName);
end;

constructor TPasScanner.Create;
begin
  Init;
end;

destructor TPasScanner.Free;
begin
  RReservedWords.Free;
  ROperations.Free;
end;

procedure TPasScanner.Init;
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
    Add('GOTO');
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
    Add('<');
    Add('>');
    Add('<=');
    Add('>=');
    Add(':=');
    Add('=');
    Add('<>');
    Add('XOR');
    Add('NOT');
    Add('AND');
    Add('OR');
    Add('NOT');
    Add('DIV');
    Add('MOD');
    Add('SHL');
    Add('SHR');
  end;
  // ----
  RSeparators := [',', '(', ')', ';', '[', ']', ':'];
  ROperators := ['+', '-', '*', '/', '<', '>', '=', ':'];
  RLangSymbols := ['A' .. 'Z', '0' .. '9', '_'];
  RSkipSymbols := [' ', #9];
end;

procedure TPasScanner.Next;
var
  i, j: Integer;
  State: TScannerState;

  procedure AssignLex(LexCode: TLexemCode; newCurRow, newCurCol: Integer);
  begin
    with RCurLexem do begin
      if LexCode = lcConstant then
        if not(trystrtoint(Value, ValueInt) or (not trystrtofloat(Value, ValueFloat))) then LexCode := lcError;
      Code := LexCode;
      Col := CurCol;
      Row := CurRow;
    end;
    CurRow := newCurRow;
    CurCol := newCurCol;
  end;

  procedure DoChecks(i, j: Integer);
  begin
    if (IsOperation(RCurLexem.Value)) then AssignLex(lcOperation, i, j)
    else if (IsReservedWord(RCurLexem.Value)) then AssignLex(lcReservedWord, i, j)
    else if (IsIdentificator(RCurLexem.Value)) then AssignLex(lcIdentificator, i, j)
    else if (IsConstant(RCurLexem.Value)) and (RCurChar = ':') then AssignLex(lcLabel, i, j)
    else if (IsConstant(RCurLexem.Value)) then AssignLex(lcConstant, i, j)
    else if (Length(RCurLexem.Value) = 1) and (RCurLexem.Value[1] in RSeparators) then AssignLex(lcSeparator, i, j)
    else AssignLex(lcError, i, j);
  end;

begin
  ClearCurLexem;
  j := CurCol;
  i := CurRow;
  State := ssNone;
  while not EOF(RFile) do begin
    if i <> CurRow then j := 1;
    if RCurLexem.Value <> '' then begin
      DoChecks(i, j);
      RReadNextChar := True;
      exit;
    end;
    while not EOln(RFile) do begin
      if RReadNextChar then read(RFile, RCurChar);
      RReadNextChar := True;
      if (RCurChar = '{') and (State <> ssInComment) then begin
        State := ssInComment;
        Inc(j);
        continue;
      end;

      if (RCurChar = '}') and (State = ssInComment) then begin
        State := ssNone;
        Inc(j);
        continue;
      end;

      if (State = ssInComment) then begin
        Inc(j);
        continue;
      end;

      if (RCurChar = '''') and (State <> ssInString) then begin
        State := ssInString;
        Inc(j);
        continue;
      end;

      // тут строки...

      if (AnsiUpperCase(CurLexem.Value) = 'END') and (RCurChar = '.') then begin
        AssignLex(lcReservedWord, i, Succ(j));
        RReadNextChar := false;
        exit;
      end;

      if (RCurLexem.Value = '/') and (RCurChar = '/') then begin
        RCurLexem.Value := '';
        break;
      end;

      if (State = ssInOperation) and not(RCurChar in ROperators) then begin
        DoChecks(i, j);
        RReadNextChar := false;
        exit;
      end;

      if (RCurChar in RSeparators) and (RCurLexem.Value = '') and (RCurChar <> ':') then begin
        RCurLexem.Value := RCurChar;
        AssignLex(lcSeparator, i, j);
        exit;
      end;

      if (State <> ssInOperation) and (RCurLexem.Value <> '') and (RCurChar in RSeparators + ROperators + RSkipSymbols)
      then begin
        DoChecks(i, j);
        RReadNextChar := false;
        exit;
      end;

      if (RCurChar in ROperators) then State := ssInOperation
      else State := ssNone;

      if not(RCurChar in RSkipSymbols) then RCurLexem.Value := RCurLexem.Value + RCurChar;

      Inc(j);
    end;
    readln(RFile);
    Inc(i);
  end;
  REndOfScan := True;
  closefile(RFile);
end;

function TPasScanner.NextAndGet: TLexem;
begin
  Next;
  exit(RCurLexem);
end;

end.
