mock_provider "openstack" {
  mock_data "openstack_dns_zone_v2" {
    defaults = {
      id = "zone-id"
    }
  }
}

mock_provider "external" {}

override_data {
  target = module.record_generator.data.external.key2fp
  values = {
    result = {
      "ssh-ed25519" = "ed25519fp"
      "ssh-rsa"     = "rsafp"
    }
  }
}

variables {
  name   = "Phoenix"
  domain = "example.org"
  public_instances = {
    login1 = {
      public_ip = "192.0.2.10"
      tags      = ["login", "proxy", "public"]
      hostkeys  = { ed25519 = "ssh-ed25519 AAAA", rsa = "ssh-rsa AAAA" }
    }
    login2 = {
      public_ip = "192.0.2.11"
      tags      = ["login", "public"]
      hostkeys  = { ed25519 = "ssh-ed25519 AAAA", rsa = "ssh-rsa AAAA" }
    }
  }
}

run "records_are_grouped_per_name_and_type" {
  command = apply

  assert {
    condition     = openstack_dns_recordset_v2.records["phoenix A"].records == toset(["192.0.2.10", "192.0.2.11"])
    error_message = "The cluster A record set must hold the IP of every login node."
  }

  assert {
    condition     = openstack_dns_recordset_v2.records["phoenix A"].name == "phoenix.example.org."
    error_message = "Record set names must be fully qualified with a trailing dot."
  }

  assert {
    condition     = openstack_dns_recordset_v2.records["*.phoenix A"].records == toset(["192.0.2.10"])
    error_message = "The vhost record set must only point to proxy nodes."
  }

  assert {
    condition     = openstack_dns_recordset_v2.records["login1.phoenix SSHFP"].records == toset(["1 2 RSAFP", "4 2 ED25519FP"])
    error_message = "SSHFP records must be grouped per host and formatted as 'algorithm type fingerprint'."
  }

  assert {
    condition     = alltrue([for rs in openstack_dns_recordset_v2.records : rs.ttl == 300 && rs.zone_id == "zone-id"])
    error_message = "Every record set must use the default TTL and the looked-up zone."
  }

  assert {
    condition     = toset(output.hostnames) == toset(["*.phoenix.example.org", "login1.phoenix.example.org", "login2.phoenix.example.org", "phoenix.example.org"])
    error_message = "hostnames must list the distinct A record names."
  }
}

run "zone_name_and_ttl_can_be_set" {
  command = plan

  variables {
    zone_name = "clusters.example.org."
    ttl       = 60
  }

  assert {
    condition     = data.openstack_dns_zone_v2.domain.name == "clusters.example.org."
    error_message = "zone_name must override the zone looked up in Designate."
  }

  assert {
    condition     = alltrue([for rs in openstack_dns_recordset_v2.records : rs.ttl == 60])
    error_message = "ttl must apply to every record set."
  }
}
