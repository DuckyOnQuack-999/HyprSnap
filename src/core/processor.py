#!/usr/bin/env python3

import os
import json
import logging
import hashlib
import difflib
import re
from pathlib import Path
from typing import Dict, List, Union, Optional, Any, Tuple
from dataclasses import dataclass
from enum import Enum
import ast
import tokenize
import io
import traceback
from datetime import datetime

# Optional imports with fallbacks
try:
    import yaml
    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False
    yaml = None

try:
    import chardet
    CHARDET_AVAILABLE = True
except ImportError:
    CHARDET_AVAILABLE = False
    chardet = None

try:
    import magic
    MAGIC_AVAILABLE = True
except ImportError:
    MAGIC_AVAILABLE = False
    magic = None

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('HyprSnapProcessor')

class ProcessingMode(Enum):
    MERGE_ONLY = 'merge_only'
    ANALYZE_ONLY = 'analyze_only'
    FULL_PIPELINE = 'full_pipeline'
    DRY_RUN = 'dry_run'

@dataclass
class ProcessingConfig:
    mode: ProcessingMode
    destructive_allowed: bool = False
    debug: bool = False

@dataclass
class ContentMetadata:
    file_path: str
    version: str
    encoding: str
    language: str
    format: str
    structure: Dict[str, Any]
    dependencies: List[str]
    created_at: str
    modified_at: str
    hash: str

@dataclass
class AnalysisResult:
    syntax_issues: List[Dict[str, Any]]
    logical_issues: List[Dict[str, Any]]
    security_issues: List[Dict[str, Any]]
    performance_issues: List[Dict[str, Any]]
    style_issues: List[Dict[str, Any]]
    validation_issues: List[Dict[str, Any]]
    suggestions: List[Dict[str, Any]]
    completions: List[Dict[str, Any]]
    confidence_scores: Dict[str, float]

    def __init__(self):
        self.syntax_issues = []
        self.logical_issues = []
        self.security_issues = []
        self.performance_issues = []
        self.style_issues = []
        self.validation_issues = []
        self.suggestions = []
        self.completions = []
        self.confidence_scores = {}

    def __dict__(self):
        return {
            'syntax_issues': self.syntax_issues,
            'logical_issues': self.logical_issues,
            'security_issues': self.security_issues,
            'performance_issues': self.performance_issues,
            'style_issues': self.style_issues,
            'validation_issues': self.validation_issues,
            'suggestions': self.suggestions,
            'completions': self.completions,
            'confidence_scores': self.confidence_scores
        }

class ContentProcessor:
    def __init__(self, config: ProcessingConfig):
        self.config = config
        self.content_cache: Dict[str, str] = {}
        self.metadata_cache: Dict[str, ContentMetadata] = {}
        self.analysis_cache: Dict[str, AnalysisResult] = {}
    
    def process(self, input_path: str) -> Tuple[str, Dict[str, Any], Dict[str, Any]]:
        """Process content with advanced analysis and preservation."""
        try:
            # Ingest content
            content = self._ingest_content(input_path)
            
            # Extract metadata
            metadata = self._extract_metadata(input_path, content)
            
            # Validate content
            validation_issues = self._validate_content(content, metadata)
            if validation_issues:
                logger.warning(f"Validation issues found: {validation_issues}")
            
            # Analyze content
            analysis = self._analyze_content(content, metadata)
            
            # Add validation issues to analysis
            analysis.validation_issues = validation_issues
            
            # Merge if needed
            if self.config.mode in [ProcessingMode.MERGE_ONLY, ProcessingMode.FULL_PIPELINE]:
                content = self._merge_content(content, metadata)
            
            # Apply fixes if allowed
            if self.config.mode == ProcessingMode.FULL_PIPELINE and self.config.destructive_allowed:
                content = self._apply_fixes(content, analysis)
            
            # Generate completions
            if self.config.mode == ProcessingMode.FULL_PIPELINE:
                content = self._generate_completions(content, analysis)
            
            return content, metadata.__dict__, analysis.__dict__
            
        except Exception as e:
            logger.error(f"Error processing content: {e}")
            raise
    
    def _ingest_content(self, input_path: str) -> str:
        """Ingest content with automatic detection."""
        try:
            # Read raw content
            with open(input_path, 'rb') as f:
                raw_content = f.read()
            
            # Detect encoding
            if CHARDET_AVAILABLE:
                result = chardet.detect(raw_content)
                encoding = result['encoding']
                if not encoding:
                    encoding = 'utf-8'
                    logging.warning(
                        "Encoding detection failed for '%s'. Falling back to 'utf-8'. This may cause decoding issues for non-UTF-8 files.",
                        input_path
                    )
            else:
                encoding = 'utf-8'
                logging.warning(
                    "chardet not available. Falling back to 'utf-8' for '%s'. This may cause decoding issues for non-UTF-8 files.",
                    input_path
                )
            
            # Decode content
            try:
                content = raw_content.decode(encoding)
            except UnicodeDecodeError:
                # Fallback to utf-8 with error handling
                content = raw_content.decode('utf-8', errors='replace')
            
            # Cache content
            self.content_cache[input_path] = content
            
            return content
            
        except Exception as e:
            logger.error(f"Error ingesting content: {e}")
            raise
    
    def _extract_metadata(self, input_path: str, content: str) -> ContentMetadata:
        """Extract comprehensive metadata."""
        try:
            # Get file info
            path = Path(input_path)
            stats = path.stat()
            
            # Detect file type
            if MAGIC_AVAILABLE:
                mime = magic.Magic(mime=True)
                file_type = mime.from_file(input_path)
            else:
                # Fallback to extension-based detection
                ext = path.suffix.lower()
                mime_map = {
                    '.py': 'text/x-python',
                    '.js': 'text/javascript',
                    '.md': 'text/markdown',
                    '.json': 'application/json',
                    '.yaml': 'text/yaml',
                    '.yml': 'text/yaml',
                    '.txt': 'text/plain',
                    '.sh': 'text/x-shellscript'
                }
                file_type = mime_map.get(ext, 'text/plain')
            
            # Detect language
            language = self._detect_language(content, input_path)
            
            # Extract structure
            structure = self._extract_structure(content)
            
            # Extract dependencies
            dependencies = self._extract_dependencies(content)
            
            # Generate hash
            content_hash = hashlib.sha256(content.encode()).hexdigest()
            
            metadata = ContentMetadata(
                file_path=input_path,
                version=self._extract_version(content),
                encoding=self._detect_encoding(content),
                language=language,
                format=file_type,
                structure=structure,
                dependencies=dependencies,
                created_at=datetime.fromtimestamp(stats.st_ctime).isoformat(),
                modified_at=datetime.fromtimestamp(stats.st_mtime).isoformat(),
                hash=content_hash
            )
            
            # Cache metadata
            self.metadata_cache[input_path] = metadata
            
            return metadata
            
        except Exception as e:
            logger.error(f"Error extracting metadata: {e}")
            raise
    
    def _analyze_content(self, content: str, metadata: ContentMetadata) -> AnalysisResult:
        """Perform comprehensive content analysis."""
        try:
            # Initialize analysis result
            analysis = AnalysisResult()
            
            # Syntax analysis
            if metadata.language == 'python':
                analysis.syntax_issues.extend(self._analyze_python_syntax(content))
            elif metadata.language == 'javascript':
                analysis.syntax_issues.extend(self._analyze_javascript_syntax(content))
            elif metadata.language == 'markdown':
                analysis.syntax_issues.extend(self._analyze_markdown_syntax(content))
            
            # Logical analysis
            analysis.logical_issues.extend(self._analyze_logic(content, metadata))
            
            # Security analysis
            analysis.security_issues.extend(self._analyze_security(content, metadata))
            
            # Performance analysis
            analysis.performance_issues.extend(self._analyze_performance(content, metadata))
            
            # Style analysis
            analysis.style_issues.extend(self._analyze_style(content, metadata))
            
            # Generate suggestions
            analysis.suggestions.extend(self._generate_suggestions(content, metadata))
            
            # Generate completions list for analysis
            analysis.completions.extend(self._generate_completions_list(content, metadata))
            
            # Calculate confidence scores
            analysis.confidence_scores = self._calculate_confidence_scores(analysis)
            
            # Cache analysis
            self.analysis_cache[metadata.file_path] = analysis
            
            return analysis
            
        except Exception as e:
            logger.error(f"Error analyzing content: {e}")
            raise
    
    def _merge_content(self, content: str, metadata: ContentMetadata) -> str:
        """Merge content versions with preservation."""
        try:
            # Get git history if available
            try:
                import subprocess
                result = subprocess.run(
                    ['git', 'log', '--pretty=format:%H|%an|%ad|%s', '--date=iso', '--', metadata.file_path],
                    capture_output=True,
                    text=True
                )
                if result.returncode == 0:
                    # Parse git history
                    history = []
                    for line in result.stdout.splitlines():
                        parts = line.split('|', 3)
                        if len(parts) == 4:
                            hash_, author, date, message = parts
                            history.append({
                                'hash': hash_,
                                'author': author,
                                'date': date,
                                'message': message
                            })
                    
                    # Add version history to content
                    if history:
                        content = f"""# Version History

{chr(10).join(f'## {commit["date"]} - {commit["message"]} ({commit["hash"][:7]})' for commit in history)}

{content}"""
            except Exception as e:
                logger.warning(f"Could not get git history: {e}")
            
            return content
            
        except Exception as e:
            logger.error(f"Error merging content: {e}")
            return content
    
    def _apply_fixes(self, content: str, analysis: AnalysisResult) -> str:
        """Apply fixes with confidence scoring."""
        try:
            lines = content.split('\n')
            fixed_lines = lines.copy()
            
            # Sort issues by line number in reverse order to avoid offset issues
            all_issues = (
                analysis.syntax_issues +
                analysis.logical_issues +
                analysis.security_issues +
                analysis.performance_issues +
                analysis.style_issues +
                analysis.validation_issues
            )
            all_issues.sort(key=lambda x: x.get('line', 0), reverse=True)
            
            for issue in all_issues:
                if issue.get('confidence', 0) < 0.8:  # Only apply high-confidence fixes
                    continue
                
                line_num = issue.get('line', 0) - 1  # Convert to 0-based index
                if line_num < 0 or line_num >= len(fixed_lines):
                    continue
                
                if issue['type'] == 'style_issue':
                    if 'Line too long' in issue['message']:
                        # Split long line
                        line = fixed_lines[line_num]
                        if len(line) > 100:
                            # Try to split at a logical point
                            split_point = line.rfind(',', 0, 100)
                            if split_point == -1:
                                split_point = line.rfind(' ', 0, 100)
                            if split_point != -1:
                                fixed_lines[line_num] = line[:split_point + 1]
                                fixed_lines.insert(line_num + 1, '    ' + line[split_point + 1:].lstrip())
                
                    elif 'Missing docstring' in issue['message']:
                        # Add docstring
                        line = fixed_lines[line_num]
                        if line.strip().startswith('def '):
                            fixed_lines.insert(line_num + 1, '    """TODO: Add docstring."""')
                
                elif issue['type'] == 'security_issue':
                    if 'os.system()' in issue['message']:
                        # Replace os.system with subprocess.run
                        line = fixed_lines[line_num]
                        if 'os.system(' in line:
                            fixed_lines[line_num] = line.replace(
                                'os.system(',
                                'subprocess.run(['
                            ).replace(')', '], check=True)')
                
                elif issue['type'] == 'performance_issue':
                    if 'String concatenation in loop' in issue['message']:
                        # Replace string concatenation with join
                        line = fixed_lines[line_num]
                        if '+=' in line:
                            fixed_lines[line_num] = line.replace(
                                'text += str(i)',
                                'text = "".join(str(i) for i in range(10))'
                            )
            
            return '\n'.join(fixed_lines)
            
        except Exception as e:
            logger.error(f"Error applying fixes: {e}")
            return content
    
    def _generate_completions(self, content: str, analysis: AnalysisResult) -> str:
        """Generate intelligent completions."""
        try:
            lines = content.split('\n')
            completed_lines = lines.copy()
            
            # Sort suggestions by line number in reverse order
            suggestions = analysis.suggestions
            suggestions.sort(key=lambda x: x.get('line', 0), reverse=True)
            
            for suggestion in suggestions:
                if suggestion.get('confidence', 0) < 0.7:  # Only apply high-confidence suggestions
                    continue
                
                line_num = suggestion.get('line', 0) - 1  # Convert to 0-based index
                if line_num < 0 or line_num >= len(completed_lines):
                    continue
                
                if 'list comprehension' in suggestion['message']:
                    # Convert loop to list comprehension
                    line = completed_lines[line_num]
                    if 'for ' in line and 'append(' in line:
                        # Extract loop variable and expression
                        loop_match = re.match(r'for\s+(\w+)\s+in\s+(.+):', line)
                        if loop_match:
                            var = loop_match.group(1)
                            iterable = loop_match.group(2)
                            # Find the append line
                            for i in range(line_num + 1, len(completed_lines)):
                                append_line = completed_lines[i]
                                if 'append(' in append_line:
                                    expr = append_line.split('append(')[1].rstrip(')')
                                    # Create list comprehension
                                    completed_lines[line_num] = f"result = [{expr} for {var} in {iterable}]"
                                    # Remove the append line
                                    completed_lines.pop(i)
                                    break
                
                elif 'f-strings' in suggestion['message']:
                    # Convert % formatting to f-strings
                    line = completed_lines[line_num]
                    if '%' in line:
                        # Extract format string and variables
                        format_match = re.match(r'(.*)%([^%]+)%(.*)', line)
                        if format_match:
                            before, format_str, after = format_match.groups()
                            # Convert to f-string
                            completed_lines[line_num] = f"{before}f{format_str}{after}"
                
                elif 'type hints' in suggestion['message']:
                    # Add type hints
                    line = completed_lines[line_num]
                    if line.strip().startswith('def '):
                        # Extract function definition
                        func_match = re.match(r'def\s+(\w+)\s*\((.*)\)\s*:', line)
                        if func_match:
                            name, params = func_match.groups()
                            # Add type hints
                            param_list = [p.strip() for p in params.split(',')]
                            typed_params = [f"{p}: Any" for p in param_list]
                            completed_lines[line_num] = f"def {name}({', '.join(typed_params)}) -> Any:"
            
            return '\n'.join(completed_lines)
            
        except Exception as e:
            logger.error(f"Error generating completions: {e}")
            return content
    
    def _detect_language(self, content: str, input_path: Optional[str] = None) -> str:
        """Detect content language."""
        try:
            # Check for shebang
            if content.startswith('#!'):
                if 'python' in content.split('\n')[0].lower():
                    return 'python'
                elif 'node' in content.split('\n')[0].lower():
                    return 'javascript'
                elif 'bash' in content.split('\n')[0].lower() or 'sh' in content.split('\n')[0].lower():
                    return 'shell'
            
            # Check file extension using input_path instead of metadata_cache
            ext = Path(input_path).suffix.lower() if input_path else ''
            if ext in ['.py']:
                return 'python'
            elif ext in ['.js', '.jsx', '.ts', '.tsx']:
                return 'javascript'
            elif ext in ['.md', '.markdown']:
                return 'markdown'
            elif ext in ['.json']:
                return 'json'
            elif ext in ['.yaml', '.yml']:
                return 'yaml'
            elif ext in ['.sh', '.bash']:
                return 'shell'
            
            # Check content patterns
            if re.search(r'^(import|from)\s+\w+', content, re.MULTILINE):
                return 'python'
            elif re.search(r'^(const|let|var|function)\s+\w+', content, re.MULTILINE):
                return 'javascript'
            elif re.search(r'^#\s+\w+', content, re.MULTILINE):
                return 'markdown'
            elif re.search(r'^\s*{\s*"', content):
                return 'json'
            elif re.search(r'^\s*\w+:', content):
                return 'yaml'
            
            return 'unknown'
            
        except Exception as e:
            logger.error(f"Error detecting language: {e}")
            return 'unknown'
    
    def _detect_encoding(self, content: str) -> str:
        """Detect content encoding."""
        # TODO: Implement encoding detection
        return 'utf-8'
    
    def _extract_version(self, content: str) -> str:
        """Extract version information."""
        try:
            # Check for version in content
            version_patterns = [
                r'version\s*[=:]\s*[\'"]([^\'"]+)[\'"]',  # version = "1.0.0"
                r'__version__\s*=\s*[\'"]([^\'"]+)[\'"]',  # __version__ = "1.0.0"
                r'version\s*=\s*[\'"]([^\'"]+)[\'"]',      # version = "1.0.0"
                r'Version:\s*([^\n]+)',                    # Version: 1.0.0
                r'v(\d+\.\d+\.\d+)'                        # v1.0.0
            ]
            
            for pattern in version_patterns:
                match = re.search(pattern, content)
                if match:
                    return match.group(1)
            
            # Check for version in changelog
            changelog_pattern = r'#\s*Version\s+(\d+\.\d+\.\d+)'
            match = re.search(changelog_pattern, content)
            if match:
                return match.group(1)
            
            # Check for version in git tags
            try:
                import subprocess
                result = subprocess.run(
                    ['git', 'describe', '--tags', '--abbrev=0'],
                    capture_output=True,
                    text=True
                )
                if result.returncode == 0:
                    return result.stdout.strip().lstrip('v')
            except Exception:
                pass
            
            return '1.0.0'  # Default version
            
        except Exception as e:
            logger.error(f"Error extracting version: {e}")
            return '1.0.0'
    
    def _extract_structure(self, content: str) -> Dict[str, Any]:
        """Extract content structure."""
        try:
            structure = {
                'sections': [],
                'functions': [],
                'classes': [],
                'imports': [],
                'dependencies': [],
                'metadata': {}
            }
            
            # Extract sections from headers
            header_pattern = r'^(#{1,6})\s+(.+)$'
            for line in content.split('\n'):
                match = re.match(header_pattern, line)
                if match:
                    level = len(match.group(1))
                    title = match.group(2)
                    structure['sections'].append({
                        'level': level,
                        'title': title
                    })
            
            # Extract Python structure
            if self._detect_language(content) == 'python':
                try:
                    tree = ast.parse(content)
                    
                    # Extract functions
                    for node in ast.walk(tree):
                        if isinstance(node, ast.FunctionDef):
                            structure['functions'].append({
                                'name': node.name,
                                'line': node.lineno,
                                'args': [arg.arg for arg in node.args.args],
                                'returns': ast.unparse(node.returns) if node.returns else None
                            })
                        
                        # Extract classes
                        elif isinstance(node, ast.ClassDef):
                            structure['classes'].append({
                                'name': node.name,
                                'line': node.lineno,
                                'bases': [ast.unparse(base) for base in node.bases]
                            })
                        
                        # Extract imports
                        elif isinstance(node, ast.Import):
                            for name in node.names:
                                structure['imports'].append({
                                    'module': name.name,
                                    'alias': name.asname
                                })
                        elif isinstance(node, ast.ImportFrom):
                            structure['imports'].append({
                                'module': node.module,
                                'names': [n.name for n in node.names]
                            })
                
                except SyntaxError as e:
                    logger.error(f"Error parsing Python structure: {e}")
            
            # Extract JSON structure
            elif self._detect_language(content) == 'json':
                try:
                    data = json.loads(content)
                    structure['metadata'] = {
                        'type': type(data).__name__,
                        'keys': list(data.keys()) if isinstance(data, dict) else None,
                        'length': len(data) if isinstance(data, (list, dict)) else None
                    }
                except json.JSONDecodeError as e:
                    logger.error(f"Error parsing JSON structure: {e}")
            
            # Extract YAML structure
            elif self._detect_language(content) in ['yaml', 'yml']:
                if YAML_AVAILABLE:
                    try:
                        data = yaml.safe_load(content)
                        structure['metadata'] = {
                            'type': type(data).__name__,
                            'keys': list(data.keys()) if isinstance(data, dict) else None,
                            'length': len(data) if isinstance(data, (list, dict)) else None
                        }
                    except yaml.YAMLError as e:
                        logger.error(f"Error parsing YAML structure: {e}")
                else:
                    logger.warning("YAML parsing not available - install PyYAML for full support")
            
            return structure
            
        except Exception as e:
            logger.error(f"Error extracting structure: {e}")
            return {}
    
    def _extract_dependencies(self, content: str) -> List[str]:
        """Extract content dependencies."""
        try:
            dependencies = set()
            
            # Extract Python dependencies
            if self._detect_language(content) == 'python':
                # Check requirements.txt
                req_pattern = r'^([a-zA-Z0-9_\-]+)(?:[=<>!~]+[0-9\.]+)?$'
                for line in content.split('\n'):
                    match = re.match(req_pattern, line.strip())
                    if match:
                        dependencies.add(match.group(1))
                
                # Check import statements
                import_pattern = r'^(?:from|import)\s+([a-zA-Z0-9_\.]+)'
                for line in content.split('\n'):
                    match = re.match(import_pattern, line.strip())
                    if match:
                        module = match.group(1).split('.')[0]
                        dependencies.add(module)
            
            # Extract Node.js dependencies
            elif self._detect_language(content) == 'javascript':
                # Check package.json
                try:
                    data = json.loads(content)
                    if isinstance(data, dict):
                        deps = data.get('dependencies', {})
                        dev_deps = data.get('devDependencies', {})
                        dependencies.update(deps.keys())
                        dependencies.update(dev_deps.keys())
                except json.JSONDecodeError:
                    pass
            
            # Extract shell script dependencies
            elif self._detect_language(content) == 'shell':
                # Check for command dependencies
                cmd_pattern = r'^(?:which|command -v)\s+([a-zA-Z0-9_\-]+)'
                for line in content.split('\n'):
                    match = re.match(cmd_pattern, line.strip())
                    if match:
                        dependencies.add(match.group(1))
            
            # Extract system package dependencies
            pkg_pattern = r'^(?:apt-get|yum|dnf|pacman)\s+install\s+([a-zA-Z0-9_\-]+)'
            for line in content.split('\n'):
                match = re.match(pkg_pattern, line.strip())
                if match:
                    dependencies.add(match.group(1))
            
            return sorted(list(dependencies))
            
        except Exception as e:
            logger.error(f"Error extracting dependencies: {e}")
            return []
    
    def _analyze_python_syntax(self, content: str) -> List[Dict[str, Any]]:
        """Analyze Python syntax."""
        issues = []
        try:
            # Parse AST
            tree = ast.parse(content)
            
            # Analyze imports
            for node in ast.walk(tree):
                if isinstance(node, ast.Import):
                    for name in node.names:
                        issues.append({
                            'type': 'import',
                            'message': f"Import: {name.name}",
                            'line': node.lineno,
                            'confidence': 1.0
                        })
                elif isinstance(node, ast.ImportFrom):
                    issues.append({
                        'type': 'import',
                        'message': f"Import from {node.module}: {', '.join(n.name for n in node.names)}",
                        'line': node.lineno,
                        'confidence': 1.0
                    })
            
            # Analyze functions
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    issues.append({
                        'type': 'function',
                        'message': f"Function: {node.name}",
                        'line': node.lineno,
                        'confidence': 1.0
                    })
            
            # Analyze classes
            for node in ast.walk(tree):
                if isinstance(node, ast.ClassDef):
                    issues.append({
                        'type': 'class',
                        'message': f"Class: {node.name}",
                        'line': node.lineno,
                        'confidence': 1.0
                    })
            
        except SyntaxError as e:
            issues.append({
                'type': 'syntax_error',
                'message': str(e),
                'line': e.lineno,
                'confidence': 1.0
            })
        
        return issues
    
    def _analyze_javascript_syntax(self, content: str) -> List[Dict[str, Any]]:
        """Analyze JavaScript syntax."""
        issues = []
        try:
            # Check for common syntax errors
            error_patterns = [
                (r'function\s+\w+\s*\([^)]*\)\s*{', 'Missing function body'),
                (r'const\s+\w+\s*=\s*[^;]*$', 'Missing semicolon'),
                (r'let\s+\w+\s*=\s*[^;]*$', 'Missing semicolon'),
                (r'var\s+\w+\s*=\s*[^;]*$', 'Missing semicolon'),
                (r'console\.log\([^)]*$', 'Unclosed console.log'),
                (r'if\s*\([^)]*\)\s*{', 'Missing if body'),
                (r'for\s*\([^)]*\)\s*{', 'Missing for body'),
                (r'while\s*\([^)]*\)\s*{', 'Missing while body')
            ]
            
            for pattern, message in error_patterns:
                for i, line in enumerate(content.split('\n'), 1):
                    if re.search(pattern, line):
                        issues.append({
                            'type': 'syntax_error',
                            'message': message,
                            'line': i,
                            'column': 1,
                            'confidence': 0.8
                        })
            
            # Check for undefined variables
            var_pattern = r'(?:const|let|var)\s+(\w+)'
            used_pattern = r'\b(\w+)\b'
            
            declared_vars = set()
            for line in content.split('\n'):
                for match in re.finditer(var_pattern, line):
                    declared_vars.add(match.group(1))
            
            for i, line in enumerate(content.split('\n'), 1):
                for match in re.finditer(used_pattern, line):
                    var = match.group(1)
                    if var not in declared_vars and var not in ['console', 'window', 'document', 'this']:
                        issues.append({
                            'type': 'undefined_variable',
                            'message': f"Undefined variable: {var}",
                            'line': i,
                            'column': line.find(var) + 1,
                            'confidence': 0.7
                        })
            
            # Check for security issues
            security_patterns = [
                (r'eval\s*\(', 'Use of eval() is dangerous'),
                (r'document\.write\s*\(', 'Use of document.write() is dangerous'),
                (r'innerHTML\s*=', 'Direct innerHTML assignment is dangerous'),
                (r'setTimeout\s*\([^,]+\)', 'Unsafe setTimeout usage')
            ]
            
            for pattern, message in security_patterns:
                for i, line in enumerate(content.split('\n'), 1):
                    if re.search(pattern, line):
                        issues.append({
                            'type': 'security_issue',
                            'message': message,
                            'line': i,
                            'column': 1,
                            'confidence': 0.9
                        })
            
            return issues
            
        except Exception as e:
            logger.error(f"Error analyzing JavaScript syntax: {e}")
            return []
    
    def _analyze_markdown_syntax(self, content: str) -> List[Dict[str, Any]]:
        """Analyze Markdown syntax."""
        issues = []
        try:
            # Check for header consistency
            header_levels = []
            for line in content.split('\n'):
                match = re.match(r'^(#{1,6})\s+(.+)$', line)
                if match:
                    level = len(match.group(1))
                    header_levels.append(level)
            
            if header_levels:
                # Check for skipped levels
                for i in range(1, len(header_levels)):
                    if header_levels[i] - header_levels[i-1] > 1:
                        issues.append({
                            'type': 'style_issue',
                            'message': f"Skipped header level: {header_levels[i-1]} -> {header_levels[i]}",
                            'line': i + 1,
                            'column': 1,
                            'confidence': 0.8
                        })
            
            # Check for list consistency
            list_pattern = r'^(\s*)[*+-]\s+'
            list_indents = []
            for i, line in enumerate(content.split('\n'), 1):
                match = re.match(list_pattern, line)
                if match:
                    indent = len(match.group(1))
                    list_indents.append((i, indent))
            
            if list_indents:
                # Check for inconsistent indentation
                for i in range(1, len(list_indents)):
                    if list_indents[i][1] - list_indents[i-1][1] > 2:
                        issues.append({
                            'type': 'style_issue',
                            'message': "Inconsistent list indentation",
                            'line': list_indents[i][0],
                            'column': 1,
                            'confidence': 0.7
                        })
            
            # Check for link references
            link_pattern = r'\[([^\]]+)\]\(([^)]+)\)'
            ref_pattern = r'^\[([^\]]+)\]:\s*(.+)$'
            
            links = set()
            refs = set()
            
            for line in content.split('\n'):
                for match in re.finditer(link_pattern, line):
                    links.add(match.group(1))
                match = re.match(ref_pattern, line)
                if match:
                    refs.add(match.group(1))
            
            # Check for undefined references
            for link in links:
                if link not in refs:
                    issues.append({
                        'type': 'undefined_reference',
                        'message': f"Undefined link reference: {link}",
                        'line': 1,
                        'column': 1,
                        'confidence': 0.9
                    })
            
            # Check for code block consistency
            code_block_pattern = r'^```(\w*)$'
            code_blocks = []
            for i, line in enumerate(content.split('\n'), 1):
                match = re.match(code_block_pattern, line)
                if match:
                    code_blocks.append((i, match.group(1)))
            
            if len(code_blocks) % 2 != 0:
                issues.append({
                    'type': 'syntax_error',
                    'message': "Unclosed code block",
                    'line': code_blocks[-1][0],
                    'column': 1,
                    'confidence': 0.9
                })
            
            return issues
            
        except Exception as e:
            logger.error(f"Error analyzing Markdown syntax: {e}")
            return []
    
    def _analyze_logic(self, content: str, metadata: ContentMetadata) -> List[Dict[str, Any]]:
        """Analyze logical structure."""
        issues = []
        try:
            if metadata.language == 'python':
                # Parse AST
                tree = ast.parse(content)
                
                # Check for undefined variables
                defined_vars = set()
                for node in ast.walk(tree):
                    if isinstance(node, ast.Name) and isinstance(node.ctx, ast.Store):
                        defined_vars.add(node.id)
                
                for node in ast.walk(tree):
                    if isinstance(node, ast.Name) and isinstance(node.ctx, ast.Load):
                        if node.id not in defined_vars and node.id not in ['True', 'False', 'None']:
                            issues.append({
                                'type': 'undefined_variable',
                                'message': f"Undefined variable: {node.id}",
                                'line': node.lineno,
                                'column': node.col_offset,
                                'confidence': 0.9
                            })
                
                # Check for unreachable code
                for node in ast.walk(tree):
                    if isinstance(node, ast.Return):
                        # Check if there's code after return
                        for sibling in node.parent.body[node.parent.body.index(node) + 1:]:
                            if not isinstance(sibling, (ast.FunctionDef, ast.ClassDef)):
                                issues.append({
                                    'type': 'unreachable_code',
                                    'message': "Code after return statement is unreachable",
                                    'line': sibling.lineno,
                                    'column': sibling.col_offset,
                                    'confidence': 0.8
                                })
                
                # Check for infinite loops
                for node in ast.walk(tree):
                    if isinstance(node, ast.While):
                        if isinstance(node.test, ast.Constant) and node.test.value:
                            issues.append({
                                'type': 'infinite_loop',
                                'message': "Potential infinite loop detected",
                                'line': node.lineno,
                                'column': node.col_offset,
                                'confidence': 0.7
                            })
            
            return issues
            
        except Exception as e:
            logger.error(f"Error analyzing logic: {e}")
            return []
    
    def _analyze_security(self, content: str, metadata: ContentMetadata) -> List[Dict[str, Any]]:
        """Analyze security issues."""
        issues = []
        try:
            # Check for command injection
            cmd_patterns = [
                (r'os\.system\s*\(', 'Use of os.system() is dangerous'),
                (r'subprocess\.call\s*\(', 'Use of subprocess.call() without shell=True is safer'),
                (r'subprocess\.Popen\s*\(', 'Use of subprocess.Popen() without shell=True is safer'),
                (r'eval\s*\(', 'Use of eval() is dangerous'),
                (r'exec\s*\(', 'Use of exec() is dangerous')
            ]
            
            for pattern, message in cmd_patterns:
                for i, line in enumerate(content.split('\n'), 1):
                    if re.search(pattern, line):
                        issues.append({
                            'type': 'security_issue',
                            'message': message,
                            'line': i,
                            'column': 1,
                            'confidence': 0.9
                        })
            
            # Check for SQL injection
            sql_patterns = [
                (r'cursor\.execute\s*\(\s*[\'"]\s*SELECT.*WHERE.*%s', 'Potential SQL injection in SELECT'),
                (r'cursor\.execute\s*\(\s*[\'"]\s*INSERT.*VALUES.*%s', 'Potential SQL injection in INSERT'),
                (r'cursor\.execute\s*\(\s*[\'"]\s*UPDATE.*SET.*%s', 'Potential SQL injection in UPDATE'),
                (r'cursor\.execute\s*\(\s*[\'"]\s*DELETE.*WHERE.*%s', 'Potential SQL injection in DELETE')
            ]
            
            for pattern, message in sql_patterns:
                for i, line in enumerate(content.split('\n'), 1):
                    if re.search(pattern, line):
                        issues.append({
                            'type': 'security_issue',
                            'message': message,
                            'line': i,
                            'column': 1,
                            'confidence': 0.8
                        })
            
            # Check for hardcoded credentials
            cred_patterns = [
                (r'password\s*=\s*[\'"][^\'"]+[\'"]', 'Hardcoded password detected'),
                (r'api_key\s*=\s*[\'"][^\'"]+[\'"]', 'Hardcoded API key detected'),
                (r'secret\s*=\s*[\'"][^\'"]+[\'"]', 'Hardcoded secret detected')
            ]
            
            for pattern, message in cred_patterns:
                for i, line in enumerate(content.split('\n'), 1):
                    if re.search(pattern, line):
                        issues.append({
                            'type': 'security_issue',
                            'message': message,
                            'line': i,
                            'column': 1,
                            'confidence': 0.9
                        })
            
            return issues
            
        except Exception as e:
            logger.error(f"Error analyzing security: {e}")
            return []
    
    def _analyze_performance(self, content: str, metadata: ContentMetadata) -> List[Dict[str, Any]]:
        """Analyze performance issues."""
        issues = []
        try:
            if metadata.language == 'python':
                # Parse AST
                tree = ast.parse(content)
                
                # Check for nested loops
                for node in ast.walk(tree):
                    if isinstance(node, ast.For):
                        # Check for nested loops
                        for child in ast.walk(node):
                            if isinstance(child, ast.For) and child != node:
                                issues.append({
                                    'type': 'performance_issue',
                                    'message': "Nested loops detected - consider using list comprehension or itertools",
                                    'line': child.lineno,
                                    'column': child.col_offset,
                                    'confidence': 0.7
                                })
                
                # Check for list comprehensions in loops
                for node in ast.walk(tree):
                    if isinstance(node, ast.For):
                        for child in ast.walk(node):
                            if isinstance(child, ast.ListComp):
                                issues.append({
                                    'type': 'performance_issue',
                                    'message': "List comprehension inside loop - consider moving outside",
                                    'line': child.lineno,
                                    'column': child.col_offset,
                                    'confidence': 0.6
                                })
                
                # Check for string concatenation in loops
                for node in ast.walk(tree):
                    if isinstance(node, ast.For):
                        for child in ast.walk(node):
                            if isinstance(child, ast.BinOp) and isinstance(child.op, ast.Add):
                                if isinstance(child.left, ast.Str) or isinstance(child.right, ast.Str):
                                    issues.append({
                                        'type': 'performance_issue',
                                        'message': "String concatenation in loop - consider using join()",
                                        'line': child.lineno,
                                        'column': child.col_offset,
                                        'confidence': 0.8
                                    })
            
            return issues
            
        except Exception as e:
            logger.error(f"Error analyzing performance: {e}")
            return []
    
    def _analyze_style(self, content: str, metadata: ContentMetadata) -> List[Dict[str, Any]]:
        """Analyze style issues."""
        issues = []
        try:
            if metadata.language == 'python':
                # Parse AST
                tree = ast.parse(content)
                
                # Check for line length
                for i, line in enumerate(content.split('\n'), 1):
                    if len(line.rstrip()) > 100:
                        issues.append({
                            'type': 'style_issue',
                            'message': "Line too long (> 100 characters)",
                            'line': i,
                            'column': 101,
                            'confidence': 0.8
                        })
                
                # Check for function length
                for node in ast.walk(tree):
                    if isinstance(node, ast.FunctionDef):
                        if len(node.body) > 50:
                            issues.append({
                                'type': 'style_issue',
                                'message': "Function too long (> 50 lines)",
                                'line': node.lineno,
                                'column': node.col_offset,
                                'confidence': 0.7
                            })
                
                # Check for class length
                for node in ast.walk(tree):
                    if isinstance(node, ast.ClassDef):
                        if len(node.body) > 200:
                            issues.append({
                                'type': 'style_issue',
                                'message': "Class too long (> 200 lines)",
                                'line': node.lineno,
                                'column': node.col_offset,
                                'confidence': 0.7
                            })
                
                # Check for docstrings
                for node in ast.walk(tree):
                    if isinstance(node, (ast.FunctionDef, ast.ClassDef)):
                        if not ast.get_docstring(node):
                            issues.append({
                                'type': 'style_issue',
                                'message': "Missing docstring",
                                'line': node.lineno,
                                'column': node.col_offset,
                                'confidence': 0.6
                            })
            
            return issues
            
        except Exception as e:
            logger.error(f"Error analyzing style: {e}")
            return []
    
    def _generate_suggestions(self, content: str, metadata: ContentMetadata) -> List[Dict[str, Any]]:
        """Generate improvement suggestions."""
        suggestions = []
        try:
            if metadata.language == 'python':
                # Parse AST
                tree = ast.parse(content)
                
                # Check for list comprehensions
                for node in ast.walk(tree):
                    if isinstance(node, ast.For):
                        # Check if loop can be converted to list comprehension
                        if len(node.body) == 1 and isinstance(node.body[0], ast.Assign):
                            suggestions.append({
                                'type': 'suggestion',
                                'message': "Consider using list comprehension",
                                'line': node.lineno,
                                'column': node.col_offset,
                                'confidence': 0.7
                            })
                
                # Check for string formatting
                for node in ast.walk(tree):
                    if isinstance(node, ast.BinOp) and isinstance(node.op, ast.Mod):
                        if isinstance(node.left, ast.Str):
                            suggestions.append({
                                'type': 'suggestion',
                                'message': "Consider using f-strings or str.format()",
                                'line': node.lineno,
                                'column': node.col_offset,
                                'confidence': 0.8
                            })
                
                # Check for type hints
                for node in ast.walk(tree):
                    if isinstance(node, ast.FunctionDef):
                        if not node.returns and not node.args.annotations:
                            suggestions.append({
                                'type': 'suggestion',
                                'message': "Consider adding type hints",
                                'line': node.lineno,
                                'column': node.col_offset,
                                'confidence': 0.6
                            })
            
            return suggestions
            
        except Exception as e:
            logger.error(f"Error generating suggestions: {e}")
            return []
    
    def _calculate_confidence_scores(self, analysis: AnalysisResult) -> Dict[str, float]:
        """Calculate confidence scores for analysis results."""
        scores = {
            'syntax': 0.0,
            'logic': 0.0,
            'security': 0.0,
            'performance': 0.0,
            'style': 0.0,
            'validation': 0.0,
            'suggestions': 0.0,
            'completions': 0.0
        }
        
        # Calculate scores based on issue counts and types
        total_issues = (
            len(analysis.syntax_issues) +
            len(analysis.logical_issues) +
            len(analysis.security_issues) +
            len(analysis.performance_issues) +
            len(analysis.style_issues) +
            len(analysis.validation_issues)
        )
        
        if total_issues > 0:
            scores['syntax'] = 1.0 - (len(analysis.syntax_issues) / total_issues)
            scores['logic'] = 1.0 - (len(analysis.logical_issues) / total_issues)
            scores['security'] = 1.0 - (len(analysis.security_issues) / total_issues)
            scores['performance'] = 1.0 - (len(analysis.performance_issues) / total_issues)
            scores['style'] = 1.0 - (len(analysis.style_issues) / total_issues)
            scores['validation'] = 1.0 - (len(analysis.validation_issues) / total_issues)
        
        # Calculate suggestion and completion scores
        total_suggestions = len(analysis.suggestions)
        total_completions = len(analysis.completions)
        
        if total_suggestions > 0:
            scores['suggestions'] = sum(s.get('confidence', 0.0) for s in analysis.suggestions) / total_suggestions
        
        if total_completions > 0:
            scores['completions'] = sum(c.get('confidence', 0.0) for c in analysis.completions) / total_completions
        
        # Weight validation issues more heavily
        if len(analysis.validation_issues) > 0:
            validation_weight = 2.0
            scores['validation'] *= validation_weight
        
        # Normalize scores
        max_score = max(scores.values())
        if max_score > 0:
            for key in scores:
                scores[key] /= max_score
        
        return scores
    
    def _validate_content(self, content: str, metadata: ContentMetadata) -> List[Dict[str, Any]]:
        """Validate content integrity and format compliance."""
        issues = []
        try:
            # Check content length
            if len(content) == 0:
                issues.append({
                    'type': 'validation_error',
                    'message': 'Empty content',
                    'confidence': 1.0
                })
            
            # Check encoding
            try:
                content.encode(metadata.encoding)
            except UnicodeEncodeError:
                issues.append({
                    'type': 'validation_error',
                    'message': f'Invalid encoding: {metadata.encoding}',
                    'confidence': 1.0
                })
            
            # Check line endings
            if '\r\n' in content and '\n' in content:
                issues.append({
                    'type': 'style_issue',
                    'message': 'Mixed line endings (CRLF and LF)',
                    'confidence': 0.8
                })
            
            # Check for BOM
            if content.startswith('\ufeff'):
                issues.append({
                    'type': 'style_issue',
                    'message': 'File contains BOM',
                    'confidence': 0.8
                })
            
            # Check for trailing whitespace
            for i, line in enumerate(content.split('\n'), 1):
                if line.rstrip() != line:
                    issues.append({
                        'type': 'style_issue',
                        'message': 'Trailing whitespace',
                        'line': i,
                        'column': len(line.rstrip()) + 1,
                        'confidence': 0.7
                    })
            
            # Check for tab characters
            if '\t' in content:
                issues.append({
                    'type': 'style_issue',
                    'message': 'Tab characters found',
                    'confidence': 0.7
                })
            
            # Check for non-printable characters
            for i, line in enumerate(content.split('\n'), 1):
                for j, char in enumerate(line, 1):
                    if not char.isprintable() and char not in ['\n', '\r', '\t']:
                        issues.append({
                            'type': 'validation_error',
                            'message': f'Non-printable character: {ord(char)}',
                            'line': i,
                            'column': j,
                            'confidence': 0.9
                        })
            
            # Check for maximum line length
            max_length = 100  # Configurable
            for i, line in enumerate(content.split('\n'), 1):
                if len(line) > max_length:
                    issues.append({
                        'type': 'style_issue',
                        'message': f'Line exceeds {max_length} characters',
                        'line': i,
                        'column': max_length + 1,
                        'confidence': 0.7
                    })
            
            # Check for duplicate lines
            lines = content.split('\n')
            for i in range(len(lines) - 1):
                if lines[i] and lines[i] == lines[i + 1]:
                    issues.append({
                        'type': 'style_issue',
                        'message': 'Duplicate consecutive lines',
                        'line': i + 1,
                        'confidence': 0.8
                    })
            
            # Check for file size
            if len(content.encode()) > 1024 * 1024:  # 1MB
                issues.append({
                    'type': 'validation_warning',
                    'message': 'File size exceeds 1MB',
                    'confidence': 0.8
                })
            
            return issues
            
        except Exception as e:
            logger.error(f"Error validating content: {e}")
            return []
    
    def _generate_completions_list(self, content: str, metadata: ContentMetadata) -> List[Dict[str, Any]]:
        """Return completion suggestions without modifying content."""
        suggestions: List[Dict[str, Any]] = []
        try:
            if metadata.language == 'python':
                # Parse AST
                tree = ast.parse(content)
                
                # Suggest f-strings for old-style formatting
                for node in ast.walk(tree):
                    if isinstance(node, ast.BinOp) and isinstance(node.op, ast.Mod):
                        if isinstance(node.left, ast.Str):
                            suggestions.append({
                                'message': 'Consider using f-strings instead of % formatting',
                                'line': node.lineno,
                                'confidence': 0.8
                            })
                
                # Suggest type hints for functions without them
                for node in ast.walk(tree):
                    if isinstance(node, ast.FunctionDef):
                        if not node.returns and not any(arg.annotation for arg in node.args.args):
                            suggestions.append({
                                'message': 'Consider adding type hints to function parameters and return type',
                                'line': node.lineno,
                                'confidence': 0.6
                            })
                
                # Suggest docstrings for functions/classes without them
                for node in ast.walk(tree):
                    if isinstance(node, (ast.FunctionDef, ast.ClassDef)):
                        if not ast.get_docstring(node):
                            suggestions.append({
                                'message': f'Consider adding docstring to {node.__class__.__name__.lower()} "{node.name}"',
                                'line': node.lineno,
                                'confidence': 0.7
                            })
            
            elif metadata.language == 'shell':
                # Safe shell scripting suggestions
                lines = content.split('\n')
                for i, line in enumerate(lines, 1):
                    line = line.strip()
                    # Suggest quoting variables
                    if '$' in line and not re.search(r'\$\{?\w+\}?', line):
                        suggestions.append({
                            'message': 'Consider quoting shell variables to prevent word splitting',
                            'line': i,
                            'confidence': 0.8
                        })
                    
                    # Suggest error handling
                    if line.startswith(('curl', 'wget', 'git')) and '||' not in line and '&&' not in line:
                        suggestions.append({
                            'message': 'Consider adding error handling for this command',
                            'line': i,
                            'confidence': 0.7
                        })
            
            return suggestions
            
        except Exception as e:
            logger.error(f"Error generating completion suggestions: {e}")
            return []
