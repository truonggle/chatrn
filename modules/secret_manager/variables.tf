variable "project_id" { type = string }
variable "project_name" { type = string }
variable "env" { type = string }
variable "secrets" { type = map(string) }
variable "secret_accessors" {
  type = map(object({
    secret_name = string
    member      = string
  }))
  default = {}
}