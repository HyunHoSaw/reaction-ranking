# ───────── GitHub Actions ↔ AWS 신뢰 연결 (OIDC) ─────────

# 1) "GitHub이 발급하는 신분증을 믿겠다"고 AWS에 등록
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# 2) GitHub Actions가 빌려 쓸 역할(출입증 종류)
resource "aws_iam_role" "github_actions" {
  name = "github-actions-reaction"

  # 신뢰 정책: 누가 이 역할을 빌릴 수 있나
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # 내 저장소의 main 브랜치에서 온 요청만 허용
          "token.actions.githubusercontent.com:sub" = "repo:HyunHoSaw/reaction-ranking:ref:refs/heads/main"
        }
      }
    }]
  })
}

# 3) 이 역할로 할 수 있는 일 (필요한 것만 = 최소 권한)
resource "aws_iam_role_policy" "github_actions" {
  name = "ecr-push-eks-describe"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # ECR 로그인 (이 권한은 특정 저장소로 좁힐 수 없음)
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        # 우리 ECR 저장소 2개에만 이미지 업로드 가능
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage"
        ]
        Resource = [
          aws_ecr_repository.frontend.arn,
          aws_ecr_repository.backend.arn
        ]
      },
      {
        # 클러스터 접속 정보 조회 (kubectl 연결용)
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        Resource = module.eks.cluster_arn
      }
    ]
  })
}
