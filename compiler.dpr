program compiler;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Winapi.Windows,
  pkScaner in 'pkScaner.pas';

const
  COMPILE_VERSION = '0.2';

  CONSOLE_DEFAULT_COLOR = FOREGROUND_GREEN + FOREGROUND_Blue;
  CONSOLE_GREEN_COLOR = FOREGROUND_GREEN;
  CONSOLE_PINK_COLOR = FOREGROUND_RED + FOREGROUND_Blue;

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
    'lcChar',
    'lcString'
  );

  RCommand: string;

procedure SetConsoleColor(NewColor: Integer);
begin
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), NewColor);
end;

procedure PrintInfo;
begin
  SetConsoleColor(CONSOLE_PINK_COLOR);
  Writeln;
  Writeln('PascalCompiler v' + COMPILE_VERSION:50);
  Writeln;
  SetConsoleColor(CONSOLE_GREEN_COLOR);
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
  SetConsoleTitle(PChar('PascalCompiler v' + COMPILE_VERSION + ' [ https://github.com/ZRazor/PascalCompiler ]'));
  if ParamCount = 0 then begin
    PrintInfo;
    Readln;
    halt;
  end;

end.
