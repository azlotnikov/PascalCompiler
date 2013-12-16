UNIT pkScanner;

INTERFACE

USES
  System.SysUtils,
  Generics.Collections,
  RegularExpressions;

TYPE
  TLexemCode = (lcUnknown, lcReservedWord, lcIdentificator, lcInteger, lcFloat, lcError, lcSeparator, lcOperation,
    lcChar, lcString, lcLabel);

  TScanerState = (ssNone, ssInComment, ssInString, ssInStringQuote, ssInOperation, ssInInt, ssInHex, ssInFloat,
    ssInIdentificator, ssDoChecks, ssInStringEnd, ssInSeparator, ssError);

  TOperationType = (ptAdd, ptSub, ptMult, ptDiv, ptIntDiv, ptMod, ptLess, ptGreater, ptLessEq, ptGreaterEq, ptAssign,
    ptEq, ptNotEq, ptPointer1, ptPointer2, ptXOR, ptNOT, ptAND, ptOR, ptSHL, ptSHR, { } ptNone, ptUnAdd, ptUnSub);

  TReserwedWordType = (rwArray, { } rwNone);

  TLexem = RECORD
    ValueStr: STRING;
    Row: Integer;
    Col: Integer;
    ValueReserwedWord: TReserwedWordType;
    ValueSeparator: Char;
    ValueChar: Char;
    ValueInt: Integer;
    ValueOperation: TOperationType;
    ValueFloat: Extended;
    Code: TLexemCode;
    FUNCTION PrintLexem: STRING;
    // case Code: TLexemCode of
    // lcReservedWord: (ValueReserwedWord: TReserwedWordType);
    // lcSeparator: (ValueSeparator: Char);
    // lcChar: (ValueChar: Char);
    // lcInteger: (ValueInt: Integer);
    // lcOperation: (ValueOperation: TOperationType);
    // lcFloat: (ValueFloat: Extended);
  END;

  TScanner = CLASS
  PRIVATE
    RCurRow         : LongInt;
    RCurCol         : LongInt;
    RCurLexem       : TLexem;
    REndOfScan      : Boolean;
    RFile           : TextFile;
    RReservedWords  : TList<STRING>;
    ROperations     : TList<STRING>;
    ROperators      : SET OF Char;
    RLangSymbols    : SET OF Char;
    RSeparators     : SET OF Char;
    RSkipSymbols    : SET OF Char;
    RPointersSymbols: SET OF Char;
    RReadNextChar   : Boolean;
    RExceptions     : Boolean;
    RCurChar        : Char;
    PROCEDURE Init;
    PROCEDURE ClearCurLexem;
    FUNCTION IsIdentificator(S: STRING): Boolean;
    FUNCTION IsReservedWord(S: STRING): Boolean;
    FUNCTION IsOperation(S: STRING): Boolean;
    FUNCTION IsHex(S: STRING): Boolean;
    FUNCTION IsInteger(S: STRING): Boolean;
    FUNCTION IsFloat(S: STRING): Boolean;
    FUNCTION IsChar(S: STRING): Boolean;
  PUBLIC
    PROPERTY EndOfScan: Boolean
      READ   REndOfScan;
    PROPERTY CurLexem: TLexem
      READ   RCurLexem;
    PROCEDURE StartFileScan(FileName: STRING);
    FUNCTION Next: Boolean;
    CONSTRUCTOR Create(AExceprtions: Boolean = true);
    DESTRUCTOR Free;
  END;

TYPE
  TSyntaxException = CLASS(Exception)
  PUBLIC
    CONSTRUCTOR Create(Msg: STRING; Lexem: TLexem);
  END;

IMPLEMENTATION

CONST
  EXCEPTION_FORMAT = '%s (Row: %d; Col: %d; Value: %s)';

  { TSyntaxException }

CONSTRUCTOR TSyntaxException.Create(Msg: STRING; Lexem: TLexem);
BEGIN
  INHERITED Create(Format(EXCEPTION_FORMAT, [Msg, Lexem.Row, Lexem.Col, Lexem.ValueStr]));
END;

{ TLexem }

FUNCTION TLexem.PrintLexem: STRING;
BEGIN
  Exit(ValueStr);
  CASE Code OF
    lcChar:
      Result := ValueChar;
    lcInteger:
      Result := IntToStr(ValueInt);
    lcFloat:
      FloatToStr(ValueFloat);
  ELSE
    Result := ValueStr;
  END;
END;

{ TPasScaner }

FUNCTION TScanner.IsChar(S: STRING): Boolean;
VAR
  i: Integer;
BEGIN
  Result := true;
  IF Length(S) < 2 THEN
    Exit(false);
  IF S[1] <> '#' THEN
    Exit(false);
  FOR i := 2 TO Length(S) DO
    IF NOT(S[i] IN ['0' .. '9']) THEN
      Exit(false);
END;

FUNCTION TScanner.IsFloat(S: STRING): Boolean;
VAR
  RegEx: TRegEx;
BEGIN
  Result := RegEx.IsMatch(S, '^[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$');
END;

FUNCTION TScanner.IsHex(S: STRING): Boolean;
VAR
  RegEx: TRegEx;
BEGIN
  Result := RegEx.IsMatch(S, '^\$[0-9a-fA-F]+$');
END;

FUNCTION TScanner.IsIdentificator(S: STRING): Boolean;
VAR
  RegEx: TRegEx;
BEGIN
  Result := RegEx.IsMatch(S, '^[^\d\W]\w*\Z$');
END;

FUNCTION TScanner.IsInteger(S: STRING): Boolean;
VAR
  RegEx: TRegEx;
BEGIN
  Result := RegEx.IsMatch(S, '^(?<![-.])\b[0-9]+\b(?!\.[0-9])$');
END;

FUNCTION TScanner.IsOperation(S: STRING): Boolean;
BEGIN
  Exit(ROperations.Contains(AnsiUpperCase(S)));
END;

FUNCTION TScanner.IsReservedWord(S: STRING): Boolean;
BEGIN
  Exit(RReservedWords.Contains(AnsiUpperCase(S)));
END;

PROCEDURE TScanner.StartFileScan(FileName: STRING);
BEGIN
  RCurRow := 1;
  RCurCol := 1;
  ClearCurLexem;
  RReadNextChar := true;
  REndOfScan    := false;
  assign(RFile, FileName);
  reset(RFile);
END;

PROCEDURE TScanner.ClearCurLexem;
BEGIN
  WITH RCurLexem DO
  BEGIN
    Code     := lcUnknown;
    ValueStr := '';
    Row      := -1;
    Col      := -1;
  END;
END;

CONSTRUCTOR TScanner.Create(AExceprtions: Boolean = true);
BEGIN
  RExceptions := AExceprtions;
  Init;
END;

DESTRUCTOR TScanner.Free;
BEGIN
  RReservedWords.Free;
  ROperations.Free;
END;

PROCEDURE TScanner.Init;
BEGIN
  RReservedWords := TList<STRING>.Create;
  WITH RReservedWords DO
  BEGIN
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
  END;
  // ----
  ROperations := TList<STRING>.Create;
  WITH ROperations DO
  BEGIN
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
  END;
  // ----
  RSeparators      := [',', '(', ')', ';', '[', ']', ':'];
  ROperators       := ['+', '-', '*', '/', '<', '>', '=', ':'];
  RPointersSymbols := ['@', '^'];
  RLangSymbols     := ['A' .. 'Z', '0' .. '9', '_'];
  RSkipSymbols     := [' ', #9];
END;

FUNCTION TScanner.Next: Boolean;
VAR
  i, j            : Integer;
  State, PrevState: TScanerState;
  LAssign         : Boolean;

  PROCEDURE AssignLex(LexCode: TLexemCode; newCurRow, newCurCol: Integer);
  BEGIN
    LAssign := true;
    WITH RCurLexem DO
    BEGIN
      Col     := RCurCol;
      Row     := RCurRow;
      RCurRow := newCurRow;
      RCurCol := newCurCol;
      IF LexCode = lcInteger THEN
      BEGIN
        IF NOT(trystrtoint(ValueStr, ValueInt)) THEN
        BEGIN
          LexCode := lcError;
          IF RExceptions THEN
            RAISE TSyntaxException.Create('Integer overflow', RCurLexem);
        END;
      END;
      IF LexCode = lcFloat THEN
      BEGIN
        IF (trystrtofloat(ValueStr, ValueFloat)) THEN
        BEGIN
          LexCode := lcError;
          IF RExceptions THEN
            RAISE TSyntaxException.Create('Float overflow', RCurLexem);
        END;
      END;
      IF (LexCode = lcString) AND (Length(ValueStr) = 1) THEN
      BEGIN
        ValueChar := ValueStr[1];
        LexCode   := lcChar;
      END;
      IF (LexCode = lcOperation) THEN
        ValueOperation := TOperationType(ROperations.IndexOf(ValueStr))
      ELSE
        ValueOperation := ptNone;
      IF (LexCode = lcReservedWord) THEN
        ValueReserwedWord := TReserwedWordType(RReservedWords.IndexOf(ValueStr))
      ELSE
        ValueReserwedWord := rwNone;
      IF (LexCode = lcSeparator) THEN
        ValueSeparator := ValueStr[1]
      ELSE
        ValueSeparator := #0;

      Code := LexCode;
    END;
  END;

  PROCEDURE DoChecks(LState: TScanerState; i, j: Integer);
  BEGIN
    LAssign := false;
    CASE LState OF
      ssInOperation:
        IF IsOperation(RCurLexem.ValueStr) THEN
          AssignLex(lcOperation, i, j)
        ELSE
        BEGIN
          AssignLex(lcError, i, j);
          IF RExceptions THEN
            RAISE TSyntaxException.Create('Error Operation', RCurLexem);
        END;
      ssInInt:
        IF IsInteger(RCurLexem.ValueStr) THEN
          AssignLex(lcInteger, i, j)
        ELSE
        BEGIN
          AssignLex(lcError, i, j);
          IF RExceptions THEN
            RAISE TSyntaxException.Create('Error Integer', RCurLexem);
        END;
      ssInHex:
        IF IsHex(RCurLexem.ValueStr) THEN
          AssignLex(lcInteger, i, j)
        ELSE
        BEGIN
          AssignLex(lcError, i, j);
          IF RExceptions THEN
            RAISE TSyntaxException.Create('Error Hex', RCurLexem);
        END;
      ssInFloat:
        IF IsFloat(RCurLexem.ValueStr) THEN
          AssignLex(lcFloat, i, j)
        ELSE
        BEGIN
          AssignLex(lcError, i, j);
          IF RExceptions THEN
            RAISE TSyntaxException.Create('Error Float', RCurLexem);
        END;
      ssInIdentificator:
        BEGIN
          IF IsOperation(RCurLexem.ValueStr) THEN
            AssignLex(lcOperation, i, j)
          ELSE IF IsReservedWord(RCurLexem.ValueStr) THEN
            AssignLex(lcReservedWord, i, j)
          ELSE IF IsIdentificator(RCurLexem.ValueStr) THEN
            AssignLex(lcIdentificator, i, j)
          ELSE
          BEGIN
            AssignLex(lcError, i, j);
            IF RExceptions THEN
              RAISE TSyntaxException.Create('Error Identificator', RCurLexem);
          END;
        END;
      ssInSeparator:
        IF (Length(RCurLexem.ValueStr) = 1) AND (RCurLexem.ValueStr[1] IN RSeparators) THEN
          AssignLex(lcSeparator, i, j)
        ELSE
        BEGIN
          AssignLex(lcError, i, j);
          IF RExceptions THEN
            RAISE TSyntaxException.Create('Error Separator', RCurLexem);
        END;
      ssError:
        BEGIN
          AssignLex(lcError, i, j);
          IF RExceptions THEN
            RAISE TSyntaxException.Create('Unknown Error', RCurLexem);
        END;
    END;

    IF NOT LAssign THEN
    BEGIN
      AssignLex(lcError, i, j);
      IF RExceptions THEN
        RAISE TSyntaxException.Create('Unknown Error', RCurLexem);
    END;
  END;

  FUNCTION UpdateState(C: Char): TScanerState;
  BEGIN
    Result := State;
    // Коммент открывается
    IF (C = '{') AND NOT(State IN [ssInComment, ssInString]) AND (RCurLexem.ValueStr <> '') THEN
      Exit(ssDoChecks);
    IF (C = '{') AND NOT(State IN [ssInComment, ssInString]) THEN
      Exit(ssInComment);
    // Коммент закрывается
    IF (C = '}') AND (State = ssInComment) THEN
      Exit(ssNone);
    // строка открывается
    IF (C = '''') AND NOT(State IN [ssInString, ssInStringQuote]) AND (RCurLexem.ValueStr <> '') THEN
      Exit(ssDoChecks);
    IF (C = '''') AND NOT(State IN [ssInString, ssInStringQuote]) THEN
      Exit(ssInString);
    // строка закрывается
    IF (C <> '''') AND (State = ssInStringQuote) THEN
      Exit(ssInStringEnd);
    // кавычка в строке
    IF (C = '''') AND (State = ssInString) THEN
      Exit(ssInStringQuote);
    // двойная кавычка
    IF (C = '''') AND (State = ssInStringQuote) THEN
      Exit(ssInString);
    IF (State IN [ssInString, ssInStringQuote, ssInComment]) THEN
      Exit;
    // начало целого числа
    IF (C IN ['0' .. '9', 'e', 'E']) AND (State = ssNone) THEN
      Exit(ssInInt);
    // число с e
    IF (C = '-') AND ((Pos('e', RCurLexem.ValueStr) > 0) OR (Pos('E', RCurLexem.ValueStr) > 0)) AND
      (State IN [ssInFloat, ssInInt]) THEN
      Exit;
    // переход из целого в дробное
    IF (C = '.') AND (State = ssInInt) THEN
      Exit(ssInFloat);
    // встретили разделитель при непустйо лексмеме
    IF (C IN RSeparators + RPointersSymbols) AND (RCurLexem.ValueStr <> '') THEN
      Exit(ssDoChecks);
    // встретили разделитель при пусой лексеме
    IF (C IN RSeparators) THEN
      Exit(ssInSeparator);
    // встретили @ или ^ при пусой лексеме
    IF (C IN RPointersSymbols) THEN
      Exit(ssInOperation);
    // начали операцию
    IF (C IN ROperators) AND (State <> ssInOperation) AND (RCurLexem.ValueStr = '') THEN
      Exit(ssInOperation);
    // продолжили операцию
    IF (C IN ROperators) AND (State = ssInOperation) THEN
      Exit;
    // закончили операцию
    IF NOT(C IN ROperators) AND (State = ssInOperation) THEN
      Exit(ssDoChecks);
    // начало идентификатора
    IF (C IN ['a' .. 'z', 'A' .. 'Z', '_']) AND (State = ssNone) THEN
      Exit(ssInIdentificator);
    // начало HEX числа
    IF (C = '$') AND (State = ssNone) THEN
      Exit(ssInHex);
    // встретили любой разделитель (проблел и т д) при непустой лексеме
    IF (C IN RSkipSymbols + RSeparators + RPointersSymbols + ROperators + ['#']) AND
      NOT(State IN [ssInString, ssInStringQuote, ssInComment]) AND (RCurLexem.ValueStr <> '') THEN
      Exit(ssDoChecks);
    // ошибка идентификатора
    IF NOT(C IN ['a' .. 'z', 'A' .. 'Z', '_', '0' .. '9']) AND (State = ssInIdentificator) THEN
      Exit(ssError);
  END;

BEGIN
  IF REndOfScan THEN
    Exit(false);
  Result := true;
  ClearCurLexem;
  j         := RCurCol;
  i         := RCurRow;
  State     := ssNone;
  PrevState := ssNone;
  IF EOF(RFile) AND (RReadNextChar = false) THEN
  BEGIN
    RCurLexem.ValueStr := RCurChar;
    State              := UpdateState(RCurChar);
    DoChecks(State, i, j);
  END;
  WHILE NOT EOF(RFile) DO
  BEGIN
    IF i <> RCurRow THEN
      j := 1;
    IF State = ssInString THEN
    BEGIN
      AssignLex(lcError, i, j);
      IF RExceptions THEN
        RAISE TSyntaxException.Create('Error String', RCurLexem);
      Exit;
    END;
    IF (RCurLexem.ValueStr <> '') AND (State <> ssInComment) THEN
    BEGIN
      DoChecks(State, i, j);
      RReadNextChar := true;
      Exit;
    END;
    WHILE NOT EOln(RFile) DO
    BEGIN
      IF RReadNextChar THEN
        READ(RFile, RCurChar);
      RReadNextChar := true;

      PrevState := State;
      State     := UpdateState(RCurChar);

      CASE State OF
        ssNone:
          ;
        ssInComment:
          ;
        ssInString:
          ;
        ssInInt:
          ;
        ssInFloat:
          ;
        ssInStringQuote:
          ;
        ssInStringEnd:
          BEGIN
            AssignLex(lcString, i, j);
            RReadNextChar := false;
            Exit;
          END;
        ssInSeparator:
          BEGIN
            RCurLexem.ValueStr := RCurChar;
            AssignLex(lcSeparator, i, j);
            Exit;
          END;
        ssDoChecks:
          BEGIN
            DoChecks(PrevState, i, j);
            RReadNextChar := false;
            Exit;
          END;
        ssError:
          BEGIN
            AssignLex(lcError, i, j);
            IF RExceptions THEN
            BEGIN
              CASE PrevState OF
                ssNone:
                  RAISE TSyntaxException.Create('Unknown Error', RCurLexem);
                ssInComment:
                  RAISE TSyntaxException.Create('Error Comment', RCurLexem);
                ssInString:
                  RAISE TSyntaxException.Create('Error String', RCurLexem);
                ssInStringQuote:
                  RAISE TSyntaxException.Create('Error String', RCurLexem);
                ssInOperation:
                  RAISE TSyntaxException.Create('Error Operation', RCurLexem);
                ssInInt:
                  RAISE TSyntaxException.Create('Error Integer', RCurLexem);
                ssInHex:
                  RAISE TSyntaxException.Create('Error Hex', RCurLexem);
                ssInFloat:
                  RAISE TSyntaxException.Create('Error Float', RCurLexem);
                ssInIdentificator:
                  RAISE TSyntaxException.Create('Error Identificator', RCurLexem);
                ssDoChecks:
                  RAISE TSyntaxException.Create('Unknown Error', RCurLexem);
                ssInStringEnd:
                  RAISE TSyntaxException.Create('Error String', RCurLexem);
                ssInSeparator:
                  RAISE TSyntaxException.Create('Error Sepataror', RCurLexem);
                ssError:
                  RAISE TSyntaxException.Create('Unknown Error', RCurLexem);
              END;
            END;
          END;
      END;
      IF (AnsiUpperCase(CurLexem.ValueStr) = 'END') AND (RCurChar = '.') THEN
      BEGIN
        AssignLex(lcReservedWord, i, Succ(j));
        RReadNextChar := false;
        REndOfScan    := true;
        Exit;
      END;

      IF (RCurLexem.ValueStr = '/') AND (RCurChar = '/') THEN
      BEGIN
        RCurLexem.ValueStr := '';
        State              := ssNone;
        break;
      END;

      IF NOT(RCurChar IN RSkipSymbols) OR (State IN [ssInString, ssInStringQuote]) THEN
        IF NOT(State IN [ssInComment, ssNone]) THEN
          RCurLexem.ValueStr := RCurLexem.ValueStr + RCurChar;
      Inc(j);
    END;
    readln(RFile);
    Inc(i);
  END;
  IF State = ssInStringQuote THEN
    AssignLex(lcString, i, j)
  ELSE IF RCurLexem.ValueStr <> '' THEN
    DoChecks(State, i, j)
  ELSE
    Result   := false;
  REndOfScan := true;
  closefile(RFile);
END;

END.
