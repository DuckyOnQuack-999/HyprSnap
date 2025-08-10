#!/usr/bin/env python3

import logging
logger = logging.getLogger(__name__)

import os
import json
import yaml
import markdown
try:
    import pdfkit
    PDFKIT_AVAILABLE = True
except ImportError:
    PDFKIT_AVAILABLE = False
    logger.warning("pdfkit not available. PDF output will be disabled.")
from pathlib import Path
from typing import Dict, List, Union, Optional, Any
from dataclasses import dataclass
import hashlib
import difflib
import re
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

@dataclass
class FormatConfig:
    output_format: str
    include_toc: bool = True
    include_changelog: bool = True
    include_semantic_map: bool = True
    include_dependency_graph: bool = True
    include_summary: bool = True
    highlight_issues: bool = True
    highlight_fixes: bool = True
    highlight_completions: bool = True

class OutputFormatter:
    def __init__(self, config: FormatConfig):
        self.config = config
        self.toc: List[Dict[str, Any]] = []
        self.changelog: List[Dict[str, Any]] = []
        self.semantic_map: Dict[str, Any] = {}
        self.dependency_graph: Dict[str, Any] = {}
        self.summary: Dict[str, Any] = {}
    
    def format_output(self, content: str, metadata: Dict[str, Any], analysis: Dict[str, Any]) -> str:
        """Format content based on configuration."""
        try:
            # (Re)generate dynamic sections for this content
            self.toc = self._generate_toc(content) if self.config.include_toc else []
            self.changelog = self._generate_changelog(content, metadata) if self.config.include_changelog else []
            self.semantic_map = self._generate_semantic_map(content) if self.config.include_semantic_map else {}
            self.dependency_graph = self._generate_dependency_graph(metadata) if self.config.include_dependency_graph else {}
            self.summary = self._generate_summary(content, metadata, analysis) if self.config.include_summary else {}
            
            if self.config.output_format == 'markdown':
                return self._format_markdown(content, metadata, analysis)
            elif self.config.output_format == 'html':
                return self._format_html(content, metadata, analysis)
            elif self.config.output_format == 'json':
                return self._format_json(content, metadata, analysis)
            elif self.config.output_format == 'pdf':
                if not PDFKIT_AVAILABLE:
                    raise ImportError("pdfkit not available. Please install it to enable PDF output.")
                return self._format_pdf(content, metadata, analysis)
            else:
                raise ValueError(f"Unsupported format: {self.config.output_format}")
        except Exception as e:
            logger.error(f"Error formatting content: {e}")
            raise

    # Back-compat alias
    def format(self, content: str, metadata: Dict[str, Any], analysis: Dict[str, Any]) -> str:
        return self.format_output(content, metadata, analysis)
    
    def _generate_toc(self, content: str) -> List[Dict[str, Any]]:
        """Generate table of contents."""
        toc = []
        
        # Extract headers
        header_pattern = r'^(#{1,6})\s+(.+)$'
        for line in content.split('\n'):
            match = re.match(header_pattern, line)
            if match:
                level = len(match.group(1))
                title = match.group(2)
                anchor = re.sub(r'[^\w\s-]', '', title.lower()).replace(' ', '-')
                toc.append({
                    'level': level,
                    'title': title,
                    'anchor': anchor
                })
        
        return toc
    
    def _generate_changelog(self, content: str, metadata: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Generate changelog."""
        changelog = []
        try:
            # Extract version history from content
            version_pattern = r'#\s*Version\s+(\d+\.\d+\.\d+)(?:\s+\(([^)]+)\))?\s*\n((?:[^\n]+\n)+)'
            for match in re.finditer(version_pattern, content, re.MULTILINE):
                version = match.group(1)
                date = match.group(2) or datetime.now().isoformat()
                changes_text = match.group(3)
                
                # Parse changes
                changes = []
                for line in changes_text.split('\n'):
                    line = line.strip()
                    if line.startswith('- '):
                        changes.append(line[2:])
                    elif line.startswith('* '):
                        changes.append(line[2:])
                
                changelog.append({
                    'version': version,
                    'date': date,
                    'changes': changes
                })
            
            # Check git history if available
            try:
                import subprocess
                result = subprocess.run(
                    ['git', 'log', '--pretty=format:%h|%s|%ad', '--date=iso'],
                    capture_output=True,
                    text=True
                )
                if result.returncode == 0:
                    for line in result.stdout.split('\n'):
                        commit_hash, message, date = line.split('|')
                        if re.match(r'v?\d+\.\d+\.\d+', message):
                            version = message.lstrip('v')
                            changelog.append({
                                'version': version,
                                'date': date,
                                'changes': [message],
                                'commit': commit_hash
                            })
            except Exception:
                pass
            
            # Sort by version
            changelog.sort(key=lambda x: [int(n) for n in x['version'].split('.')], reverse=True)
            
            return changelog
            
        except Exception as e:
            logger.error(f"Error generating changelog: {e}")
            return []
    
    def _generate_semantic_map(self, content: str) -> Dict[str, Any]:
        """Generate semantic map of content."""
        semantic_map = {
            'introduction': [],
            'logic': [],
            'algorithm': [],
            'error_handling': [],
            'dependencies': [],
            'documentation': [],
            'tests': []
        }
        
        # Map content sections
        current_section = 'introduction'
        for line in content.split('\n'):
            # Detect section changes
            if line.startswith('# '):
                current_section = 'introduction'
            elif line.startswith('## Logic'):
                current_section = 'logic'
            elif line.startswith('## Algorithm'):
                current_section = 'algorithm'
            elif line.startswith('## Error Handling'):
                current_section = 'error_handling'
            elif line.startswith('## Dependencies'):
                current_section = 'dependencies'
            elif line.startswith('## Documentation'):
                current_section = 'documentation'
            elif line.startswith('## Tests'):
                current_section = 'tests'
            
            semantic_map[current_section].append(line)
        
        return semantic_map
    
    def _generate_dependency_graph(self, metadata: Dict[str, Any]) -> Dict[str, Any]:
        """Generate dependency graph."""
        graph = {
            'nodes': [],
            'edges': []
        }
        
        # Add nodes
        for dep in metadata.get('dependencies', []):
            graph['nodes'].append({
                'id': dep,
                'type': 'dependency'
            })
        
        # Add edges
        for dep in metadata.get('dependencies', []):
            graph['edges'].append({
                'from': metadata.get('name', 'main'),
                'to': dep,
                'type': 'depends_on'
            })
        
        return graph
    
    def _generate_summary(self, content: str, metadata: Dict[str, Any], analysis: Dict[str, Any]) -> Dict[str, Any]:
        """Generate summary report."""
        summary = {
            'metadata': metadata,
            'analysis': analysis,
            'statistics': {
                'total_lines': len(content.split('\n')),
                'total_issues': len(analysis.get('issues', [])),
                'total_suggestions': len(analysis.get('suggestions', [])),
                'total_dependencies': len(metadata.get('dependencies', [])),
                'total_sections': len(self.semantic_map)
            }
        }
        
        return summary
    
    def _format_markdown(self, content: str, metadata: Dict[str, Any], analysis: Dict[str, Any]) -> str:
        """Format output as Markdown."""
        output = []
        
        # Add title
        output.append(f"# {metadata.get('name', 'Document')}\n")
        
        # Add table of contents
        if self.config.include_toc:
            output.append("## Table of Contents\n")
            for item in self.toc:
                output.append(f"{'  ' * (item['level'] - 1)}- [{item['title']}](#{item['anchor']})")
            output.append("")
        
        # Add changelog
        if self.config.include_changelog:
            output.append("## Changelog\n")
            for entry in self.changelog:
                output.append(f"### Version {entry['version']} ({entry['date']})\n")
                for change in entry['changes']:
                    output.append(f"- {change}")
                output.append("")
        
        # Add semantic map
        if self.config.include_semantic_map:
            output.append("## Semantic Map\n")
            for section, lines in self.semantic_map.items():
                output.append(f"### {section.title()}\n")
                output.extend(lines)
                output.append("")
        
        # Add dependency graph
        if self.config.include_dependency_graph:
            output.append("## Dependencies\n")
            output.append("```mermaid")
            output.append("graph TD")
            for edge in self.dependency_graph['edges']:
                output.append(f"    {edge['from']} --> {edge['to']}")
            output.append("```\n")
        
        # Add summary
        if self.config.include_summary:
            output.append("## Summary\n")
            output.append("### Statistics\n")
            for key, value in self.summary['statistics'].items():
                output.append(f"- {key}: {value}")
            output.append("")
        
        # Add content with annotations
        output.append("## Content\n")
        if self.config.highlight_issues:
            output.append("### Issues\n")
            for bucket in ['syntax_issues','logical_issues','security_issues','performance_issues','style_issues','validation_issues']:
                if analysis.get(bucket):
                    output.append(f"#### {bucket.replace('_',' ').title()}")
                    for issue in analysis.get(bucket, []):
                        output.append(f"- L{issue.get('line','?')}: {issue.get('type')}: {issue.get('message')}")
            output.append("")
        
        if self.config.highlight_fixes:
            output.append("### Fixes\n")
            for fix in analysis.get('fixes', []):
                output.append(f"- L{fix.get('line','?')}: {fix.get('message')}")
            output.append("")
        
        if self.config.highlight_completions:
            output.append("### Completions\n")
            for completion in analysis.get('completions', []):
                output.append(f"- L{completion.get('line','?')}: {completion.get('message')}")
            output.append("")
        
        output.append("### Original Content\n")
        output.append("```")
        output.append(content)
        output.append("```")
        
        return "\n".join(output)
    
    def _format_html(self, content: str, metadata: Dict[str, Any], analysis: Dict[str, Any]) -> str:
        """Format output as HTML."""
        # Convert markdown to HTML
        markdown_content = self._format_markdown(content, metadata, analysis)
        html_content = markdown.markdown(markdown_content)
        
        # Add HTML template
        template = f"""<!DOCTYPE html>
<html>
<head>
    <title>{metadata.get('name', 'Document')}</title>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; margin: 40px; }}
        h1, h2, h3 {{ color: #333; }}
        pre {{ background-color: #f5f5f5; padding: 10px; border-radius: 5px; }}
        .issue {{ color: #d32f2f; }}
        .fix {{ color: #388e3c; }}
        .completion {{ color: #1976d2; }}
    </style>
</head>
<body>
{html_content}
</body>
</html>"""
        
        return template
    
    def _format_json(self, content: str, metadata: Dict[str, Any], analysis: Dict[str, Any]) -> str:
        """Format output as JSON."""
        output = {
            'metadata': metadata,
            'analysis': analysis,
            'toc': self.toc,
            'changelog': self.changelog,
            'semantic_map': self.semantic_map,
            'dependency_graph': self.dependency_graph,
            'summary': self.summary,
            'content': content
        }
        
        return json.dumps(output, indent=2)
    
    def _format_pdf(self, content: str, metadata: Dict[str, Any], analysis: Dict[str, Any]) -> str:
        """Format output as PDF."""
        # Convert markdown to HTML
        html_content = self._format_html(content, metadata, analysis)
        
        # Convert HTML to PDF
        pdf_content = pdfkit.from_string(html_content, False)
        
        return pdf_content 