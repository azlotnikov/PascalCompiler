unit viewtable;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids;

type
  TFTable = class(TForm)
    ViewGrid: TStringGrid;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FTable: TFTable;

implementation

{$R *.dfm}

procedure TFTable.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFTable.FormCreate(Sender: TObject);
begin
  with ViewGrid do begin
    Cells[0, 0] := 'Порядковый номер';
    Cells[1, 0] := 'Кодовое имя';
    Cells[2, 0] := 'Расшифровка';
  end;
end;

end.
