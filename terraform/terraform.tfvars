vms = {
  "sql" = {
    name     = "SRV-SQL-01"
    memory   = 49152 # 48GB
    cpus     = 8
    template = "win"
  },
  "app" = {
    name     = "SRV-APP-01"
    memory   = 16384 # 16GB
    cpus     = 4
    template = "win"
  },
  "linux" = {
    name     = "SRV-LNX-01"
    memory   = 8192  # 8GB
    cpus     = 2
    template = "linux"
  }
}