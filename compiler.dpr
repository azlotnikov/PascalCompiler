program compiler;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  pkScaner in 'pkScaner.pas';

var
  Scan: TPasScaner;
  LexemDefinitions: array [0 .. 9] of string = (
    'lcUnknown',
    'lcReservedWord',
    'lcIdentificator',
    'lcConstant',
    'lcError',
    'lcSeparator',
    'lcLabel',
    'lcOperation',
    'lcString',
    'lcComment'
  );

begin
  Scan := TPasScaner.Create('test.pas');
  while not Scan.EOF do begin
    Scan.Next;
    Writeln(Format('%s: %s | %d | %d', [LexemDefinitions[Ord(Scan.CurLexem.Code)], Scan.CurLexem.Value,
      Scan.CurLexem.Row, Scan.CurLexem.Col]));
  end;
  readln;

end.
