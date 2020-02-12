variable region {
  default = "us-east-1"
}

variable region2 {
  default = "us-east-2"
}

variable account_name {
  default = "avtx_lab_demo"
}

variable "avtx_key_name" {
  default = "avtx_key"
}

variable "awsaccesskey" {
        type = string
}
variable "awssecretkey" {
        type = string
}

variable "avtx_controller_bucket" { 
    default = "e52e25bc602498b5fda4f87fc126dbc4"
}
