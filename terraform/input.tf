locals {
  project_id = "warm-torus-179002"
  region     = "us-west3"
  zone       = "us-west3-c"
  shapes = {
    # worker = "e2-standard-2"
    # controller  = "e2-standard-2"
    worker     = "e2-small"
    controller = "e2-small"
  }
}
