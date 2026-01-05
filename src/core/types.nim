type
  ProfileId* = distinct int32

  ProfileName* = object
    data*: string

const
  AppName* = "dotman"
  AppVersion* = "0.1.0"
  MaxProfiles* = 1024'i32
  MainProfile* = "main"
  ProfileIdInvalid* = ProfileId(-1)
