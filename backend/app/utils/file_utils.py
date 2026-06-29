import uuid
import shutil
from pathlib import Path
from fastapi import UploadFile

def save_upload_file(upload_dir: str, upload_file: UploadFile) -> str:
    upload_path = Path(upload_dir)
    upload_path.mkdir(parents=True, exist_ok=True)
    
    file_extension = Path(upload_file.filename or "avatar.png").suffix or ".png"
    unique_name = f"{uuid.uuid4().hex}{file_extension}"
    file_path = upload_path / unique_name
    
    with open(file_path, "wb") as buffer:
        upload_file.file.seek(0)
        shutil.copyfileobj(upload_file.file, buffer)
    
    return str(file_path)
