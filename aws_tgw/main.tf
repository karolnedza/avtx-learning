# Create an Aviatrix AWS TGW
resource "aviatrix_aws_tgw" "lab_aws_tgw" {
  account_name                      = var.account_name
  aws_side_as_number                = var.tgw_asn
  manage_vpc_attachment             = false
  region                            = var.region
  tgw_name                          = "${var.region}-Lab-AWS-TGW"

  security_domains {
    connected_domains    = [
      "Default_Domain",
      "Shared_Service_Domain",
    ]
    security_domain_name = "Aviatrix_Edge_Domain"
#       attached_vpc {
#           vpc_account_name = var.account_name
#           vpc_id           = var.tvpc_id
#           vpc_region       = var.region
#      }
  }

  security_domains {
    connected_domains    = [
      "Aviatrix_Edge_Domain",
      "Shared_Service_Domain"
    ]
    security_domain_name = "Default_Domain"
  }

  security_domains {
    connected_domains    = [
      "Aviatrix_Edge_Domain",
      "Default_Domain"
    ]
    security_domain_name = "Shared_Service_Domain"
  }

  security_domains {
    security_domain_name = "Firenet_Domain"
    aviatrix_firewall = true
#       attached_vpc {
#           vpc_account_name = var.account_name
#           vpc_id           = var.sec_vpc_id
#           vpc_region       = var.region
#        }
    }

  security_domains {
    security_domain_name = "Dev_Domain"
  }

  security_domains {
    security_domain_name = "Prod_Domain"
  }
}
