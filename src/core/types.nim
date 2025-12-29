type
  ProfileId* = distinct int32

  ProfileName* = object
    data*: string

const
  MaxProfiles* = 1024'i32
  MainProfile* = "main"
