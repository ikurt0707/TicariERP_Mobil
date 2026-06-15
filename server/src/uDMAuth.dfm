object DMAuth: TDMAuth
  OnCreate = DataModuleCreate
  Height = 210
  Width = 340
  object FDConnectionAuth: TFDConnection
    Params.Strings = (
      'DriverID=MSSQL')
    LoginPrompt = False
    Left = 56
    Top = 32
  end
  object FDPhysMSSQLDriverLink1: TFDPhysMSSQLDriverLink
    Left = 56
    Top = 96
  end
end
