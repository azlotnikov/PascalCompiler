program compiler;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Winapi.Windows,
  pkScanner in 'pkScanner.pas',
  pkParser in 'pkParser.pas',
  pkTree in 'pkTree.pas';

const
  COMPILER_VERSION = '0.2';

  CONSOLE_DEFAULT_COLOR = FOREGROUND_GREEN + FOREGROUND_Blue;
  CONSOLE_GREEN_COLOR = FOREGROUND_GREEN;
  CONSOLE_PINK_COLOR = FOREGROUND_RED + FOREGROUND_Blue;

var
  Scan: TPasScanner;
  Pars: TParser;
  LexemDefinitions: array [0 .. 10] of string = (
    'lcUnknown',
    'lcReservedWord',
    'lcIdentificator',
    'lcConstant',
    'lcInteger',
    'lcFloat',
    'lcError',
    'lcSeparator',
    'lcOperation',
    'lcChar',
    'lcString'
  );

  FileOut: TextFile;

procedure SetConsoleColor(NewColor: Integer);
begin
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), NewColor);
end;

procedure PrintInfo;
begin
  SetConsoleColor(CONSOLE_DEFAULT_COLOR);
  Writeln('PascalCompiler v' + COMPILER_VERSION);
  Writeln;
  Writeln('Available Commands:');
  Writeln;
  SetConsoleColor(CONSOLE_PINK_COLOR);
  Write('Scan file:    ');
  SetConsoleColor(CONSOLE_GREEN_COLOR);
  Writeln('-s filename');
  SetConsoleColor(CONSOLE_PINK_COLOR);
  Write('Pars file:    ');
  SetConsoleColor(CONSOLE_GREEN_COLOR);
  Writeln('-p filename');
  SetConsoleColor(CONSOLE_PINK_COLOR);
  Write('Compile file: ');
  SetConsoleColor(CONSOLE_GREEN_COLOR);
  Writeln('-c filename');
  SetConsoleColor(CONSOLE_DEFAULT_COLOR);
  Writeln;
  Writeln('Press ENTER to exit');
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
  SetConsoleTitle(PChar('PascalCompiler v' + COMPILER_VERSION + ' [ https://github.com/ZRazor/PascalCompiler ]'));
  if ParamCount < 2 then begin
    PrintInfo;
    Readln;
    halt;
  end;

  if ParamStr(1) = '-s' then begin
    Scan := TPasScanner.Create;
    Scan.ScanFile(ParamStr(2));
    if ParamStr(3) <> '' then AssignFile(output, ParamStr(3));
    while Scan.Next do begin
      Writeln(Format('%20s'#9'%d'#9'%d'#9'%s', [LexemDefinitions[ord(Scan.CurLexem.Code)], Scan.CurLexem.Row,
        Scan.CurLexem.Col, Scan.CurLexem.Value]));
    end;
    Scan.Free;
  end;

  if ParamStr(1) = '-p' then begin
    Pars := TParser.Create;
    if ParamStr(3) <> '' then AssignFile(output, ParamStr(3));
    Pars.ParsFile(ParamStr(2));
    Pars.Free;
  end;

end.
