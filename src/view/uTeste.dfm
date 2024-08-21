object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 328
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object btnInsert: TButton
    Left = 8
    Top = 32
    Width = 121
    Height = 57
    Caption = 'Insert'
    TabOrder = 0
    OnClick = btnInsertClick
  end
  object btnUpdateSQL: TButton
    Left = 8
    Top = 128
    Width = 121
    Height = 57
    Caption = 'Update by Text SQL'
    TabOrder = 1
    OnClick = btnUpdateSQLClick
  end
  object btnDeleteSQL: TButton
    Left = 8
    Top = 219
    Width = 121
    Height = 57
    Caption = 'Delete by Text SQL'
    TabOrder = 2
    OnClick = btnDeleteSQLClick
  end
  object btnLoad: TButton
    Left = 144
    Top = 32
    Width = 121
    Height = 57
    Caption = 'LoadByPK'
    TabOrder = 3
    OnClick = btnLoadClick
  end
  object btnUpdatePK: TButton
    Left = 144
    Top = 128
    Width = 121
    Height = 57
    Caption = 'Update by PK'
    TabOrder = 4
    OnClick = btnUpdatePKClick
  end
  object btnUpdateProp: TButton
    Left = 279
    Top = 128
    Width = 121
    Height = 57
    Caption = 'Update by Property'
    TabOrder = 5
    OnClick = btnUpdatePropClick
  end
  object btnDeleteByPK: TButton
    Left = 144
    Top = 219
    Width = 121
    Height = 57
    Caption = 'Delete by PK'
    TabOrder = 6
    OnClick = btnDeleteByPKClick
  end
  object btnDeleteProp: TButton
    Left = 279
    Top = 219
    Width = 121
    Height = 57
    Caption = 'Delete by Property'
    TabOrder = 7
    OnClick = btnDeletePropClick
  end
end
