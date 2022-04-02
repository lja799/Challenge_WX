#########################################################################
# Variables
#########################################################################

variable "docker_image" {
  description = "Docker Image File"
  type        = string
  default     = "dfranciswoolies/ciarecruitment-bestapiever"
}

variable "docker_image_tag" {
  description = "Docker Image File Tag"
  type        = string
  default     = "247904"
}

variable "health_check" {
  description = "Container Health Check Path"
  type        = string
  default     = "/health"
}

variable "apikey_secret" {
  description = "The APIKEY Secret"
  type        = string
  sensitive   = true
}