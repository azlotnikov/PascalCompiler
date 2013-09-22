program compiler;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Winapi.Windows,
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
  Scan := TPasScaner.Create;
  while True do begin
    DefColor;
    Readln(c);
    CleanSrc;
    write('File: ');
    GreenColor;
    Writeln(c);
    DefColor;
    Writeln('+-----------------------------------------------------------------+');
    write('|');
    Write(' Code |':19);
    write(' Value |':33);
    write(' Row |':7);
    Writeln(' Col |':7);
    Writeln('+-----------------------------------------------------------------+');
    if c = 'exit' then Halt(0);
    Scan.LoadFromFile(c);
    while not Scan.EOF do begin
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
    end;
    Writeln('+-----------------------------------------------------------------+');
  end;
  Readln;

end.
