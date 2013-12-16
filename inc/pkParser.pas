UNIT pkParser;

INTERFACE

USES
  System.SysUtils,
  pkScanner,
  pkTree,
  Generics.Collections;

TYPE
  TOperationPriority = (oppLowest, oppThird, oppSecond, oppHighest);

TYPE
  TParser = CLASS
  PRIVATE
    RExceptions         : Boolean;
    RScan               : TScanner;
    Lexems              : TQueue<TLexem>;
    OperationsPriorities: TDictionary<TOperationType, TOperationPriority>;
    FUNCTION ParseTerm(Priority: TOperationPriority = LOW(TOperationPriority)): TExprNode;
    FUNCTION ParseFactor(Priority: TOperationPriority = LOW(TOperationPriority)): TExprNode;
    FUNCTION GetLexem: TLexem;
    PROCEDURE PutLexem(Value: TLexem);
  PUBLIC
    RRoot: TExprNode;
    FUNCTION ParseExpression(Priority: TOperationPriority = LOW(TOperationPriority)): TExprNode;
    PROCEDURE ParsFile(FileName: STRING);
    PROCEDURE Free;
    CONSTRUCTOR Create(AExceptions: Boolean = False);
  END;

IMPLEMENTATION

CONST
  EXCEPTION_NO_LEXEM_AFTER     = 'No lexem after';
  EXCEPTION_NO_CLOSING_BRACKET = 'CLosing bracket expexted';
  EXCEPTION_UNSUPPORTED_LEXEM  = 'This Lexem is unsupported';

  { TParser }

FUNCTION TParser.ParseFactor(Priority: TOperationPriority = LOW(TOperationPriority)): TExprNode;
VAR
  Lexem: TLexem;
BEGIN
  Result := NIL;
  Lexem  := RScan.CurLexem;
  CASE Lexem.Code OF
    lcIdentificator:
      Result := TIdentificatorNode.Create(Lexem.ValueStr, Lexem.ValueStr, Lexem.Row, Lexem.Col, NIL, NIL);
    lcInteger:
      Result := TIntegerNode.Create(Lexem.ValueInt, Lexem.ValueStr, Lexem.Row, Lexem.Col, NIL, NIL);
    lcFloat:
      Result := TFloatNode.Create(Lexem.ValueFloat, Lexem.ValueStr, Lexem.Row, Lexem.Col, NIL, NIL);
    lcSeparator:
      BEGIN
        IF (Lexem.ValueSeparator = '(') THEN
        BEGIN
          IF RScan.Next THEN
            Result := ParseExpression
          ELSE IF (RExceptions) THEN
            RAISE TSyntaxException.Create(EXCEPTION_NO_LEXEM_AFTER, RScan.CurLexem);
          IF (RScan.CurLexem.ValueSeparator <> ')') AND RExceptions THEN
            RAISE TSyntaxException.Create(EXCEPTION_NO_CLOSING_BRACKET, RScan.CurLexem);
        END
        ELSE
          RAISE TSyntaxException.Create(EXCEPTION_UNSUPPORTED_LEXEM, RScan.CurLexem);
      END;
    lcError:
      exit(ParseFactor);
  ELSE
    IF (RExceptions) THEN
      RAISE TSyntaxException.Create(EXCEPTION_UNSUPPORTED_LEXEM, RScan.CurLexem);
  END;
  RScan.Next;
END;

FUNCTION TParser.ParseTerm(Priority: TOperationPriority = LOW(TOperationPriority)): TExprNode;
VAR
  Left : TExprNode;
  Lexem: TLexem;
BEGIN
  Left   := ParseFactor;
  Lexem  := RScan.CurLexem;
  Result := Left;
  IF (Lexem.ValueOperation IN [ptMult, ptDiv, ptIntDiv, ptMod]) THEN
  BEGIN
    IF RScan.Next THEN
      Result := TOperationNode.Create(Lexem.ValueOperation, Lexem.ValueStr, Lexem.Row, Lexem.Col, Left, ParseTerm);
  END;
END;

CONSTRUCTOR TParser.Create(AExceptions: Boolean = False);
BEGIN
  RExceptions := AExceptions;
  RScan       := TScanner.Create(RExceptions);
  Lexems      := TQueue<TLexem>.Create;
  WITH OperationsPriorities DO
  BEGIN
    Add(ptUnAdd, oppHighest);
    Add(ptUnSub, oppHighest);
    Add(ptNOT, oppHighest);
    // Add(ptPointer1, oppHighest);
    // Add(ptPointer2, oppHighest);

    Add(ptMult, oppSecond);
    Add(ptDiv, oppSecond);
    Add(ptIntDiv, oppSecond);
    Add(ptAND, oppSecond);
    Add(ptSHL, oppSecond);
    Add(ptSHR, oppSecond);

    Add(ptAdd, oppThird);
    Add(ptSub, oppThird);
    Add(ptOR, oppThird);
    Add(ptXOR, oppThird);

    Add(ptEq, oppLowest);
    Add(ptNotEq, oppLowest);
    Add(ptLess, oppLowest);
    Add(ptGreater, oppLowest);
    Add(ptLessEq, oppLowest);
    Add(ptGreaterEq, oppLowest);
  END;
END;

PROCEDURE TParser.ParsFile(FileName: STRING);
BEGIN
  RScan.StartFileScan(FileName);
  RScan.Next;
  RRoot := ParseExpression;
  RRoot.Print(0);
END;

PROCEDURE TParser.PutLexem(Value: TLexem);
BEGIN
  Lexems.Enqueue(Value);
END;

PROCEDURE TParser.Free;
BEGIN
  Lexems.Free;
  RScan.Free;
  OperationsPriorities.Free;
  Destroy;
END;

FUNCTION TParser.GetLexem: TLexem;
BEGIN
  IF Lexems.Count <> 0 THEN
    exit(Lexems.Dequeue);

  IF RScan.Next THEN // !!
    Result := RScan.CurLexem;
END;

FUNCTION TParser.ParseExpression(Priority: TOperationPriority = LOW(TOperationPriority)): TExprNode;
VAR
  Left : TExprNode;
  Lexem: TLexem;
BEGIN
  IF (Priority = HIGH(TOperationPriority)) THEN
    exit(ParseFactor);
  Result := ParseExpression(Succ(Priority));
  Lexem  := GetLexem;
  IF (Lexem.ValueOperation IN [ptAdd, ptSub]) THEN
  BEGIN
    IF RScan.Next THEN
      Result := TOperationNode.Create(Lexem.ValueOperation, Lexem.ValueStr, Lexem.Row, Lexem.Col, Left,
        ParseExpression);
  END;
END;

END.
