unit plScaner;

interface

uses
  System.SysUtils,
  System.Classes,
  plSearchTree;

type
  TLexemsInfo = record
    Identificators: Integer;
    Words: Integer;
    Constants: Integer;
    Labels: Integer;
    Operations: Integer;
    Separators: Integer;
    Errors: Integer;
    Total: Integer;
    Strings: Integer;
  end;

  TScaner = class
  private
    RReservedWords: array of string;
    ROperations: array of string;
    ROperators: set of char;
    RLangSymbols: set of char;
    RSeparators: set of char;
    RCodedProgram: String;
    RLexems: TLexemsInfo;
    function PrepareLine(S: String): String;
    function IsIdentifier(S: String): Boolean;
    function IsReservedWord(S: string): Boolean;
    function IsOperation(S: string): Boolean;
    function IsConstant(S: string): Boolean;
    procedure AddReservedWord(NewWord: String);
    procedure AddOperation(NewOpearation: string);
    procedure ClearLexems;
    procedure Init;
  public
    RCodeTree: TSearchTree;
    property CodedProgram: String read RCodedProgram;
    property Lexems: TLexemsInfo read RLexems;
    procedure AnalizeCode(Code: string);
    constructor Create(Code: string = '');
    procedure Free;
  end;

implementation

{ TScaner }

function TScaner.PrepareLine(S: String): String;
begin
  if Length(S) = 0 then Exit('');
  while S[1] = ' ' do Delete(S, 1, 1);
  while S[Length(S)] = ' ' do Delete(S, Length(S), 1);
  S := AnsiUpperCase(S);
  Result := S;
end;

function TScaner.IsConstant(S: string): Boolean;
var
  I, t: Integer;
  F: Boolean;
begin
  Result := True;
  t := 0;
  if (S[1] = '$') and (Length(S) > 1) then t := 1;
  for I := 1 + t to Length(S) do
    if not(S[I] in ['.', '0' .. '9']) then begin
      if (S[I] = '.') and (not F) then F := True
      else Result := False;
    end;
end;

function TScaner.IsIdentifier(S: String): Boolean;
var
  I: Integer;
begin
  Result := S[1] in ['A' .. 'Z'];
  if not Result then Exit(False);
  for I := 2 to Length(S) do
    if not(S[I] in ['0' .. '9', 'A' .. 'Z']) then Exit(False);
  Result := Result and (S <> 'AND') and (S <> 'OR') and (S <> 'NOT') and (S <> 'XOR');
end;

function TScaner.IsOperation(S: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(ROperations) do
    if ROperations[I] = S then Exit(True);
end;

function TScaner.IsReservedWord(S: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(RReservedWords) do
    if RReservedWords[I] = S then Exit(True);
end;

procedure TScaner.AddOperation(NewOpearation: string);
begin
  SetLength(ROperations, Length(ROperations) + 1);
  ROperations[High(ROperations)] := NewOpearation;
end;

procedure TScaner.AddReservedWord(NewWord: String);
begin
  SetLength(RReservedWords, Length(RReservedWords) + 1);
  RReservedWords[High(RReservedWords)] := NewWord;
end;

procedure TScaner.AnalizeCode(Code: string);
var
  CodeLines: TStringList;
  I, j: Integer;
  CurrLine: String;
  CurrChar: char;
  ErrorLex: Boolean;
  LocLexem: PItem;
  CurrLexem: TLexem;
begin
  RCodeTree.Clear;
  RCodedProgram := '';
  ClearLexems;
  CodeLines := TStringList.Create;
  CodeLines.Text := Code;
  for I := 0 to Pred(CodeLines.Count) do begin
    CurrLine := PrepareLine(CodeLines[I]);
    // конец программы END.
    { if Pos('END.', CurrLine) = 1 then begin
      CurrLexem.Code := lcReservedWord;
      Inc(RLexems.Constants);
      CurrLexem.CodeName := LexemCodeChar[Ord(CurrLexem.Code)] + IntToStr(RLexems.Constants);
      CurrLexem.Line := Succ(I);
      CurrLexem.Name := 'END';
      LocLexem := RCodeTree.Search(CurrLexem);
      RCodedProgram := RCodedProgram + LocLexem.Value.CodeName + ' ';
      break;
      end; }
    j := 1;
    while j <= Length(CurrLine) do begin
      CurrChar := CurrLine[j];
      // Встретилась строка
      if CurrChar = '''' then begin
        Inc(j);
        ErrorLex := False;
        repeat
          if CurrLine[j] = '''' then begin
            // Ошибка
            if j = Length(CurrLine) then begin
              ErrorLex := True;
              break;
            end;
            // Двойной апостроф
            if CurrLine[Succ(j)] = '''' then begin
              Inc(j, 2);
              Continue;
            end;
            // Закрывающий апостроф
            Inc(j);
            break;
          end;
          CurrLexem.Name := CurrLexem.Name + CurrLine[j];
          Inc(j);
        until False;
        if ErrorLex then begin
          // Ошибочная лексемма
          CurrLexem.Code := lcError;
          Inc(RLexems.Errors);
          CurrLexem.CodeName := LexemCodeChar[Ord(CurrLexem.Code)] + IntToStr(RLexems.Errors);
          LocLexem := RCodeTree.Search(CurrLexem);
          RCodedProgram := RCodedProgram + LocLexem.Value.CodeName + ' ';
        end else begin
          CurrLexem.Code := lcString;
          Inc(RLexems.Strings);
          CurrLexem.CodeName := LexemCodeChar[Ord(CurrLexem.Code)] + IntToStr(RLexems.Strings);
          CurrLexem.Line := Succ(I);
          LocLexem := RCodeTree.Search(CurrLexem);
          RCodedProgram := RCodedProgram + LocLexem.Value.CodeName + ' ';
        end;
        // Продолжить анализ последующего символа
        Continue;
      end;
      // Встретился символ-разделитель, операция или конец строки
      if (CurrChar = ' ') or (j = Length(CurrLine)) or (CurrChar in ROperators) or (CurrChar in RSeparators) then begin
        if (j = Length(CurrLine)) and (CurrChar <> ' ') and (not(CurrChar in ROperators)) and
          (not(CurrChar in RSeparators)) then CurrLexem.Name := CurrLexem.Name + CurrChar;
        if CurrLexem.Name <> '' then begin
          // Неправильная лексема
          ErrorLex := True;
          // Лексема раньше не встречалась
          LocLexem := RCodeTree.Locate(CurrLexem);
          if LocLexem = nil then begin
            // CurrLexem.Line := Succ(I);
            if IsReservedWord(CurrLexem.Name) and ErrorLex then begin
              CurrLexem.Code := lcReservedWord;
              Inc(RLexems.Words);
              CurrLexem.CodeName := LexemCodeChar[Ord(CurrLexem.Code)] + IntToStr(RLexems.Words);
              LocLexem := RCodeTree.Search(CurrLexem);
              RCodedProgram := RCodedProgram + LocLexem.Value.CodeName + ' ';
              ErrorLex := False;
            end;
            // Идентификатор
            if IsIdentifier(CurrLexem.Name) and ErrorLex then begin
              CurrLexem.Code := lcIdentifier;
              Inc(RLexems.Identificators);
              CurrLexem.CodeName := LexemCodeChar[Ord(CurrLexem.Code)] + IntToStr(RLexems.Identificators);
              LocLexem := RCodeTree.Search(CurrLexem);
              RCodedProgram := RCodedProgram + LocLexem.Value.CodeName + ' ';
              ErrorLex := False;
            end;
            // Метка
            if IsConstant(CurrLexem.Name) and ErrorLex and (CurrLine[j] = ':') then begin
              CurrLexem.Code := lcLabel;
              Inc(RLexems.Labels);
              CurrLexem.CodeName := LexemCodeChar[Ord(CurrLexem.Code)] + IntToStr(RLexems.Labels);
              LocLexem := RCodeTree.Search(CurrLexem);
              RCodedProgram := RCodedProgram + LocLexem.Value.CodeName + ' ';
              ErrorLex := False
            end;
            // Константа
            if IsConstant(CurrLexem.Name) and ErrorLex then begin
              CurrLexem.Code := lcConstant;
              Inc(RLexems.Constants);
              CurrLexem.CodeName := LexemCodeChar[Ord(CurrLexem.Code)] + IntToStr(RLexems.Constants);
              LocLexem := RCodeTree.Search(CurrLexem);
              RCodedProgram := RCodedProgram + LocLexem.Value.CodeName + ' ';
              ErrorLex := False;
            end;
            // Встретили операцию
            if IsOperation(CurrLexem.Name) and ErrorLex then begin
              CurrLexem.Code := lcOperation;
              Inc(RLexems.Operations);
              CurrLexem.CodeName := LexemCodeChar[Ord(CurrLexem.Code)] + IntToStr(RLexems.Operations);
              LocLexem := RCodeTree.Search(CurrLexem);
              RCodedProgram := RCodedProgram + LocLexem.Value.CodeName + ' ';
              ErrorLex := False;
            end;
            // Ошибочная лексемма
            if ErrorLex then begin
              CurrLexem.Code := lcError;
              Inc(RLexems.Errors);
              CurrLexem.CodeName := LexemCodeChar[Ord(CurrLexem.Code)] + IntToStr(RLexems.Errors);
              LocLexem := RCodeTree.Search(CurrLexem);
              RCodedProgram := RCodedProgram + LocLexem.Value.CodeName + ' ';
            end;
          end
          else RCodedProgram := RCodedProgram + LocLexem.Value.CodeName + ' ';
        end;
        // Определяем разделитель (Если есть)
        if (CurrChar in ROperators) or (CurrChar in RSeparators) then begin
          if j < Pred(Length(CurrLine)) then begin
            if IsOperation(CurrChar + CurrLine[Succ(j)]) then begin
              CurrLexem.Name := CurrChar + CurrLine[Succ(j)];
              Inc(j);
            end
            else CurrLexem.Name := CurrChar;
          end
          else CurrLexem.Name := CurrChar;
          LocLexem := RCodeTree.Locate(CurrLexem);
          // Встретили операцию
          if (IsOperation(CurrLexem.Name)) and (LocLexem = nil) then begin
            CurrLexem.Code := lcOperation;
            Inc(RLexems.Operations);
            CurrLexem.Line := Succ(I);
            CurrLexem.CodeName := LexemCodeChar[Ord(CurrLexem.Code)] + IntToStr(RLexems.Operations);
            LocLexem := RCodeTree.Search(CurrLexem);
          end;
          // Встретили разделитель
          if (CurrChar in RSeparators) and (LocLexem = nil) then begin
            CurrLexem.Code := lcSeparator;
            Inc(RLexems.Separators);
            CurrLexem.Line := Succ(I);
            CurrLexem.CodeName := LexemCodeChar[Ord(CurrLexem.Code)] + IntToStr(RLexems.Separators);
            LocLexem := RCodeTree.Search(CurrLexem);
          end;
          if (LocLexem.Value.Name = ':') and (CurrLine[Succ(j)] = '=') then
          else RCodedProgram := RCodedProgram + LocLexem.Value.CodeName + ' ';
        end;
        // Обнуляем информацию о текущей лексемме
        with CurrLexem do begin
          Name := '';
          Line := 0;
          Code := lcUnknown;
          CodeName := '';
        end;
      end
      else if CurrChar <> ' ' then CurrLexem.Name := CurrLexem.Name + CurrChar;
      Inc(j);
    end;
    RCodedProgram := RCodedProgram + #13#10;
  end;
end;

procedure TScaner.ClearLexems;
begin
  with RLexems do begin
    Identificators := 0;
    Words := 0;
    Constants := 0;
    Operations := 0;
    Separators := 0;
    Errors := 0;
    Total := 0;
    Strings := 0;
  end;
end;

constructor TScaner.Create(Code: string = '');
begin
  Init;
  if (Length(Code) > 0) then AnalizeCode(Code);
end;

procedure TScaner.Free;
begin
  RCodeTree.Clear;
  Destroy;
end;

procedure TScaner.Init;
begin
  RCodeTree := TSearchTree.Create;
  AddReservedWord('ARRAY');
  AddReservedWord('BEGIN');
  AddReservedWord('CASE');
  AddReservedWord('CONST');
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
  AddReservedWord('LABEL');
  AddReservedWord('MOD');
  AddReservedWord('NIL');
  AddReservedWord('NOT');
  AddReservedWord('OF');
  AddReservedWord('OR');
  AddReservedWord('PACKED');
  AddReservedWord('PROCEDURE');
  AddReservedWord('PROGRAM');
  AddReservedWord('RECORD');
  AddReservedWord('REPEAT');
  AddReservedWord('SET');
  AddReservedWord('THEN');
  AddReservedWord('TO');
  AddReservedWord('TYPE');
  AddReservedWord('UNTIL');
  AddReservedWord('VAR');
  AddReservedWord('WHILE');
  AddReservedWord('WITH');
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
  AddOperation('OR');
  AddOperation('XOR');
  AddOperation('NOT');
  AddOperation('AND');
  AddOperation('DIV');
  AddOperation('MOD');
  // ----
  RSeparators := [',', '(', ')', ':', ';'];
  ROperators := ['+', '-', '*', '/', '<', '>', '='];
  RLangSymbols := ['A' .. 'Z', '0' .. '9', '_'];
end;

end.
