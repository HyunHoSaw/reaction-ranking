# Reaction Ranking

반응속도 테스트 게임 + 실시간 랭킹 서비스 (DevOps 파이널 프로젝트)

## 구성
- frontend: nginx (정적 페이지 + /api 리버스 프록시)
- backend: Python FastAPI (랭킹 API)
- redis: Sorted Set 기반 랭킹 저장

## 로컬 실행
    docker compose up -d --build
    # http://localhost:8080

## 예정
- Terraform으로 AWS VPC / EKS 구성
- GitHub Actions CI/CD
- Prometheus + Grafana 모니터링
