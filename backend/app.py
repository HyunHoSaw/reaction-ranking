import os
import redis
from fastapi import FastAPI
from pydantic import BaseModel, Field

# Redis 접속 (주소는 환경변수로 받음 → 로컬/EKS 어디서든 재사용)
r = redis.Redis(host=os.getenv("REDIS_HOST", "redis"), port=6379, decode_responses=True)
app = FastAPI()
KEY = "ranking"

class Score(BaseModel):
    name: str = Field(min_length=1, max_length=20)
    ms: int = Field(gt=50, lt=10000)   # 50ms 이하/10초 이상은 비정상 기록으로 거부

@app.get("/api/health")
def health():
    r.ping()
    return {"status": "ok"}

@app.post("/api/scores")
def add_score(s: Score):
    # Sorted Set에 저장. lt=True → 같은 이름이면 더 빠른 기록일 때만 갱신
    r.zadd(KEY, {s.name: s.ms}, lt=True)
    return {"ok": True}

@app.get("/api/ranking")
def ranking():
    # 점수 낮은 순(빠른 순)으로 상위 10명
    rows = r.zrange(KEY, 0, 9, withscores=True)
    return [{"name": n, "ms": int(s)} for n, s in rows]
