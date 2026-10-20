"""云端 MinerU 解析器包装器，用于 ingest 工作流。"""

from __future__ import annotations

import asyncio
import os
import tempfile
from pathlib import Path

import structlog

from app.shared.infra.exceptions import FileParseError
from app.workflows.ingest.parsing.lib.types import ParserRunOptions
from app.workflows.ingest.parsing.mineru_cloud import (
    MinerUExtractedResult,
    MinerURequestOptions,
    parse_file_to_dir,
)

logger = structlog.get_logger(__name__)


def _get_mineru_cloud_token() -> str | None:
    """从环境变量获取 MinerU Cloud API Token。
    
    优先级:
    1. MINERU_CLOUD_TOKEN
    2. MINERU_API_TOKEN
    3. MINERU_API_TOKENS (取第一个)
    """
    # 首选
    token = os.getenv("MINERU_CLOUD_TOKEN", "").strip()
    if token:
        return token
    
    # 备选
    token = os.getenv("MINERU_API_TOKEN", "").strip()
    if token:
        return token
    
    # 多个token的情况（取第一个）
    tokens = os.getenv("MINERU_API_TOKENS", "").strip()
    if tokens:
        first_token = tokens.split(",")[0].strip()
        if first_token:
            return first_token
    
    return None


async def parse_pdf_with_mineru_cloud_wrapper(
    file_path: str | Path,
    asset_dir: Path,
    options: ParserRunOptions,
) -> str:
    """使用 MinerU Cloud API 解析 PDF。
    
    Args:
        file_path: PDF 文件路径
        asset_dir: 资源文件输出目录（图片等）
        options: 解析选项
        
    Returns:
        解析后的 Markdown 文本
        
    Raises:
        FileParseError: 当 Token 未配置或解析失败时
    """
    path = Path(file_path)
    
    # 检查 Token
    api_token = _get_mineru_cloud_token()
    if not api_token:
        raise FileParseError(
            path.name,
            reason=(
                "MinerU Cloud API Token 未配置。请设置环境变量："
                "MINERU_CLOUD_TOKEN 或 MINERU_API_TOKEN"
            ),
        )
    
    logger.info(
        "parse_pdf_mineru_cloud_start",
        filename=path.name,
        timeout_s=options.timeout_s,
        file_size_mb=round(path.stat().st_size / 1024 / 1024, 2),
    )
    
    # 准备临时目录
    with tempfile.TemporaryDirectory(prefix="mineru_cloud_") as temp_dir:
        temp_path = Path(temp_dir)
        
        # 构建 MinerU 选项
        mineru_options = MinerURequestOptions(
            api_token=api_token,
            enable_formula=True,
            enable_table=True,
            is_ocr=False,  # 云端自动检测
            model_version="vlm",  # 默认使用最新模型
        )
        
        try:
            # 调用云端解析（同步函数，用 to_thread 包装）
            result: MinerUExtractedResult = await asyncio.to_thread(
                parse_file_to_dir,
                file_path=path,
                options=mineru_options,
                output_dir=temp_path,
                base_url=os.getenv("MINERU_CLOUD_URL", "https://mineru.net"),
                poll_interval_s=5.0,  # 每5秒轮询一次
                poll_timeout_s=600.0,  # 轮询超时10分钟
                total_timeout_s=options.timeout_s or 3600.0,  # 总超时1小时
                progress_callback=None,
            )
            
            # 读取 Markdown
            markdown_text = result.markdown_path.read_text(encoding="utf-8")
            
            if not markdown_text.strip():
                raise FileParseError(
                    path.name,
                    reason="MinerU Cloud 返回了空的 Markdown 内容",
                )
            
            # TODO: 复制图片到 asset_dir（如果需要）
            # if result.images_dir and result.images_dir.exists():
            #     for img in result.images_dir.glob("*"):
            #         shutil.copy(img, asset_dir / img.name)
            
            logger.info(
                "parse_pdf_mineru_cloud_success",
                filename=path.name,
                markdown_length=len(markdown_text),
                batch_id=result.batch_id,
            )
            
            return markdown_text
            
        except Exception as exc:
            logger.exception(
                "parse_pdf_mineru_cloud_failed",
                filename=path.name,
                error=str(exc),
            )
            raise FileParseError(
                path.name,
                reason=f"MinerU Cloud 解析失败: {exc}",
            ) from exc
