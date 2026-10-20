"""Local MinerU PDF parser for AITeachMe."""

from __future__ import annotations

import asyncio
import subprocess
import tempfile
from pathlib import Path

import structlog

from app.shared.infra.exceptions import FileParseError
from app.workflows.ingest.parsing.lib.types import ParserRunOptions

logger = structlog.get_logger()


async def parse_pdf_with_mineru_local(
    file_path: str | Path,
    asset_dir: Path,
    options: ParserRunOptions,
) -> str:
    """Parse PDF using local MinerU installation."""
    return await asyncio.to_thread(_parse_pdf_with_mineru_local_sync, Path(file_path), asset_dir, options)


def _parse_pdf_with_mineru_local_sync(
    path: Path,
    asset_dir: Path,
    options: ParserRunOptions,
) -> str:
    """Synchronous MinerU PDF parsing."""
    logger.info(
        "parse_pdf_mineru_local_start",
        filename=path.name,
        file_size_bytes=path.stat().st_size,
    )

    try:
        # Check if MinerU is available
        try:
            import mineru  # noqa: F401
        except ImportError:
            raise FileParseError(
                path.name,
                reason="MinerU is not installed. Run: pip install 'mineru>=4.0,<5'",
            )

        # Create temporary output file
        with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False, encoding="utf-8") as tmp_output:
            output_path = Path(tmp_output.name)

        try:
            # Run mineru-kit parse command
            # Use basic tier by default (no extra dependencies)
            cmd = [
                "mineru-kit",
                "parse",
                str(path.absolute()),
                "-o",
                str(output_path.absolute()),
                "--tier",
                "basic",
            ]

            logger.info(
                "parse_pdf_mineru_local_exec",
                filename=path.name,
                command=" ".join(cmd),
            )

            # Run the command with extended timeout (1 hour for very large PDFs)
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=3600,  # 1 hour timeout (was 1800)
                encoding="utf-8",
                errors="replace",
            )

            if result.returncode != 0:
                error_msg = result.stderr if result.stderr else result.stdout
                logger.warning(
                    "parse_pdf_mineru_local_failed",
                    filename=path.name,
                    returncode=result.returncode,
                    stderr=error_msg[:500],
                )
                raise FileParseError(
                    path.name,
                    reason=f"MinerU parsing failed (exit code {result.returncode}): {error_msg[:200]}",
                )

            # Read the output markdown
            if not output_path.exists():
                raise FileParseError(
                    path.name,
                    reason="MinerU did not produce output file",
                )

            markdown_content = output_path.read_text(encoding="utf-8", errors="replace")

            if not markdown_content.strip():
                raise FileParseError(
                    path.name,
                    reason="MinerU returned empty markdown",
                )

            logger.info(
                "parse_pdf_mineru_local_success",
                filename=path.name,
                markdown_length=len(markdown_content),
                markdown_lines=markdown_content.count("\n"),
            )

            return markdown_content

        finally:
            # Clean up temporary output file
            if output_path.exists():
                try:
                    output_path.unlink()
                except Exception:
                    pass

    except subprocess.TimeoutExpired:
        logger.warning(
            "parse_pdf_mineru_local_timeout",
            filename=path.name,
        )
        raise FileParseError(
            path.name,
            reason="MinerU parsing timed out (>5 minutes)",
        )
    except FileParseError:
        raise
    except Exception as exc:
        logger.exception(
            "parse_pdf_mineru_local_error",
            filename=path.name,
            error=str(exc),
        )
        raise FileParseError(
            path.name,
            reason=f"MinerU parsing error: {exc!s}",
        )
