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
    REOF: Boolean;
    RLexemsCount: TLexemsCount;
    RReservedWords: array of string;
    ROperations: array of string;
    ROperators: set of char;
    RLangSymbols: set of char;
    RSeparators: set of char;
    RSourceCode: TStringList;
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
    property EOF: Boolean read REOF;
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
var
  I: Integer;
begin
  ClearLexemsCount;
  CurRow := 1;
  CurCol := 1;
  ClearCurLexem;
  REOF := false;
  RSourceCode.Clear;
  RSourceCode.LoadFromFile(FileName);
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
  RSourceCode.Free;
  Destroy;
end;

procedure TPasScaner.Init;
begin
  RSourceCode := TStringList.Create;
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
  CurLine: String;
  inString: Boolean;
  inOperation: Boolean;
  inOneLineComment, inMultiLineComment: Boolean;
  ErrorLex: Boolean;
  procedure AssignLex(LexCode: TLexemCode; newCurRow, newCurCol: Integer);
  begin
    with RCurLexem do begin
      Code := LexCode;
      Col := CurCol;
      Row := CurRow;
    end;
    CurRow := newCurRow;
    CurCol := newCurCol;
    ErrorLex := false;
  end;

  procedure AddAndInc;
  begin
    RCurLexem.Value := RCurLexem.Value + RSourceCode[I][j];
    Inc(j);
  end;

  procedure DoChecks;
  begin
    ErrorLex := True;

    if ErrorLex and (IsOperation(RCurLexem.Value)) then AssignLex(lcOperation, Succ(I), j);
    if ErrorLex and (IsReservedWord(RCurLexem.Value)) then AssignLex(lcReservedWord, Succ(I), j);
    if ErrorLex and (IsIdentificator(RCurLexem.Value)) then AssignLex(lcIdentificator, Succ(I), j);
    if ErrorLex and (IsConstant(RCurLexem.Value)) and (RSourceCode[I][j] = ':') then AssignLex(lcLabel, Succ(I), j);
    if ErrorLex and (IsConstant(RCurLexem.Value)) then AssignLex(lcConstant, Succ(I), j);

    if ErrorLex then AssignLex(lcError, Succ(I), j);
  end;

begin
  ClearCurLexem;
  j := CurCol;
  inMultiLineComment := false;
  inOneLineComment := false;
  inString := false;
  ErrorLex := false;
  for I := Pred(CurRow) to Pred(RSourceCode.Count) do begin
    if I <> Pred(CurRow) then j := 1;
    if inOneLineComment then begin
      AssignLex(lcComment, Succ(I), j);
      exit;
    end;
    if inString then begin
      AssignLex(lcError, Succ(I), j);
      exit;
    end;
    if not(inMultiLineComment) and (RCurLexem.Value <> '') then begin
      DoChecks;
      exit;
    end;
    inOneLineComment := false;
    while j <= Length(RSourceCode[I]) do begin

      if inOneLineComment then begin
        AddAndInc;
        continue;
      end;

      if inMultiLineComment and (RSourceCode[I][j] <> '}') then begin
        AddAndInc;
        continue;
      end;

      if inMultiLineComment and (RSourceCode[I][j] = '}') then begin
        AssignLex(lcComment, Succ(I), Succ(j));
        exit;
      end;

      if inString and (RSourceCode[I][j] <> '''') then begin
        AddAndInc;
        continue;
      end;

      if inString and (RSourceCode[I][j] = '''') then begin
        AssignLex(lcString, Succ(I), Succ(j));
        exit;
      end;

      if RSourceCode[I][j] = '{' then begin
        inMultiLineComment := True;
        CurCol := j;
        CurRow := Succ(I);
        Inc(j);
        continue;
      end;

      if RSourceCode[I][j] = '''' then begin
        inString := True;
        CurCol := j;
        CurRow := Succ(I);
        Inc(j);
        continue;
      end;

      if (j < Length(RSourceCode[I])) and ((RSourceCode[I][j] + RSourceCode[I][j + 1]) = '//') then begin
        inOneLineComment := True;
        CurCol := j;
        CurRow := Succ(I);
        Inc(j, 2);
        continue;
      end;

      if (RCurLexem.Value = '') and (RSourceCode[I][j] in RSeparators) and (RSourceCode[I][j] <> ':') then begin
        RCurLexem.Value := RSourceCode[I][j];
        AssignLex(lcSeparator, Succ(I), Succ(j));
        exit;
      end;

      if (AnsiUpperCase(CurLexem.Value) = 'END') and (RSourceCode[I][j] = '.') then begin
        AssignLex(lcReservedWord, Succ(I), Succ(j));
        REOF := True;
        exit;
      end;

      if inOperation and not(RSourceCode[I][j] in ROperators) then begin
        DoChecks;
        exit;
      end;

      if (RSourceCode[I][j] in ROperators) then begin
        if (not inOperation) and (RCurLexem.Value <> '') then begin
          DoChecks;
          exit;
        end;
        inOperation := True;
      end
      else inOperation := false;

      if inOperation and ((Length(RCurLexem.Value) = 1)) then begin
        RCurLexem.Value := RCurLexem.Value + RSourceCode[I][j];
        Inc(j);
        DoChecks;
        exit;
      end;

      if (RCurLexem.Value <> '') and ((RSourceCode[I][j] in RSeparators) or (RSourceCode[I][j] = ' ')) then begin
        DoChecks;
        exit;
      end;

      if inMultiLineComment or inOneLineComment or inString then RCurLexem.Value := RCurLexem.Value + RSourceCode[I][j];

      if not(inOneLineComment) and (not inMultiLineComment) and (not inString) and not(RSourceCode[I][j] in [' ', #9])
      then begin
        if RCurLexem.Value = '' then begin
          CurRow := Succ(I);
          CurCol := j;
        end;
        RCurLexem.Value := RCurLexem.Value + RSourceCode[I][j];
      end;

      Inc(j);
    end;
  end;
  DoChecks;
  REOF := True;
end;

end.
