unit pkScaner;

interface

uses
  System.SysUtils,
  System.Classes,
  Generics.Collections;

type
  TLexemCode = (lcUnknown, lcReservedWord, lcIdentificator, lcConstant, lcError, lcSeparator, lcLabel, lcOperation,
    lcString, lcComment);

  TScannerState = (ssError, ssInComment, ssInString, ssInOperation);

  TLexem = record
    Code: TLexemCode;
    Value: String;
    ValueInt: integer;
    ValueFloat: extended;
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
    ROperators: set of char;
    RLangSymbols: set of char;
    RSeparators: set of char;
    RSkipSymbols: set of char;
    RReadNextChar: boolean;
    RCurChar: Char;
    procedure Init;
    procedure ClearCurLexem;
    function IsIdentificator(S: String): Boolean;
    function IsReservedWord(S: string): Boolean;
    function IsOperation(S: string): Boolean;
    function IsConstant(S: string): Boolean;
  public
    property EndOfScan: Boolean read REndOfScan;
    property CurLexem: TLexem read RCurLexem;
    constructor Create; overload;
    constructor Create(FileName: string); overload;
    procedure LoadFromFile(FileName: string);
    procedure Free;
    procedure Next;
  end;

implementation

{ TPasScaner }

function TPasScanner.IsConstant(S: string): Boolean;
var
  I, t: Integer;
  F: Boolean;
begin
  if Length(S) = 0 then exit(false);
  Result := True;
  t := 0;
  if (S[1] = '$' ) and (Length(S) > 1) then t := 1;
  for I := 1 + t to Length(S) do
    if (S[I] in ['.', '0' .. '9']) then begin
      if (t = 1) and (S[I] = '.') then exit(false);
      if (S[I] = '.') and ((I = Length(S)) or (I = 1)) then exit(false);
    end
    else exit(false);
end;

function TPasScanner.IsIdentificator(S: String): Boolean;
var
  I: Integer;
begin
  if Length(S) = 0 then exit(false);
  Result := True;
  if not(S[1] in ['A' .. 'Z', 'a' .. 'z']) or (IsOperation(S)) then exit(false);
  for I := 2 to Length(S) do
    if not(S[I] in ['0' .. '9', 'A' .. 'Z', 'a' .. 'z']) then exit(false);
end;

function TPasScanner.IsOperation(S: string): Boolean;
var
  t:integer;
begin
  Exit(ROperations.BinarySearch(S, T));
end;

function TPasScanner.IsReservedWord(S: string): Boolean;
var
  t:integer;
begin
  Exit(RReservedWords.BinarySearch(S, T));
end;

procedure TPasScanner.LoadFromFile(FileName: string);
begin
  CurRow := 1;
  CurCol := 1;
  ClearCurLexem;
  RReadNextChar := true;
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

constructor TPasScanner.Create(FileName: string);
begin
  Create;
  LoadFromFile(FileName);
end;

constructor TPasScanner.Create;
begin
  Init;
end;

procedure TPasScanner.Free;
begin
  Destroy;
end;

procedure TPasScanner.Init;
begin
  RReservedWords := TList<String>.Create;
  RReservedWords.Add('ARRAY');
  RReservedWords.Add('BEGIN');
  RReservedWords.Add('CASE');
  RReservedWords.Add('CONST');
  RReservedWords.Add('DO');
  RReservedWords.Add('DOWNTO');
  RReservedWords.Add('ELSE');
  RReservedWords.Add('END');
  RReservedWords.Add('FILE');
  RReservedWords.Add('FOR');
  RReservedWords.Add('FUNCTION');
  RReservedWords.Add('GOTO');
  RReservedWords.Add('IF');
  RReservedWords.Add('IN');
  RReservedWords.Add('LABEL');
  RReservedWords.Add('NIL');
  RReservedWords.Add('OF');
  RReservedWords.Add('PROCEDURE');
  RReservedWords.Add('PROGRAM');
  RReservedWords.Add('RECORD');
  RReservedWords.Add('REPEAT');
  RReservedWords.Add('SET');
  RReservedWords.Add('THEN');
  RReservedWords.Add('TO');
  RReservedWords.Add('TYPE');
  RReservedWords.Add('UNTIL');
  RReservedWords.Add('VAR');
  RReservedWords.Add('WHILE');
  RReservedWords.Add('WITH');
  // ----
  ROperations := TList<String>.Create;
  ROperations.Add('+');
  ROperations.Add('-');
  ROperations.Add('*');
  ROperations.Add('/');
  ROperations.Add('<');
  ROperations.Add('>');
  ROperations.Add('<=');
  ROperations.Add('>=');
  ROperations.Add(':=');
  ROperations.Add('=');
  ROperations.Add('XOR');
  ROperations.Add('NOT');
  ROperations.Add('AND');
  ROperations.Add('OR');
  ROperations.Add('NOT');
  ROperations.Add('DIV');
  ROperations.Add('MOD');

  // ----
  RSeparators := [',', '(', ')', ';', '[', ']', ':'];
  ROperators := ['+', '-', '*', '/', '<', '>', '=', ':'];
  RLangSymbols := ['A' .. 'Z', '0' .. '9', '_'];
  RSkipSymbols := [' ', #9];
end;

procedure TPasScanner.Next;
var
  I, j: Integer;
  State: TScannerState;

  procedure AssignLex(LexCode: TLexemCode; newCurRow, newCurCol: Integer);
  var ConvertError: Boolean;
  begin
    with RCurLexem do begin
      if LexCode = lcConstant then begin
        ConvertError := trystrtoint(Value, ValueInt);
        ConvertError := ConvertError or (not trystrtofloat(Value, ValueFloat));
        if not ConvertError then lexCode := lcError;
      end;
      Code := LexCode;
      Col := CurCol;
      Row := CurRow;
    end;
    CurRow := newCurRow;
    CurCol := newCurCol;
  end;

  procedure DoChecks(i, j: integer);
  begin
    if (IsOperation(RCurLexem.Value)) then AssignLex(lcOperation, I, j)
    else if (IsReservedWord(RCurLexem.Value)) then AssignLex(lcReservedWord, I, j)
    else if (IsIdentificator(RCurLexem.Value)) then AssignLex(lcIdentificator, I, j)
    else if (IsConstant(RCurLexem.Value)) and (RCurChar = ':') then AssignLex(lcLabel, I, j)
    else if (IsConstant(RCurLexem.Value)) then AssignLex(lcConstant, I, j)
    else if (Length(RCurLexem.Value) = 1) and (RCurLexem.Value[1] in RSeparators) then AssignLex(lcSeparator, I, j)
    else AssignLex(lcError, I, j);
  end;

begin
  ClearCurLexem;
  j := CurCol;
  I := CurRow;
  State := ssError;
  while not EOF(RFile) do begin
    if I <> CurRow then j := 1;
    if RCurLexem.Value <> '' then begin
      DoChecks(i, j);
      RReadNextChar := true;
      exit;
    end;
    while not EOln(RFile) do begin
      if RReadNextChar then read(RFile, RCurChar);
      RReadNextChar := true;
      if (RCurChar = '{') and (State <> ssInComment) then begin
        State := ssInComment;
        Inc(j);
        continue;
      end;

      if (RCurChar = '}') and (State = ssInComment) then begin
        State := ssError;
        Inc(j);
        continue;
      end;

      if (State = ssInComment) then begin
        inc(j);
        continue;
      end;

      if (RCurChar = '''') and (State <> ssInString) then begin
        State := ssInString;
        inc(j);
        continue;
      end;

      if (RCurChar = '''') and (State = ssInString) and
        ((RCurLexem.Value = '') or ((RCurLexem.Value[Length(RCurLexem.Value)] = '''') and (RCurChar <> ''''))) then begin
        if (RCurLexem.Value <> '') and (RCurLexem.Value[Length(RCurLexem.Value)] = '''') then
          Delete(RCurLexem.Value, length(RCurLexem.Value), 1);
        AssignLex(lcString, i, succ(j));
        exit;
      end;

      if (RCurLexem.Value = '/') and (RCurChar = '/') then begin
        RCurLexem.Value := '';
        break;
      end;

      if (RCurChar in RSeparators) and (RCurLexem.Value = '') then begin
        RCurLexem.Value := RCurChar;
        AssignLex(lcSeparator, i , j);
        exit;
      end;

      if (RCurChar in RSeparators) or ((RCurLexem.Value <> '') and (RCurChar in RSkipSymbols)) then begin
        DoChecks(i, j);
        RReadNextChar := false;
        exit;
      end;

      if not(RCurChar in RSkipSymbols) then RCurLexem.Value := RCurLexem.Value + RCurChar;
      Inc(j);
    end;
    readln(RFile);
    inc(i);
  end;
  REndOfScan := True;
  closefile(RFile);
end;

end.
