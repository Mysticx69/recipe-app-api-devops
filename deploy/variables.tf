####################
# Database Variables
####################
variable "db_username" {
  type        = string
  description = "Username of rds instance"
}

variable "db_password" {
  type        = string
  description = "Password of rds instance"
}

variable "django_secret_key" {
  type        = string
  description = "Secret key for Django app"
}

###############
# ECR Variables
###############
variable "ecr_image_api" {
  type        = string
  description = "ECR Image for API"
}

variable "ecr_image_proxy" {
  type        = string
  description = "ECR Image for API"

}
