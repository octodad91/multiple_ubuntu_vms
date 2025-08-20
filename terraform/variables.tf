variable "vms" {
  type = map(object({
    vcpu = number
    memory = number
  }))
  default = {
    "muvm1" = { vcpu = 2, memory = 2048 }
    "muvm2" = { vcpu = 2, memory = 2048 }
    "muvm3" = { vcpu = 2, memory = 2048 }
  }
}
