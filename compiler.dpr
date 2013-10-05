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
  COMPILER_VERSION = '0.4';

  CONSOLE_DEFAULT_COLOR = FOREGROUND_GREEN + FOREGROUND_Blue;
  CONSOLE_GREEN_COLOR = FOREGROUND_GREEN;
  CONSOLE_PINK_COLOR = FOREGROUND_RED + FOREGROUND_Blue;

type
  TCompilerCommand = (ccNone, ccScan, ccPars, ccCompile);

  TCommands = record
    Exceptions: Boolean;
    InputFile: String;
    OutPutFile: String;
    Command: TCompilerCommand;
  end;

var
  Scan: TScanner;
  Pars: TParser;
  Commands: TCommands;
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
  Write('Scan file: ':20);
  SetConsoleColor(CONSOLE_GREEN_COLOR);
  Writeln('/S InputFile [OutputFile]');
  SetConsoleColor(CONSOLE_PINK_COLOR);
  Write('Pars file: ':20);
  SetConsoleColor(CONSOLE_GREEN_COLOR);
  Writeln('/P InputFile [OutputFile]');
  SetConsoleColor(CONSOLE_PINK_COLOR);
  Write('Compile file: ':20);
  SetConsoleColor(CONSOLE_GREEN_COLOR);
  Writeln('/C InputFile');
  SetConsoleColor(CONSOLE_PINK_COLOR);
  Write('EnableExceptions: ':20);
  SetConsoleColor(CONSOLE_GREEN_COLOR);
  Writeln('/E');
  SetConsoleColor(CONSOLE_DEFAULT_COLOR);
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

procedure ReadCommands;
var
  i: Integer;
  s: string;
begin
  with Commands do begin
    Command := ccNone;
    InputFile := '';
    OutPutFile := '';
    for i := 1 to ParamCount do begin
      s := AnsiUpperCase(ParamStr(i));
      if (s[1] = '/') then begin
        if s = '/S' then Command := ccScan;
        if s = '/P' then Command := ccPars;
        if s = '/C' then Command := ccCompile;
        if s = '/E' then Exceptions := True;
      end else begin
        if InputFile = '' then InputFile := ParamStr(i)
        else if OutPutFile = '' then OutPutFile := ParamStr(i);
      end;
    end;
  end;
end;

begin
  try
    SetConsoleTitle(PChar('PascalCompiler v' + COMPILER_VERSION + ' [ https://github.com/ZRazor/PascalCompiler ]'));

    ReadCommands;

    if (Commands.Command = ccNone) or (Commands.InputFile = '') then begin
      PrintInfo;
      halt;
    end;

    if Commands.Command = ccScan then begin

      Scan := TScanner.Create(Commands.Exceptions);
      Scan.StartFileScan(Commands.InputFile);
      if Commands.OutPutFile <> '' then AssignFile(output, Commands.OutPutFile);
      while Scan.Next do begin
        Writeln(Format('%-20s'#9'%d'#9'%d'#9'%s', [LexemDefinitions[ord(Scan.CurLexem.Code)], Scan.CurLexem.Row,
          Scan.CurLexem.Col, Scan.CurLexem.PrintLexem]));
      end;

      Scan.Free; { NOTE: 1}
      halt;
    end;

    if Commands.Command = ccPars then begin

      Pars := TParser.Create(Commands.Exceptions);
      if Commands.OutPutFile <> '' then AssignFile(output, Commands.OutPutFile);
      Pars.ParsFile(Commands.InputFile);

      Pars.Free;
      halt;
    end;

    PrintInfo;

  except
    on E: Exception do begin
      Writeln(ErrOutput, E.Message);
    end;
  end;

end.
