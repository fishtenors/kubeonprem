#!/usr/bin/env python

from fastapi import FastAPI
import os
import datetime
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()
instrumentator = Instrumentator().instrument(app)

app_name = os.getenv("APP_NAME", "KubeOnPrem")
build_sha = os.getenv("BUILD_SHA", "unknown")


@app.on_event("startup")
async def startup_event():
    instrumentator.expose(app)


@app.get("/")
async def root():
    now = datetime.datetime.now()
    return {
        "time": "{}".format(now),
        "app": app_name,
        "build_sha": build_sha,
    }


@app.get("/health")
async def health_check():
    return {"status": "online"}


@app.get("/ready")
async def readiness_check():
    return {"status": "ready"}
