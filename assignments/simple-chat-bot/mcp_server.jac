import sys;
import os;
import from tools {RagEngine, WebSearch}
import from mcp.server.fastmcp.tools {Tool}
import from mcp.server.fastmcp {FastMCP}
import typing;

glob rag_engine: RagEngine = RagEngine();
glob WebSearch: WebSearch = WebSearch();

with entry {
    mcp = FastMCP(name="RAG-MCP", port=8899);
}

"""
Ensures type annotations are resolved correctly (str, int), even if there are forward references
or extra typing features. This keeps function type hints usable for FastMCP's internal validation
and documentation.
"""
def resolve_hints(fn: typing.Callable) -> typing.Callable {
    fn.__annotations__ = typing.get_type_hints(fn, include_extras=True);
    return fn;
}

@mcp.tool(name="search_docs")
@resolve_hints
async def tool_search_web(query: str) -> str {
    return rag_engine.search(query);
}

@mcp.tool(name="search_web")
@resolve_hints
async def tool_search_web(query: str) -> str {
    web_search_results = web_search.search(query);
    if not web_search_results {
        return "No results found";
    }

    return web_search_results;
}

with entry {
    mcp.run("streamable-http");
}