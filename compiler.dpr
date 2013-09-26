program compiler;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Winapi.Windows,
  pkScaner in 'pkScaner.pas';

var
  Scan: TPasScanner;
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

  c: string;

procedure DefColor;
begin
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_GREEN + FOREGROUND_Blue);
end;

procedure SpecColor;
begin
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_RED + FOREGROUND_Blue);
end;

procedure NumColor;
begin
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_RED);
end;

procedure GreenColor;
begin
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_GREEN);
end;

procedure CleanSrc;
var
  Count, Res: Cardinal;
  k: string;
  BuffInfo: TConsoleScreenBufferInfo;
  FOutHandle: THandle;
begin
  FOutHandle := GetStdHandle(STD_OUTPUT_HANDLE);
  GetConsoleScreenBufferInfo(FOutHandle, BuffInfo);
  with BuffInfo do Count := dwSize.X * dwSize.Y;
  BuffInfo.dwCursorPosition.X := 0;
  BuffInfo.dwCursorPosition.Y := 0;
  FillConsoleOutputCharacter(FOutHandle, #0, Count, BuffInfo.dwCursorPosition, Res);
  SetConsoleCursorPosition(FOutHandle, BuffInfo.dwCursorPosition);
end;

begin
  SetConsoleTitle(PChar('PasCompiler [ https://github.com/ZRazor/PascalCompiler ]'));
  DefColor;
  Writeln('Write "exit" to close program or "%filename%" to pars file.');
  Scan := TPasScanner.Create;
  while True do begin
    DefColor;
    Readln(c);
    if c = 'exit' then Halt(0);
    CleanSrc;
    if not FileExists(c) then begin
      Write('File not found: ');
      SpecColor;
      Writeln(c);
      Continue;
    end;
    write('File: ');
    GreenColor;
    Writeln(c);
    DefColor;
    Writeln('+------------------+--------------------------------+------+------+');
    write('|');
    Write(' Code |':19);
    write(' Value |':33);
    write(' Row |':7);
    Writeln(' Col |':7);
    Writeln('+------------------+--------------------------------+------+------+');
    Scan.LoadFromFile(c);
    while not Scan.EndOfScan do begin
      Scan.Next;
      write('| ');
      GreenColor;
      write(LexemDefinitions[Ord(Scan.CurLexem.Code)]:16);
      DefColor;
      write(' | ');
      SpecColor;
      write(Scan.CurLexem.Value:30);
      DefColor;
      write(' | ');
      NumColor;
      write(Scan.CurLexem.Row:4);
      DefColor;
      write(' | ');
      NumColor;
      Write(Scan.CurLexem.Col:4);
      DefColor;
      Writeln(' |');
      Writeln('+------------------+--------------------------------+------+------+');
    end;
    //Writeln('+------------------+--------------------------------+------+------+');
  end;
  Readln;

end.
