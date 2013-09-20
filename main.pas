unit main;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  SynEditHighlighter,
  SynHighlighterPas,
  SynEdit,
  SynMemo,
  SynEditPopupEdit,
  Vcl.Menus,
  viewtable,
  viewcode,
  plSearchTree,
  plScaner,
  sSkinManager;

type
  TFMain = class(TForm)
    SynHighLighter: TSynPasSyn;
    MM: TMainMenu;
    MM_Menu: TMenuItem;
    CodeEditor: TSynEdit;
    MM_Analize: TMenuItem;
    MM_DoAnalize: TMenuItem;
    MM_LexemsCodeTable: TMenuItem;
    MM_Sep1: TMenuItem;
    MM_CodedProgram: TMenuItem;
    MM_Sep2: TMenuItem;
    MM_Consts: TMenuItem;
    MM_ReservedWords: TMenuItem;
    MM_Identificators: TMenuItem;
    MM_Separators: TMenuItem;
    MM_Labels: TMenuItem;
    MM_Operations: TMenuItem;
    MM_Errors: TMenuItem;
    MM_Strings: TMenuItem;
    Skin: TsSkinManager;
    procedure MM_DoAnalizeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MM_LexemsCodeTableClick(Sender: TObject);
    procedure MM_ConstsClick(Sender: TObject);
    procedure MM_ReservedWordsClick(Sender: TObject);
    procedure MM_CodedProgramClick(Sender: TObject);
    procedure MM_IdentificatorsClick(Sender: TObject);
    procedure MM_SeparatorsClick(Sender: TObject);
    procedure MM_LabelsClick(Sender: TObject);
    procedure MM_OperationsClick(Sender: TObject);
    procedure MM_ErrorsClick(Sender: TObject);
    procedure MM_StringsClick(Sender: TObject);
  private
    { Private declarations }
  public
    Scaner: TScaner;
  end;

var
  FMain: TFMain;

implementation

{$R *.dfm}

procedure TFMain.FormCreate(Sender: TObject);
begin
  Scaner := TScaner.Create;
end;

procedure TFMain.MM_CodedProgramClick(Sender: TObject);
begin
  with TFCode.Create(self) do begin
    MmoCode.Lines.SetText(PChar(Scaner.CodedProgram));
    ShowModal;
  end;
end;

procedure TFMain.MM_ConstsClick(Sender: TObject);
var
  K: Integer;
  S: String;
begin
  with TFTable.Create(self) do begin
    Caption := 'Константы';
    ViewGrid.RowCount := Succ(Scaner.Lexems.Constants);
    for K := 1 to Scaner.Lexems.Constants do begin
      S := 'C' + IntToStr(K);
      ViewGrid.Cells[0, K] := IntToStr(K);
      ViewGrid.Cells[1, K] := S;
      ViewGrid.Cells[2, K] := Scaner.CodeTreeInfo(S);
    end;
    ShowModal;
  end;

end;

procedure TFMain.MM_DoAnalizeClick(Sender: TObject);
begin
  Scaner.AnalizeCode(CodeEditor.Text);
end;

procedure TFMain.MM_ErrorsClick(Sender: TObject);
var
  K: Integer;
  S: String;
begin
  with TFTable.Create(self) do begin
    Caption := 'Ошибки';
    ViewGrid.RowCount := Succ(Scaner.Lexems.Errors);
    for K := 1 to Scaner.Lexems.Errors do begin
      S := 'E' + IntToStr(K);
      ViewGrid.Cells[0, K] := IntToStr(K);
      ViewGrid.Cells[1, K] := S;
      ViewGrid.Cells[2, K] := Scaner.CodeTreeInfo(S);
    end;
    ShowModal;
  end;
end;

procedure TFMain.MM_IdentificatorsClick(Sender: TObject);
var
  K: Integer;
  S: String;
begin
  with TFTable.Create(self) do begin
    Caption := 'Идентификаторы';
    ViewGrid.RowCount := Succ(Scaner.Lexems.Identificators);
    for K := 1 to Scaner.Lexems.Identificators do begin
      S := LexemCodeChar[ord(lcIdentifier)] + IntToStr(K);
      ViewGrid.Cells[0, K] := IntToStr(K);
      ViewGrid.Cells[1, K] := S;
      ViewGrid.Cells[2, K] := Scaner.CodeTreeInfo(S);
    end;
    ShowModal;
  end;
end;

procedure TFMain.MM_LabelsClick(Sender: TObject);
var
  K: Integer;
  S: String;
begin
  with TFTable.Create(self) do begin
    Caption := 'Метки';
    ViewGrid.RowCount := Succ(Scaner.Lexems.Labels);
    for K := 1 to Scaner.Lexems.Labels do begin
      S := LexemCodeChar[ord(lcLabel)] + IntToStr(K);
      ViewGrid.Cells[0, K] := IntToStr(K);
      ViewGrid.Cells[1, K] := S;
      ViewGrid.Cells[2, K] := Scaner.CodeTreeInfo(S);
    end;
    ShowModal;
  end;
end;

procedure TFMain.MM_LexemsCodeTableClick(Sender: TObject);
var
  S: String;
  I, N: Integer;
begin
  with TFTable.Create(self) do begin
    Caption := 'Таблица кодов лексемм';
    N := 1;
    S := '';
    for I := 1 to Length(Scaner.CodedProgram) do begin
      if Scaner.CodedProgram[I] = ' ' then begin
        ViewGrid.RowCount := Succ(N);
        ViewGrid.Cells[0, N] := IntToStr(N);
        ViewGrid.Cells[1, N] := S;
        ViewGrid.Cells[2, N] := Scaner.CodeTreeInfo(S);
        Inc(N);
        S := '';
      end
      else if not(Scaner.CodedProgram[I] in [#13, #10]) then S := S + Scaner.CodedProgram[I];
    end;
    ShowModal;
  end
end;

procedure TFMain.MM_OperationsClick(Sender: TObject);
var
  K: Integer;
  S: String;
begin
  with TFTable.Create(self) do begin
    Caption := 'Операции';
    ViewGrid.RowCount := Succ(Scaner.Lexems.Operations);
    for K := 1 to Scaner.Lexems.Operations do begin
      S := LexemCodeChar[ord(lcOperation)] + IntToStr(K);
      ViewGrid.Cells[0, K] := IntToStr(K);
      ViewGrid.Cells[1, K] := S;
      ViewGrid.Cells[2, K] := Scaner.CodeTreeInfo(S);
    end;
    ShowModal;
  end;
end;

procedure TFMain.MM_ReservedWordsClick(Sender: TObject);
var
  K: Integer;
  S: String;
begin
  with TFTable.Create(self) do begin
    Caption := 'Зарезервированные слова';
    ViewGrid.RowCount := Succ(Scaner.Lexems.Words);
    for K := 1 to Scaner.Lexems.Words do begin
      S := LexemCodeChar[ord(lcReservedWord)] + IntToStr(K);
      ViewGrid.Cells[0, K] := IntToStr(K);
      ViewGrid.Cells[1, K] := S;
      ViewGrid.Cells[2, K] := Scaner.CodeTreeInfo(S);
    end;
    ShowModal;
  end;

end;

procedure TFMain.MM_SeparatorsClick(Sender: TObject);
var
  K: Integer;
  S: String;
begin
  with TFTable.Create(self) do begin
    Caption := 'Разделители';
    ViewGrid.RowCount := Succ(Scaner.Lexems.Separators);
    for K := 1 to Scaner.Lexems.Separators do begin
      S := LexemCodeChar[ord(lcSeparator)] + IntToStr(K);
      ViewGrid.Cells[0, K] := IntToStr(K);
      ViewGrid.Cells[1, K] := S;
      ViewGrid.Cells[2, K] := Scaner.CodeTreeInfo(S);
    end;
    ShowModal;
  end;
end;

procedure TFMain.MM_StringsClick(Sender: TObject);
var
  K: Integer;
  S: String;
begin
  with TFTable.Create(self) do begin
    Caption := 'Строки';
    ViewGrid.RowCount := Succ(Scaner.Lexems.Strings);
    for K := 1 to Scaner.Lexems.Strings do begin
      S := LexemCodeChar[ord(lcString)] + IntToStr(K);
      ViewGrid.Cells[0, K] := IntToStr(K);
      ViewGrid.Cells[1, K] := S;
      ViewGrid.Cells[2, K] := Scaner.CodeTreeInfo(S);
    end;
    ShowModal;
  end;
end;

end.
