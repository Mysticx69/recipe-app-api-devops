terraform {
  cloud {
    organization = "mysticx"

    workspaces {
      name = "recipe-app-api-devops"
    }
  }
}
