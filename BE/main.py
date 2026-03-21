from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI
from core.route import router 
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

app.include_router(router, prefix="")

@app.get("/")
async def root():
    return {"status":"Server attivo."}