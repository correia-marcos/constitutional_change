"""
Measuring Constitutional Textual Entrenchment

@Goal: Establish project configuration, utility functions, and environment setup
@Description: Centralized configuration file for package management, path setup, 
              and common utilities used throughout the text analysis pipeline.
              
              Implements best practices for:
              - Reproducible environment management
              - Consistent logging configuration
              - Path handling with pathlib
              - Type hinting for maintainability
              - PEP-compliant documentation

@Date: Dec 2024
@Author: Marcos Paulo
"""

# Core Imports
import os
import sys
import logging
import spacy
import pandas as pd
from pathlib import Path
from typing import List, Union, Iterable
from importlib.metadata import version, PackageNotFoundError

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

# Project Constants
PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / 'data'
RAW_TEXT_DIR = DATA_DIR / 'raw' / 'constitutions'
PROCESSED_DIR = DATA_DIR / 'processed'

# Package Requirements (should match requirements.txt)
REQUIRED_PACKAGES = {
    'pandas': '2.0.3',
    'spacy': '3.7.2',
    'numpy': '1.24.3',
    'pyarrow': '13.0.0'  # For Parquet support
}

def verify_environment() -> None:
    """Validate the execution environment meets project requirements."""
    logger.info("Verifying project environment...")
    
    missing = []
    for pkg, req_version in REQUIRED_PACKAGES.items():
        try:
            installed_version = version(pkg)
            if installed_version != req_version:
                logger.warning(f"Version mismatch: {pkg} (installed: {installed_version}, required: {req_version})")
        except PackageNotFoundError:
            missing.append(pkg)
    
    if missing:
        logger.error(f"Missing packages: {', '.join(missing)}")
        raise ImportError("Please install missing packages using requirements.txt")
        
    logger.info("Environment validation passed")

def setup_project_dirs() -> None:
    """Create required project directories if they don't exist."""
    directories = [DATA_DIR, RAW_TEXT_DIR, PROCESSED_DIR]
    
    for directory in directories:
        directory.mkdir(parents=True, exist_ok=True)
        logger.debug(f"Verified directory: {directory}")

def get_df(text_files: List[Union[str, Path]]) -> pd.DataFrame:
    """
    Create a DataFrame from constitution text files with metadata extraction.

    Parameters
    ----------
    text_files : List[Union[str, Path]]
        List of paths to constitution text files. Filenames should follow:
        [Country]_[Year].txt (e.g., 'Brazil_1988.txt')

    Returns
    -------
    pd.DataFrame
        DataFrame with columns: ['country', 'year', 'constitution']

    Examples
    --------
    >>> texts = [Path('data/raw/Brazil_1988.txt'), Path('data/raw/USA_1787.txt')]
    >>> df = get_df(texts)
    >>> df.columns
    Index(['country', 'year', 'constitution'], dtype='object')
    """
    countries, years, constitutions = [], [], []
    for text_path in map(Path, text_files):
        # Extract metadata from filename
        stem = text_path.stem
        country_parts = stem.split('_')[:-1]
        countries.append(' '.join(country_parts))
        years.append(stem.split('_')[-1])
        # Read text content
        with text_path.open('r', encoding='utf-8', errors='ignore') as f:
            constitutions.append(f.read())

    return pd.DataFrame({
        'country': countries,
        'year': years,
        'constitution': constitutions
    })

def lemmatization(texts: Iterable[str], model: str = 'en_core_web_lg') -> List[List[str]]:
    """
    Perform spaCy-based lemmatization on a collection of texts.

    Parameters
    ----------
    texts : Iterable[str]
        Input texts to process
    model : str, optional
        spaCy language model to use (default: 'en_core_web_lg')

    Returns
    -------
    List[List[str]]
        List of lists containing lemmatized tokens per document

    Raises
    ------
    OSError: If spaCy model is not installed

    Examples
    --------
    >>> docs = ["The constitutional amendments...", "We the people..."]
    >>> lemmatize(docs)[0][:3]
    ['the', 'constitutional', 'amendment']
    """
    try:
        nlp = spacy.load(model, disable=['parser', 'ner'])
    except OSError:
        raise OSError(
            f"spaCy model '{model}' not found. Install with:\n"
            f"python -m spacy download {model}"
        )

    return [
        [token.lemma_.lower() for token in doc if not token.is_punct]
        for doc in nlp.pipe(texts, batch_size=50)
    ]

def save_parquet(df: pd.DataFrame, path: Union[str, Path]) -> None:
    """
    Save DataFrame to Parquet format with validation.

    Parameters
    ----------
    df : pd.DataFrame
        DataFrame to save
    path : Union[str, Path]
        Output path with .parquet extension

    Raises
    ------
    ValueError: If path does not end with .parquet
    """
    path = Path(path)
    if path.suffix != '.parquet':
        raise ValueError("Output path must end with .parquet extension")
    
    df.to_parquet(path, engine='pyarrow', compression='snappy')
    logger.info(f"Saved Parquet file: {path}")

def load_parquet(path: Union[str, Path]) -> pd.DataFrame:
    """
    Load Parquet file with validation.

    Parameters
    ----------
    path : Union[str, Path]
        Path to Parquet file

    Returns
    -------
    pd.DataFrame
        Loaded DataFrame
    """
    path = Path(path)
    if not path.exists():
        raise FileNotFoundError(f"Parquet file not found: {path}")
    
    return pd.read_parquet(path)

if __name__ == '__main__':
    # Run environment checks when executed directly
    verify_environment()
    setup_project_dirs()
    logger.info("Project configuration validated successfully")