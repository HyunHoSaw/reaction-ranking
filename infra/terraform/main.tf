# ───────── VPC (네트워크) ─────────
# 공식 커뮤니티 모듈 사용: 서브넷, 라우팅, NAT 등 수십 개 자원을 한 번에 만들어줌
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "reaction-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true # NAT를 1개만 (비용 절약. 실무에선 가용영역마다 1개)

  # 쿠버네티스가 로드밸런서를 어느 서브넷에 만들지 알려주는 표시
  public_subnet_tags  = { "kubernetes.io/role/elb" = 1 }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = 1 }
}

# ───────── EKS (쿠버네티스 클러스터) ─────────
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "reaction-eks"
  kubernetes_version = "1.35"

  endpoint_public_access                   = true # 맥북 kubectl로 접속 가능하게
  enable_cluster_creator_admin_permissions = true # 만든 사람(terraform-admin)에게 관리자 권한

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets # 노드는 Private 서브넷에

  # 클러스터 필수 부품
  addons = {
    coredns    = {}                        # 서비스 이름 → IP 변환 (backend, redis 찾기)
    kube-proxy = {}                        # Service 네트워크 처리
    vpc-cni    = { before_compute = true } # Pod에 VPC IP 할당
  }

  # 워커 노드 (실제로 Pod가 도는 서버)
  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_ARM_64_STANDARD" # ARM용 Amazon Linux 2023
      instance_types = ["t4g.medium"]           # 2 vCPU, 4GB 메모리
      min_size       = 1
      max_size       = 3
      desired_size   = 2
    }
  }
}

# ───────── ECR (도커 이미지 저장소) ─────────
# kind에선 kind load로 넣었지만, EKS는 여기서 이미지를 받아감
resource "aws_ecr_repository" "frontend" {
  name         = "reaction-frontend"
  force_delete = true # destroy 시 이미지가 남아 있어도 같이 삭제
}

resource "aws_ecr_repository" "backend" {
  name         = "reaction-backend"
  force_delete = true
}
