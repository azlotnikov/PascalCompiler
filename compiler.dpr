PROGRAM compiler;

{$APPTYPE CONSOLE}
{$R *.res}

USES
  System.SysUtils,
  Winapi.Windows,
  pkScanner IN 'pkScanner.pas',
  pkParser IN 'pkParser.pas',
  pkTree IN 'pkTree.pas';

CONST
  COMPILER_VERSION = '0.4';

TYPE
  TCompilerCommand = (ccNone, ccScan, ccPars, ccCompile);

  TCommands = RECORD
    Exceptions: Boolean;
    InputFile: STRING;
    OutPutFile: STRING;
    Command: TCompilerCommand;
  END;

VAR
  Scan            : TScanner;
  Pars            : TParser;
  Commands        : TCommands;
  LexemDefinitions: ARRAY [0 .. 10] OF STRING = (
    'lcUnknown',
    'lcReservedWord',
    'lcIdentificator',
    'lcInteger',
    'lcFloat',
    'lcError',
    'lcSeparator',
    'lcOperation',
    'lcChar',
    'lcString',
    'lcLabel'
  );

PROCEDURE PrintInfo;
BEGIN
  Writeln('PascalCompiler v' + COMPILER_VERSION);
  Writeln('Available Commands:');
  WRITE('Scan file: ':20);
  Writeln('/S InputFile [OutputFile]');
  WRITE('Pars file: ':20);
  Writeln('/P InputFile [OutputFile]');
  WRITE('Compile file: ':20);
  Writeln('/C InputFile');
  WRITE('EnableExceptions: ':20);
  Writeln('/E');
END;

PROCEDURE ReadCommands;
VAR
  i: Integer;
  s: STRING;
BEGIN
  WITH Commands DO
  BEGIN
    Command    := ccNone;
    InputFile  := '';
    OutPutFile := '';
    FOR i      := 1 TO ParamCount DO
    BEGIN
      s := AnsiUpperCase(ParamStr(i));
      IF (s[1] = '/') THEN
      BEGIN
        IF s = '/S' THEN
          Command := ccScan
        ELSE IF s = '/P' THEN
          Command := ccPars
        ELSE IF s = '/C' THEN
          Command := ccCompile
        ELSE IF s = '/E' THEN
          Exceptions := True
        ELSE
          Writeln('Unknown command: ' + ParamStr(i));
      END ELSE BEGIN
        IF InputFile = '' THEN
          InputFile := ParamStr(i)
        ELSE IF OutPutFile = '' THEN
          OutPutFile := ParamStr(i);
      END;
    END;
  END;
END;

BEGIN
  TRY
    SetConsoleTitle(PChar('PascalCompiler v' + COMPILER_VERSION + ' [ https://github.com/ZRazor/PascalCompiler ]'));

    ReadCommands;

    IF (Commands.Command = ccNone) OR (Commands.InputFile = '') THEN
    BEGIN
      PrintInfo;
      halt;
    END;

    IF Commands.Command = ccScan THEN
    BEGIN

      Scan := TScanner.Create(Commands.Exceptions);
      Scan.StartFileScan(Commands.InputFile);
      IF Commands.OutPutFile <> '' THEN
        AssignFile(output, Commands.OutPutFile);
      WHILE Scan.Next DO
      BEGIN
        Writeln(Format('%-20s'#9'%d'#9'%d'#9'%s', [LexemDefinitions[ord(Scan.CurLexem.Code)], Scan.CurLexem.Row,
          Scan.CurLexem.Col, Scan.CurLexem.PrintLexem]));
      END;

      Scan.Free; { NOTE: 1 }
      halt;
    END;

    IF Commands.Command = ccPars THEN
    BEGIN

      Pars := TParser.Create(Commands.Exceptions);
      IF Commands.OutPutFile <> '' THEN
        AssignFile(output, Commands.OutPutFile);
      Pars.ParsFile(Commands.InputFile);

      Pars.Free;
      halt;
    END;

    PrintInfo;

  EXCEPT
    ON E: Exception DO
      Writeln(ErrOutput, E.Message);
  END;

END.
