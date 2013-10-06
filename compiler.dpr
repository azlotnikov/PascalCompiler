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

procedure PrintInfo;
begin
  Writeln('PascalCompiler v' + COMPILER_VERSION);
  Writeln('Available Commands:');
  Write('Scan file: ':20);
  Writeln('/S InputFile [OutputFile]');
  Write('Pars file: ':20);
  Writeln('/P InputFile [OutputFile]');
  Write('Compile file: ':20);
  Writeln('/C InputFile');
  Write('EnableExceptions: ':20);
  Writeln('/E');
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
        if s = '/S' then Command := ccScan
        else if s = '/P' then Command := ccPars
        else if s = '/C' then Command := ccCompile
        else if s = '/E' then Exceptions := True
        else Writeln('Unknown command: ' + ParamStr(i));
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

      Scan.Free; { NOTE: 1 }
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
    on E: Exception do Writeln(ErrOutput, E.Message);
  end;

end.
