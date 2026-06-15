object DM: TDM
  OnCreate = DataModuleCreate
  Height = 210
  Width = 340
  object FDConnection: TFDConnection
    Params.Strings = (
      'DriverID=MSSQL')
    LoginPrompt = False
    Left = 56
    Top = 32
  end
  object FDPhysMSSQLDriverLink: TFDPhysMSSQLDriverLink
    Left = 56
    Top = 96
  end
end
