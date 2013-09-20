program PasCompiler;

uses
  Vcl.Forms,
  main in 'main.pas' {FMain} ,
  plScaner in 'plScaner.pas',
  plSearchTree in 'plSearchTree.pas',
  SynEditPopupEdit in 'SynEditPopupEdit.pas',
  viewtable in 'viewtable.pas' {FTable} ,
  viewcode in 'viewcode.pas' {FCode};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFMain, FMain);
  // Application.CreateForm(TFCode, FCode);
  // Application.CreateForm(TFTable, FTable);
  Application.Run;

end.
