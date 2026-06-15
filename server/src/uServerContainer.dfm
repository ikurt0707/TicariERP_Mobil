object ServerContainer1: TServerContainer1
  Height = 271
  Width = 415
  object DSServer1: TDSServer
    AutoStart = True
    Left = 56
    Top = 24
  end
  object DSServerClass_Cari: TDSServerClass
    OnGetClass = DSServerClass_CariGetClass
    Server = DSServer1
    Left = 184
    Top = 24
  end
  object DSServerClass_Siparis: TDSServerClass
    OnGetClass = DSServerClass_SiparisGetClass
    Server = DSServer1
    Left = 184
    Top = 80
  end
  object DSServerClass_Stok: TDSServerClass
    OnGetClass = DSServerClass_StokGetClass
    Server = DSServer1
    Left = 184
    Top = 136
  end
  object DSServerClass_CallerID: TDSServerClass
    OnGetClass = DSServerClass_CallerIDGetClass
    Server = DSServer1
    Left = 312
    Top = 24
  end
  object DSServerClass_Kurye: TDSServerClass
    OnGetClass = DSServerClass_KuryeGetClass
    Server = DSServer1
    Left = 312
    Top = 80
  end
  object DSServerClass_Auth: TDSServerClass
    OnGetClass = DSServerClass_AuthGetClass
    Server = DSServer1
    Left = 312
    Top = 136
  end
end
