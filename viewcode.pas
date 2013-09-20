unit viewcode;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TFCode = class(TForm)
    MmoCode: TMemo;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FCode: TFCode;

implementation

{$R *.dfm}

procedure TFCode.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

end.
