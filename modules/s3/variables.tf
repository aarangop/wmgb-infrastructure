# S3 module variables

variable "project_prefix" {
  description = "Prefix to be used for all resource names"
  type        = string
  default     = "wmgb"
}

variable "enable_model_versioning" {
  description = "Enable versioning for the ML models S3 bucket"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "WhosMyGoodBoy"
  }
}
