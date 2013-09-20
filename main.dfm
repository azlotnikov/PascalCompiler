object FMain: TFMain
  Left = 0
  Top = 0
  Caption = 'Pascal Lexer'
  ClientHeight = 372
  ClientWidth = 652
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MM
  OldCreateOrder = False
  OnCreate = FormCreate
  DesignSize = (
    652
    372)
  PixelsPerInch = 96
  TextHeight = 13
  object CodeEditor: TSynEdit
    Left = 8
    Top = 8
    Width = 636
    Height = 356
    Anchors = [akLeft, akTop, akRight, akBottom]
    Color = clSilver
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    TabOrder = 0
    Gutter.Font.Charset = DEFAULT_CHARSET
    Gutter.Font.Color = clWindowText
    Gutter.Font.Height = -11
    Gutter.Font.Name = 'Courier New'
    Gutter.Font.Style = []
    Highlighter = SynHighLighter
    Lines.Strings = (
      'program Test;'
      ''
      'var s:string;'
      ''
      'begin'
      '   s := '#39'123'#39';'
      '   s := $01;'
      '   s := 123;'
      '   s := 5.013;'
      'end.')
    WantTabs = True
    FontSmoothing = fsmNone
  end
  object SynHighLighter: TSynPasSyn
    Options.AutoDetectEnabled = False
    Options.AutoDetectLineLimit = 0
    Options.Visible = False
    CommentAttri.Foreground = 16384
    IdentifierAttri.Foreground = 4194368
    KeyAttri.Foreground = 16711808
    NumberAttri.Foreground = clPurple
    FloatAttri.Foreground = clPurple
    HexAttri.Foreground = clMaroon
    StringAttri.Foreground = clGreen
    CharAttri.Foreground = clGreen
    SymbolAttri.Foreground = 14492222
    Left = 584
    Top = 16
  end
  object MM: TMainMenu
    Left = 528
    Top = 16
    object MM_Menu: TMenuItem
      Caption = #1052#1077#1085#1102
    end
    object MM_Analize: TMenuItem
      Caption = #1040#1085#1072#1083#1080#1079' '#1050#1086#1076#1072
      object MM_DoAnalize: TMenuItem
        Caption = #1040#1085#1072#1083#1080#1079#1080#1088#1086#1074#1072#1090#1100
        ShortCut = 116
        OnClick = MM_DoAnalizeClick
      end
      object MM_Sep1: TMenuItem
        Caption = '-'
      end
      object MM_LexemsCodeTable: TMenuItem
        Caption = #1058#1072#1073#1083#1080#1094#1072' '#1082#1086#1076#1086#1074' '#1083#1077#1082#1089#1077#1084#1084
        OnClick = MM_LexemsCodeTableClick
      end
      object MM_CodedProgram: TMenuItem
        Caption = #1047#1072#1082#1086#1076#1080#1088#1086#1074#1072#1085#1085#1072#1103' '#1087#1088#1086#1075#1088#1072#1084#1084#1072
        OnClick = MM_CodedProgramClick
      end
      object MM_Sep2: TMenuItem
        Caption = '-'
      end
      object MM_Consts: TMenuItem
        Caption = #1050#1086#1085#1089#1090#1072#1085#1090#1099
        OnClick = MM_ConstsClick
      end
      object MM_ReservedWords: TMenuItem
        Caption = #1057#1083#1091#1078#1077#1073#1085#1099#1077' '#1089#1083#1086#1074#1072
        OnClick = MM_ReservedWordsClick
      end
      object MM_Identificators: TMenuItem
        Caption = #1048#1076#1077#1085#1090#1080#1092#1080#1082#1072#1090#1086#1088#1099
        OnClick = MM_IdentificatorsClick
      end
      object MM_Separators: TMenuItem
        Caption = #1056#1072#1079#1076#1077#1083#1080#1090#1077#1083#1080
        OnClick = MM_SeparatorsClick
      end
      object MM_Labels: TMenuItem
        Caption = #1052#1077#1090#1082#1080
        OnClick = MM_LabelsClick
      end
      object MM_Operations: TMenuItem
        Caption = #1054#1087#1077#1088#1072#1094#1080#1080
        OnClick = MM_OperationsClick
      end
      object MM_Strings: TMenuItem
        Caption = #1057#1090#1088#1086#1082#1080
        OnClick = MM_StringsClick
      end
      object MM_Errors: TMenuItem
        Caption = #1054#1096#1080#1073#1082#1080
        OnClick = MM_ErrorsClick
      end
    end
  end
end
