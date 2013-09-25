unit pkScaner;

interface

uses
  System.SysUtils,
  System.Classes;

type
  TLexemCode = (lcUnknown, lcReservedWord, lcIdentificator, lcConstant, lcError, lcSeparator, lcLabel, lcOperation,
    lcString, lcComment);

  TLexem = record
    Code: TLexemCode;
    Value: String;
    ValueInt: longint;
    ValueFloat: extended;
    Row: LongInt;
    Col: LongInt;
  end;

  TLexemsCount = record
    ReserwedWords: LongInt;
    Identificators: LongInt;
    Constants: LongInt;
    Errors: LongInt;
    Separators: LongInt;
    Labels: LongInt;
    Operations: LongInt;
    Strings: LongInt;
    Comments: LongInt;
  end;

  TPasScaner = class
  private
    CurRow: LongInt;
    CurCol: LongInt;
    RCurLexem: TLexem;
    REndOfScan: Boolean;
    RFile: TextFile;
    RLexemsCount: TLexemsCount;
    RReservedWords: array of string;
    ROperations: array of string;
    ROperators: set of char;
    RLangSymbols: set of char;
    RSeparators: set of char;
    RReadNextChar: boolean;
    RCurChar: Char;
    procedure AddReservedWord(NewWord: String);
    procedure AddOperation(NewOpearation: string);
    procedure ClearLexemsCount;
    procedure Init;
    procedure ClearCurLexem;
    function IsIdentificator(S: String): Boolean;
    function IsReservedWord(S: string): Boolean;
    function IsOperation(S: string): Boolean;
    function IsConstant(S: string): Boolean;
  public
    property EndOfScan: Boolean read REndOfScan;
    property LexemsCount: TLexemsCount read RLexemsCount;
    property CurLexem: TLexem read RCurLexem;
    constructor Create; overload;
    constructor Create(FileName: string); overload;
    procedure LoadFromFile(FileName: string);
    procedure Free;
    procedure Next;
  end;

implementation

{ TPasScaner }

function TPasScaner.IsConstant(S: string): Boolean;
var
  I, t: Integer;
  F: Boolean;
begin
  if Length(S) = 0 then exit(false);
  Result := True;
  t := 0;
  if (S[1] = '$') and (Length(S) > 1) then t := 1;
  for I := 1 + t to Length(S) do
    if (S[I] in ['.', '0' .. '9']) then begin
      if (t = 1) and (S[I] = '.') then exit(false);
      if (S[I] = '.') and ((I = Length(S)) or (I = 1)) then exit(false);
    end
    else exit(false);
end;

function TPasScaner.IsIdentificator(S: String): Boolean;
var
  I: Integer;
begin
  if Length(S) = 0 then exit(false);
  Result := True;
  if not(S[1] in ['A' .. 'Z', 'a' .. 'z']) or (IsOperation(S)) then exit(false);
  for I := 2 to Length(S) do
    if not(S[I] in ['0' .. '9', 'A' .. 'Z', 'a' .. 'z']) then exit(false);
end;

function TPasScaner.IsOperation(S: string): Boolean;
var
  I: Integer;
begin
  Result := false;
  for I := 0 to High(ROperations) do
    if ROperations[I] = AnsiUpperCase(S) then exit(True);
end;

function TPasScaner.IsReservedWord(S: string): Boolean;
var
  I: Integer;
begin
  Result := false;
  for I := 0 to High(RReservedWords) do
    if RReservedWords[I] = AnsiUpperCase(S) then exit(True);
end;

procedure TPasScaner.LoadFromFile(FileName: string);
begin
  ClearLexemsCount;
  CurRow := 1;
  CurCol := 1;
  ClearCurLexem;
  RReadNextChar := true;
  REndOfScan := false;
  assign(RFile, FileName);
  reset(RFile);
end;

procedure TPasScaner.AddOperation(NewOpearation: string);
begin
  SetLength(ROperations, Length(ROperations) + 1);
  ROperations[High(ROperations)] := NewOpearation;
end;

procedure TPasScaner.AddReservedWord(NewWord: String);
begin
  SetLength(RReservedWords, Length(RReservedWords) + 1);
  RReservedWords[High(RReservedWords)] := NewWord;
end;

procedure TPasScaner.ClearCurLexem;
begin
  with RCurLexem do begin
    Code := lcUnknown;
    Value := '';
    Row := -1;
    Col := -1;
  end;
end;

procedure TPasScaner.ClearLexemsCount;
begin
  with RLexemsCount do begin
    Identificators := 0;
    ReserwedWords := 0;
    Constants := 0;
    Comments := 0;
    Operations := 0;
    Separators := 0;
    Errors := 0;
    Strings := 0;
  end;
end;

constructor TPasScaner.Create(FileName: string);
begin
  Create;
  LoadFromFile(FileName);
end;

constructor TPasScaner.Create;
begin
  Init;
end;

procedure TPasScaner.Free;
begin
  Destroy;
end;

procedure TPasScaner.Init;
begin
  AddReservedWord('ARRAY');
  AddReservedWord('BEGIN');
  AddReservedWord('CASE');
  AddReservedWord('CONST');
  AddReservedWord('CONSTRUCTOR');
  AddReservedWord('CLASS');
  AddReservedWord('DIV');
  AddReservedWord('DO');
  AddReservedWord('DOWNTO');
  AddReservedWord('ELSE');
  AddReservedWord('END');
  AddReservedWord('FILE');
  AddReservedWord('FOR');
  AddReservedWord('FUNCTION');
  AddReservedWord('GOTO');
  AddReservedWord('IF');
  AddReservedWord('IN');
  AddReservedWord('INTERFACE');
  AddReservedWord('IMPLEMENTATION');
  AddReservedWord('LABEL');
  AddReservedWord('MOD');
  AddReservedWord('NIL');
  AddReservedWord('NOT');
  AddReservedWord('OF');
  AddReservedWord('OR');
  AddReservedWord('PACKED');
  AddReservedWord('PROCEDURE');
  AddReservedWord('PROGRAM');
  AddReservedWord('PRIVATE');
  AddReservedWord('PUBLIC');
  AddReservedWord('RECORD');
  AddReservedWord('REPEAT');
  AddReservedWord('SET');
  AddReservedWord('THEN');
  AddReservedWord('TO');
  AddReservedWord('TYPE');
  AddReservedWord('UNTIL');
  AddReservedWord('USES');
  AddReservedWord('VAR');
  AddReservedWord('WHILE');
  AddReservedWord('WITH');
  AddReservedWord('OR');
  AddReservedWord('XOR');
  AddReservedWord('NOT');
  AddReservedWord('AND');
  AddReservedWord('DIV');
  AddReservedWord('MOD');
  // ----
  AddOperation('+');
  AddOperation('-');
  AddOperation('*');
  AddOperation('/');
  AddOperation('<');
  AddOperation('>');
  AddOperation('<=');
  AddOperation('>=');
  AddOperation(':=');
  AddOperation('=');
  AddOperation('<>');
  // ----
  RSeparators := [',', '(', ')', ';', '[', ']', ':'];
  ROperators := ['+', '-', '*', '/', '<', '>', '=', ':'];
  RLangSymbols := ['A' .. 'Z', '0' .. '9', '_'];
end;

procedure TPasScaner.Next;
var
  I, j: Integer;
  inString: Boolean;
  inOperation: Boolean;
  inOneLineComment, inMultiLineComment: Boolean;
  ErrorLex: Boolean;

  procedure AssignLex(LexCode: TLexemCode; newCurRow, newCurCol: Integer);
  var ConvertError: Boolean;
  begin
    ErrorLex := false;
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

  procedure AddAndInc;
  begin
    RCurLexem.Value := RCurLexem.Value + RCurChar;
    Inc(j);
  end;

  procedure DoChecks;
  begin
    ErrorLex := True;

    if ErrorLex and (IsOperation(RCurLexem.Value)) then AssignLex(lcOperation, I, j);
    if ErrorLex and (IsReservedWord(RCurLexem.Value)) then AssignLex(lcReservedWord, I, j);
    if ErrorLex and (IsIdentificator(RCurLexem.Value)) then AssignLex(lcIdentificator, I, j);
    if ErrorLex and (IsConstant(RCurLexem.Value)) and (RCurChar = ':') then AssignLex(lcLabel, I, j);
    if ErrorLex and (IsConstant(RCurLexem.Value)) then AssignLex(lcConstant, I, j);
    if ErrorLex and (Length(RCurLexem.Value) = 1) and (RCurLexem.Value[1] in RSeparators) then
      AssignLex(lcSeparator, I, j);
    if ErrorLex then AssignLex(lcError, I, j);
  end;

  function DoOnNewLineChecks:boolean;
  begin
    Result := true;
    if inOneLineComment then begin
      AssignLex(lcComment, I, j);
      exit(false);
    end;
    if inString then begin
      AssignLex(lcError, I, j);
      exit(false);
    end;
    if not(inMultiLineComment) and (RCurLexem.Value <> '') then begin
      DoChecks;
      exit(false);
    end;
  end;

begin
  ClearCurLexem;
  j := CurCol;
  I := CurRow;
  inMultiLineComment := false;
  inOneLineComment := false;
  inString := false;
  inOperation := false;
  ErrorLex := false;
  while not EOF(RFile) do begin
    if I <> CurRow then j := 1;
    if not DoOnNewLineChecks then exit;
    inOneLineComment := false;
    while not EOln(RFile) do begin
      if RReadNextChar then read(RFile, RCurChar);
      RReadNextChar := true;
      if inOneLineComment then begin
        AddAndInc;
        continue;
      end;

      if inMultiLineComment and (RCurChar <> '}') then begin
        AddAndInc;
        continue;
      end;

      if inMultiLineComment and (RCurChar = '}') then begin
        AssignLex(lcComment, I, Succ(j));
        exit;
      end;

      if inString and (RCurChar <> '''') then begin
        AddAndInc;
        continue;
      end;

      if inString and (RCurChar = '''') then begin
        AssignLex(lcString, I, Succ(j));
        exit;
      end;

      if (RCurChar = '{') and (RCurLexem.Value = '') then begin
        inMultiLineComment := True;
        CurCol := j;
        CurRow := I;
        Inc(j);
        continue;
      end;

      if (RCurChar = '/') and (Length(RCurLexem.Value) = 1) and
      (RCurLexem.Value[1] = '/') then begin
        inOneLineComment := true;
        CurRow := I;
        CurCol := Pred(j);
        RCurLexem.Value := '';
        inc(j);
        continue;
      end;

      if inOperation and not (RCurChar in ROperators) then begin
        RReadNextChar := false;
        DoChecks;
        exit;
      end;

      if RCurChar = '''' then begin
        inString := True;
        CurCol := j;
        CurRow := I;
        Inc(j);
        continue;
      end;

      if (RCurLexem.Value = '') and (RCurChar in RSeparators) and (RCurChar <> ':') then begin
        RCurLexem.Value := RCurChar;
        AssignLex(lcSeparator, I, Succ(j));
        exit;
      end;

      if (AnsiUpperCase(CurLexem.Value) = 'END') and (RCurChar = '.') then begin
        AssignLex(lcReservedWord, I, Succ(j));
        exit;
      end;

      if (RCurLexem.Value = ':') and not(RCurChar in ROperators) then begin
        AssignLex(lcSeparator, I, j);
        exit;
      end;

      if (RCurChar in ROperators) then begin
        if (not inOperation) and (RCurLexem.Value <> '') then begin
          RReadNextChar := false;
          DoChecks;
          exit;
        end;
        inOperation := True;
      end
      else
        inOperation := false;

      if inOperation and ((Length(RCurLexem.Value) = 1)) then begin
        if RCurChar = ':' then begin
          RReadNextChar := false;
          DoChecks;
          exit;
        end;
        RCurLexem.Value := RCurLexem.Value + RCurChar;
        Inc(j);
        DoChecks;
        exit;
      end;

      if (RCurLexem.Value <> '') and ((RCurChar in RSeparators) or (RCurChar in ['{',' '])) then begin
        RReadNextChar := false;
        DoChecks;
        exit;
      end;

      if inMultiLineComment or inOneLineComment or inString then RCurLexem.Value := RCurLexem.Value + RCurChar;

      if not(inOneLineComment) and (not inMultiLineComment) and (not inString) and not(RCurChar in [' ', #9])
      then begin
        if RCurLexem.Value = '' then begin
          CurRow := I;
          CurCol := j;
        end;
        RCurLexem.Value := RCurLexem.Value + RCurChar;
      end;
      Inc(j);
    end;
    readln(RFile);
    inc(i);
  end;
  Dec(i);
  if not RReadNextChar then RCurLexem.Value := RCurLexem.Value + RCurChar;
  DoOnNewLineChecks;
  REndOfScan := True;
  closefile(RFile);
end;

end.
