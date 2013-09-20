object FTable: TFTable
  Left = 0
  Top = 0
  Caption = #1058#1072#1073#1083#1080#1094#1072
  ClientHeight = 313
  ClientWidth = 358
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  DesignSize = (
    358
    313)
  PixelsPerInch = 96
  TextHeight = 13
  object ViewGrid: TStringGrid
    Left = 8
    Top = 8
    Width = 342
    Height = 297
    Anchors = [akLeft, akTop, akRight, akBottom]
    ColCount = 3
    DefaultColWidth = 105
    FixedCols = 0
    RowCount = 2
    ScrollBars = ssVertical
    TabOrder = 0
  end
end
