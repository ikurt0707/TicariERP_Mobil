object WebModule1: TWebModule1
  OnCreate = WebModuleCreate
  Actions = <>
  Height = 230
  Width = 415
  object DSHTTPWebDispatcher1: TDSHTTPWebDispatcher
    DSContext = datasnap/
    RESTContext = rest/
    WebDispatch.PathInfo = datasnap*
    Left = 56
    Top = 32
  end
end
